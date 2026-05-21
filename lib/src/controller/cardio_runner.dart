import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cardio/cardio_interval.dart';
import '../models/cardio/cardio_lap.dart';
import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_result.dart';
import '../models/cardio/cardio_runner_state.dart';
import '../storage/prefs_runner_storage.dart';
import '../storage/runner_storage.dart';

/// Fired whenever [CardioRunner.finish] returns a [CardioResult].
typedef CardioFinishedCallback = void Function(CardioResult result);

/// Interval-based companion to `WorkoutRunner`. Designed for workouts where
/// the natural progress unit is a lap — running, intervals on a bike or rower,
/// jump-rope rounds, etc. — rather than a set×reps×weight tuple.
///
/// Lifecycle mirrors `WorkoutRunner`: [start] / [pause] / [resume] / [cancel]
/// / [finish]. State is persisted via [RunnerStorage] under a separate slot
/// (`cardio` by default) so a strength runner and a cardio runner can coexist
/// in the same app without trampling each other.
///
/// The runner keeps two timers:
///
/// * the **global** ticker advances `elapsed` for the whole session
/// * the **interval** ticker advances `currentIntervalElapsed` for the segment
///   the user is currently in. When the interval has a `targetDuration`, the
///   runner auto-completes the lap once that duration is reached.
class CardioRunner extends ChangeNotifier {
  CardioRunner({RunnerStorage? storage, String slot = 'cardio'})
    : _storage = storage ?? PrefsRunnerStorage(),
      _slot = slot;

  final RunnerStorage _storage;
  final String _slot;

  CardioPlan? _plan;
  CardioRunnerState? _state;

  Timer? _globalTicker;
  Duration _elapsed = Duration.zero;

  Timer? _intervalTicker;
  Duration _intervalElapsed = Duration.zero;

  /// How often the ticker rewrites the persisted snapshot. Keeps storage
  /// writes cheap while still bounding the data loss on a hard kill to a few
  /// seconds.
  static const Duration _persistEvery = Duration(seconds: 5);

  /// Max wall-clock delta the auto-resume adds when restoring an interrupted
  /// session. Beyond this we assume the app was suspended for a long time
  /// (user closed it for hours) and refuse to count that toward training.
  static const Duration _resumeMaxGap = Duration(minutes: 2);

  int _ticks = 0;

  /// Bumped on cancel/finish so any in-flight `_persist()` from the periodic
  /// ticker can detect that it is stale and skip the storage write. Without
  /// this, a fire-and-forget persist can resurrect a session that was just
  /// cancelled.
  int _persistGen = 0;

  /// Re-entrancy guard for [completeInterval]. The auto-advance ticker and a
  /// user tap can otherwise race and double-log against the same index.
  bool _completing = false;

  /// Tracks the most recent in-flight `_persist()` so `cancel()`/`finish()`
  /// can await it before clearing storage — otherwise a `saveState` IO that
  /// resolves after `clearState` can resurrect the session.
  Future<void>? _inflightPersist;

  final StreamController<CardioResult> _finishedController =
      StreamController<CardioResult>.broadcast();

  Stream<CardioResult> get finished => _finishedController.stream;
  CardioFinishedCallback? onFinished;

  /// Called after [completeInterval] records a lap.
  ValueChanged<CardioLap>? onIntervalCompleted;

  /// Called after [pause] persists a paused session.
  VoidCallback? onPaused;

  /// Called after [resume] persists a resumed session.
  VoidCallback? onResumed;

  /// Set this to opt out of automatic interval advance — useful for free-form
  /// cardio plans where the user wants to control transitions manually.
  bool autoAdvance = true;

  /// Optional body weight used by live-kcal helpers and by
  /// [CardioResult.kcal] when consumers prefer to read it back via the runner
  /// rather than pass it on every call.
  double? bodyWeightKg;

  // ---------------------------------------------------------------------------
  // Read-only accessors
  // ---------------------------------------------------------------------------

  CardioPlan? get plan => _plan;
  CardioRunnerState? get state => _state;
  bool get isRunning => _state?.isActive == true;
  bool get isPaused => _state != null && !_state!.isActive;
  Duration get elapsed => _elapsed;

  List<CardioInterval> get intervals => _plan?.intervals ?? const [];

  int get currentIntervalIndex => _state?.currentIntervalIndex ?? 0;

  CardioInterval? get currentInterval {
    final plan = _plan;
    if (plan == null) return null;
    final idx = currentIntervalIndex;
    if (idx < 0 || idx >= plan.intervals.length) return null;
    return plan.intervals[idx];
  }

  Duration get currentIntervalElapsed => _intervalElapsed;

  /// `Duration.zero` when the current interval has no target duration.
  Duration get currentIntervalRemaining {
    final target = currentInterval?.targetDuration;
    if (target == null) return Duration.zero;
    final left = target - _intervalElapsed;
    return left.isNegative ? Duration.zero : left;
  }

  List<CardioLap> get laps => _state?.laps ?? const [];

  /// Whether there is another interval after the current one.
  bool get hasNextInterval {
    final plan = _plan;
    if (plan == null) return false;
    return currentIntervalIndex + 1 < plan.intervals.length;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Restore a previously running cardio session from storage.
  ///
  /// Returns `true` when state and plan were both present and matched up. If
  /// the session was active when last persisted, the wall-clock delta since
  /// the last snapshot is added to the elapsed counters (capped at
  /// [_resumeMaxGap] so a long backgrounded app doesn't count toward
  /// training time).
  Future<bool> tryAutoResume() async {
    try {
      final rawState = await _storage.readState(slot: _slot);
      final rawPlan = await _storage.readPlan(slot: _slot);
      if (rawState == null || rawPlan == null) return false;
      final state = CardioRunnerState.fromJson(rawState);
      final plan = CardioPlan.fromJson(rawPlan);
      if (state.planId != plan.id) return false;

      var elapsed = state.elapsed;
      var intervalElapsed = state.intervalElapsed;
      if (state.isActive) {
        final gap = DateTime.now().difference(state.updatedAt);
        final add =
            gap.isNegative
                ? Duration.zero
                : (gap > _resumeMaxGap ? _resumeMaxGap : gap);
        elapsed += add;
        intervalElapsed += add;
      }

      _plan = plan;
      _state = state.copyWith(
        elapsed: elapsed,
        intervalElapsed: intervalElapsed,
      );
      _elapsed = elapsed;
      _intervalElapsed = intervalElapsed;

      if (state.isActive) {
        _startGlobalTicker();
        _startIntervalTicker();
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start a fresh cardio session for [plan]. If a matching active state is
  /// already in memory and [resumeIfPossible] is true, the runner picks up
  /// where it left off instead of resetting.
  Future<void> start(CardioPlan plan, {bool resumeIfPossible = true}) async {
    // Mirror WorkoutRunner.start's gating: only treat the previous session as
    // resumable when it was actually active (a finished or cancelled session
    // should start fresh even when the planId matches).
    final canResume =
        resumeIfPossible &&
        _state != null &&
        _state!.planId == plan.id &&
        _state!.isActive;

    _plan = plan;
    if (!canResume) {
      final now = DateTime.now();
      _state = CardioRunnerState(
        planId: plan.id,
        currentIntervalIndex: 0,
        isActive: true,
        startedAt: now,
        updatedAt: now,
        elapsed: Duration.zero,
        intervalElapsed: Duration.zero,
        laps: const [],
      );
      _elapsed = Duration.zero;
      _intervalElapsed = Duration.zero;
    } else {
      _state = _state!.copyWith(isActive: true, updatedAt: DateTime.now());
    }

    _startGlobalTicker();
    _startIntervalTicker();
    await _persist();
    notifyListeners();
  }

  /// Pause both tickers without producing a result.
  ///
  /// Returns `true` when an active session was paused, `false` when there
  /// was nothing to pause (no session, or the session was already paused).
  Future<bool> pause() async {
    final state = _state;
    if (state == null || !state.isActive) return false;
    _stopGlobalTicker();
    _stopIntervalTicker();
    _state = state.copyWith(
      isActive: false,
      elapsed: _elapsed,
      intervalElapsed: _intervalElapsed,
      updatedAt: DateTime.now(),
    );
    await _persist();
    onPaused?.call();
    notifyListeners();
    return true;
  }

  /// Resume the session after a [pause].
  ///
  /// Returns `true` when a paused session was resumed, `false` when there
  /// was nothing to resume (no session, or the session was already running).
  Future<bool> resume() async {
    final state = _state;
    if (state == null || state.isActive) return false;
    _state = state.copyWith(isActive: true, updatedAt: DateTime.now());
    _startGlobalTicker();
    _startIntervalTicker();
    await _persist();
    onResumed?.call();
    notifyListeners();
    return true;
  }

  /// Drop the session without producing a result. Storage is cleared.
  Future<void> cancel() async {
    _stopAllTickers();
    _persistGen++;
    _plan = null;
    _state = null;
    _elapsed = Duration.zero;
    _intervalElapsed = Duration.zero;
    // Let any in-flight tick-driven persist finish (it will short-circuit on
    // the bumped gen) so a delayed `saveState` cannot land after our clear.
    await _inflightPersist;
    await _storage.clearState(slot: _slot);
    await _storage.clearPlan(slot: _slot);
    notifyListeners();
  }

  /// Wrap up the session and emit a [CardioResult]. Returns `null` when no
  /// session is active.
  Future<CardioResult?> finish() async {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return null;

    _stopAllTickers();
    _persistGen++;
    await _inflightPersist;

    final result = CardioResult(
      planId: plan.id,
      planName: plan.name,
      discipline: plan.discipline,
      startedAt: state.startedAt,
      finishedAt: DateTime.now(),
      duration: _elapsed,
      laps: List<CardioLap>.unmodifiable(state.laps),
      meta: plan.meta,
    );

    _plan = null;
    _state = null;
    _elapsed = Duration.zero;
    _intervalElapsed = Duration.zero;

    await _storage.clearState(slot: _slot);
    await _storage.clearPlan(slot: _slot);

    onFinished?.call(result);
    if (!_finishedController.isClosed) _finishedController.add(result);

    notifyListeners();
    return result;
  }

  // ---------------------------------------------------------------------------
  // Interval / lap control
  // ---------------------------------------------------------------------------

  /// Record the current interval as a completed [CardioLap]. Advances to the
  /// next interval (or finishes the session when there is no next one).
  ///
  /// Pass `distanceMeters` for cardio kinds where distance matters; pass
  /// `rpe`/`avgHeartRate` to enrich the lap. Returns the persisted lap, or
  /// `null` when there is no active session.
  Future<CardioLap?> completeInterval({
    double? distanceMeters,
    int? avgHeartRate,
    int? rpe,
    Duration? duration,
  }) async {
    if (_completing) return null;
    _completing = true;
    try {
      final state = _state;
      final interval = currentInterval;
      if (state == null || interval == null) return null;

      final taken = duration ?? _intervalElapsed;
      final lap = CardioLap.computed(
        intervalIndex: state.currentIntervalIndex,
        duration: taken,
        distanceMeters: distanceMeters ?? interval.targetDistanceMeters,
        avgHeartRate: avgHeartRate,
        rpe: rpe,
        met: interval.met,
      );

      final laps = [...state.laps, lap];
      final nextIndex = state.currentIntervalIndex + 1;

      _intervalElapsed = Duration.zero;
      _state = state.copyWith(
        currentIntervalIndex: nextIndex,
        laps: laps,
        elapsed: _elapsed,
        intervalElapsed: Duration.zero,
        updatedAt: DateTime.now(),
      );

      await _persist();
      onIntervalCompleted?.call(lap);
      notifyListeners();

      if (nextIndex >= (_plan?.intervals.length ?? 0)) {
        // Stop tickers — the session is logically done, but we leave finish()
        // to the consumer so they can show a summary screen first.
        _stopIntervalTicker();
      }

      return lap;
    } finally {
      _completing = false;
    }
  }

  /// Skip the current interval without logging a lap. Useful for warmups the
  /// user wants to cut short.
  ///
  /// Returns `true` when the index moved forward, `false` when there is no
  /// active session or the session is already past the last interval.
  Future<bool> skipInterval() async {
    final state = _state;
    final plan = _plan;
    if (state == null || plan == null) return false;
    if (state.currentIntervalIndex >= plan.intervals.length) return false;
    _intervalElapsed = Duration.zero;
    _state = state.copyWith(
      currentIntervalIndex: state.currentIntervalIndex + 1,
      intervalElapsed: Duration.zero,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
    return true;
  }

  /// Jump to a specific interval. Mainly useful for testing or for a
  /// "previous interval" UI button.
  ///
  /// Returns `true` when the jump happened, `false` when there is no active
  /// session or [index] is out of range.
  Future<bool> jumpToInterval(int index) async {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return false;
    if (index < 0 || index >= plan.intervals.length) return false;
    _intervalElapsed = Duration.zero;
    _state = state.copyWith(
      currentIntervalIndex: index,
      intervalElapsed: Duration.zero,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _startGlobalTicker() {
    _globalTicker?.cancel();
    _ticks = 0;
    _globalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _state;
      if (state == null || !state.isActive) return;
      _elapsed += const Duration(seconds: 1);
      _ticks++;
      if (_ticks % _persistEvery.inSeconds == 0) {
        _state = state.copyWith(
          elapsed: _elapsed,
          intervalElapsed: _intervalElapsed,
          updatedAt: DateTime.now(),
        );
        // ignore: discarded_futures
        _persist();
      }
      notifyListeners();
    });
  }

  void _startIntervalTicker() {
    _intervalTicker?.cancel();
    _intervalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _state;
      final interval = currentInterval;
      if (state == null || !state.isActive || interval == null) return;
      _intervalElapsed += const Duration(seconds: 1);

      final target = interval.targetDuration;
      if (autoAdvance && target != null && _intervalElapsed >= target) {
        // ignore: discarded_futures — fire-and-forget; we already notified
        completeInterval(duration: target);
        return;
      }
      notifyListeners();
    });
  }

  void _stopGlobalTicker() {
    _globalTicker?.cancel();
    _globalTicker = null;
  }

  void _stopIntervalTicker() {
    _intervalTicker?.cancel();
    _intervalTicker = null;
  }

  void _stopAllTickers() {
    _stopGlobalTicker();
    _stopIntervalTicker();
  }

  Future<void> _persist() {
    final gen = _persistGen;
    final state = _state;
    final plan = _plan;
    if (state == null || plan == null) return Future.value();
    final stateJson = state.toJson();
    final planJson = plan.toJson();
    final fut = () async {
      // Re-check the generation between writes: `cancel()`/`finish()` bump
      // `_persistGen` and then await `_inflightPersist`, so a stale write
      // started before the bump still skips the second IO and the caller
      // can rely on storage being clean once `cancel()` returns.
      if (gen != _persistGen) return;
      await _storage.saveState(stateJson, slot: _slot);
      if (gen != _persistGen) return;
      await _storage.savePlan(planJson, slot: _slot);
    }();
    _inflightPersist = fut;
    return fut;
  }

  @override
  void dispose() {
    _stopAllTickers();
    _finishedController.close();
    super.dispose();
  }
}
