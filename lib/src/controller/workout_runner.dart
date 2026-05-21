import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/performed_exercise.dart';
import '../models/performed_set.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_plan_validation.dart';
import '../models/workout_result.dart';
import '../models/workout_runner_state.dart';
import '../models/workout_set.dart';
import '../storage/prefs_runner_storage.dart';
import '../storage/runner_storage.dart';

/// Result emitted whenever [WorkoutRunner.finish] completes successfully.
typedef WorkoutFinishedCallback = void Function(WorkoutResult result);

/// Heart of the package. Owns the active [WorkoutPlan], the running state
/// (timers, set/exercise indices, performed sets) and persistence.
///
/// `WorkoutRunner` is a [ChangeNotifier] — widgets rebuild on every state
/// change. Listen to [finished] for a one-shot result event.
class WorkoutRunner extends ChangeNotifier {
  WorkoutRunner({RunnerStorage? storage, String slot = 'default'})
    : _storage = storage ?? PrefsRunnerStorage(),
      _slot = slot;

  final RunnerStorage _storage;
  final String _slot;

  WorkoutPlan? _plan;
  WorkoutRunnerState? _state;

  Timer? _globalTimer;
  Duration _elapsed = Duration.zero;

  /// Set when [pause] is called, cleared by [resume]. Used to compute the
  /// delta to fold into `state.pausedFor` once the user resumes.
  DateTime? _pauseStartedAt;

  Timer? _setTicker;
  DateTime? _setStartedAt;
  Duration _setElapsed = Duration.zero;
  int? _activeSetExerciseIndex;
  int? _activeSetIndex;

  Timer? _restTicker;
  Duration _restRemaining = Duration.zero;
  Duration _restTotal = Duration.zero;

  /// Default rest applied when [finishCurrentSet] is called without
  /// `restSeconds`, and when [addSetToExercise] is called without `rest`.
  Duration defaultRest = const Duration(seconds: 90);

  /// Optional body weight used by live-kcal helpers and by
  /// [WorkoutResult.kcal] when consumers prefer to read it back via the
  /// runner rather than pass it on every call. Pure data — does not affect
  /// runner behaviour.
  double? bodyWeightKg;

  final StreamController<WorkoutResult> _finishedController =
      StreamController<WorkoutResult>.broadcast();

  /// Stream of [WorkoutResult]s, one per completed workout. Convenient when
  /// you want to send results to a remote sink (Supabase, Firestore, …) from
  /// anywhere in the tree.
  Stream<WorkoutResult> get finished => _finishedController.stream;

  /// Optional fire-and-forget callback. Alternative to [finished].
  WorkoutFinishedCallback? onFinished;

  /// Called after a set has been recorded via [finishCurrentSet] or [logSet].
  ValueChanged<PerformedSet>? onSetCompleted;

  /// Called when [showExercise] changes the currently displayed exercise.
  ValueChanged<int>? onExerciseChanged;

  /// Called whenever a rest countdown starts after a set.
  ValueChanged<Duration>? onRestStarted;

  /// Called every second the rest ticker fires, with the seconds remaining.
  /// Wire this to a sound/haptic helper for "3-2-1 go" cues.
  ValueChanged<Duration>? onRestTick;

  /// Called once when the rest countdown reaches zero on its own. Does NOT
  /// fire when the user calls [skipRest] — use [onRestSkipped] for that.
  VoidCallback? onRestCompleted;

  /// Called when [skipRest] cuts an active rest short.
  VoidCallback? onRestSkipped;

  /// Called after [pause] persists a paused session.
  VoidCallback? onPaused;

  /// Called after [resume] persists a resumed session, with the duration spent
  /// paused since the last `pause()` call.
  ValueChanged<Duration>? onResumed;

  /// Fires once when the active set is timed/AMRAP and the elapsed time
  /// reaches the set's `targetDuration`. The set is NOT auto-finished —
  /// consumers are expected to log reps (AMRAP) or confirm (timed) themselves.
  ValueChanged<int>? onTimedSetTargetReached;

  bool _timedTargetFired = false;

  // ---------------------------------------------------------------------------
  // Read-only accessors
  // ---------------------------------------------------------------------------

  WorkoutPlan? get plan => _plan;
  WorkoutRunnerState? get state => _state;
  bool get isRunning => _state?.isActive == true;
  bool get isPaused => _state != null && !_state!.isActive;
  Duration get elapsed => _elapsed;

  List<WorkoutExercise> get exercises => _plan?.exercises ?? const [];

  /// Index of the exercise the UI is currently *showing* (may differ from
  /// the active one, when the user is paging through the plan).
  int get currentExerciseIndex => _state?.currentExerciseIndex ?? 0;

  /// Index of the exercise the user has explicitly *started*. `null` until
  /// [setActiveExercise] is called.
  int? get activeExerciseIndex => _state?.activeExerciseIndex;
  bool get hasActiveExercise => activeExerciseIndex != null;

  WorkoutExercise? get currentExercise {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return null;
    if (state.currentExerciseIndex >= plan.exercises.length) return null;
    return plan.exercises[state.currentExerciseIndex];
  }

  WorkoutExercise? get activeExercise {
    final plan = _plan;
    final idx = activeExerciseIndex;
    if (plan == null || idx == null) return null;
    if (idx < 0 || idx >= plan.exercises.length) return null;
    return plan.exercises[idx];
  }

  bool isExerciseShown(int index) => index == currentExerciseIndex;
  bool isExerciseActive(int index) => index == activeExerciseIndex;

  bool canStart(WorkoutPlan plan) => plan.validate().isValid;

  // Set tracking
  int? get activeSetExerciseIndex => _activeSetExerciseIndex;
  int? get activeSetIndex => _activeSetIndex;
  bool get isSetRunning => _setTicker != null;
  Duration get currentSetElapsed => _setElapsed;

  /// The [WorkoutSet] the runner is currently executing, or `null` if no set
  /// is active. Useful for UIs that need to read the target reps / weight /
  /// duration of the running set directly.
  WorkoutSet? get currentActiveSet {
    final plan = _plan;
    final exIdx = _activeSetExerciseIndex;
    final setIdx = _activeSetIndex;
    if (plan == null || exIdx == null || setIdx == null) return null;
    if (exIdx < 0 || exIdx >= plan.exercises.length) return null;
    final sets = plan.exercises[exIdx].sets;
    if (setIdx < 0 || setIdx >= sets.length) return null;
    return sets[setIdx];
  }

  /// `targetDuration` of the active set when it is timed/AMRAP, else `null`.
  Duration? get currentSetTargetDuration => currentActiveSet?.targetDuration;

  /// `true` when the active set is AMRAP/timed (i.e. needs a countdown UI).
  bool get isCurrentSetTimed => currentActiveSet?.isTimed ?? false;

  /// Time left on the active timed set's countdown. `Duration.zero` when no
  /// timed set is running, when the target has been reached, or when the set
  /// has no `targetDuration`.
  Duration get currentSetRemaining {
    final target = currentSetTargetDuration;
    if (target == null) return Duration.zero;
    final left = target - _setElapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get isResting => _restTicker != null;
  Duration get restRemaining => _restRemaining;

  /// Total duration of the current rest period — useful for progress rings.
  /// `Duration.zero` while not resting.
  Duration get restTotal => _restTotal;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Attempts to restore a previously running workout. Returns `true` if a
  /// resume happened.
  Future<bool> tryAutoResume() async {
    try {
      final rawState = await _storage.readState(slot: _slot);
      final rawPlan = await _storage.readPlan(slot: _slot);
      if (rawState == null || rawPlan == null) return false;

      final state = WorkoutRunnerState.fromJson(rawState);
      _plan = WorkoutPlan.fromJson(rawPlan);
      _state = state;
      _elapsed = _computeElapsed(state);
      // Only restart the global ticker if the session was actively running.
      // Paused sessions stay paused until the consumer calls [resume].
      if (state.isActive) _startGlobalTimer();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start a new workout. If [resumeIfPossible] is true and an active state
  /// for the same plan id exists, that state is reused.
  Future<void> start(WorkoutPlan plan, {bool resumeIfPossible = true}) async {
    final canResume =
        resumeIfPossible &&
        _state != null &&
        _state!.planId == plan.id &&
        _state!.isActive;

    _plan = plan;
    if (!canResume) {
      final now = DateTime.now();
      _state = WorkoutRunnerState(
        planId: plan.id,
        currentExerciseIndex: 0,
        activeExerciseIndex: null,
        currentSetIndex: 0,
        isActive: true,
        startedAt: now,
        updatedAt: now,
        performed: const [],
      );
      _elapsed = Duration.zero;
    } else {
      _elapsed = _computeElapsed(_state!);
    }

    _resetSetState();
    _resetRest();
    _startGlobalTimer();
    await _persist();
    notifyListeners();
  }

  /// Pause the global timer (and any running set ticker / rest countdown)
  /// without ending the session. While paused, `isRunning` is false and
  /// [isPaused] is true. Total time spent paused is folded into the persisted
  /// `pausedFor` so [elapsed] does not inflate.
  ///
  /// Returns `true` when an active session was paused, `false` when there was
  /// nothing to pause (no session, or the session was already paused).
  Future<bool> pause() async {
    final state = _state;
    if (state == null || !state.isActive) return false;
    _pauseStartedAt = DateTime.now();
    _stopAllTimers();
    _state = state.copyWith(isActive: false, updatedAt: DateTime.now());
    await _persist();
    onPaused?.call();
    notifyListeners();
    return true;
  }

  /// Resume a previously [pause]d session. Restarts the global timer and adds
  /// the time spent paused to `state.pausedFor` so [elapsed] is accurate.
  ///
  /// Returns `true` when a paused session was resumed, `false` when there was
  /// nothing to resume (no session, or the session was already running).
  Future<bool> resume() async {
    final state = _state;
    if (state == null || state.isActive) return false;
    final pausedSince = _pauseStartedAt;
    final delta =
        pausedSince == null
            ? Duration.zero
            : DateTime.now().difference(pausedSince);
    _pauseStartedAt = null;
    _state = state.copyWith(
      isActive: true,
      pausedFor: state.pausedFor + delta,
      updatedAt: DateTime.now(),
    );
    _startGlobalTimer();
    await _persist();
    onResumed?.call(delta);
    notifyListeners();
    return true;
  }

  /// Stop everything and discard the in-memory state without producing a
  /// [WorkoutResult]. Storage is cleared.
  Future<void> cancel() async {
    _stopAllTimers();
    _plan = null;
    _state = null;
    _elapsed = Duration.zero;
    await _storage.clearState(slot: _slot);
    await _storage.clearPlan(slot: _slot);
    notifyListeners();
  }

  /// Finish the workout and return a result. Emits on [finished] and calls
  /// [onFinished]. Returns `null` if no workout is active.
  Future<WorkoutResult?> finish() async {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return null;

    final details =
        state.performed.map((perf) {
          final original =
              perf.exerciseIndex < plan.exercises.length
                  ? plan.exercises[perf.exerciseIndex]
                  : null;
          return PerformedExerciseDetails(
            exerciseId: original?.id ?? '',
            exerciseName: perf.exerciseName,
            sets: perf.sets,
            met: original?.met,
            categoryId: original?.category?.id,
            substitutedFrom: perf.substitutedFrom,
          );
        }).toList();

    final result = WorkoutResult(
      planId: state.planId,
      startedAt: state.startedAt,
      finishedAt: DateTime.now(),
      duration: _elapsed,
      exercises: details,
    );

    _stopAllTimers();
    _plan = null;
    _state = null;
    _elapsed = Duration.zero;

    await _storage.clearState(slot: _slot);
    await _storage.clearPlan(slot: _slot);

    onFinished?.call(result);
    if (!_finishedController.isClosed) _finishedController.add(result);

    notifyListeners();
    return result;
  }

  // ---------------------------------------------------------------------------
  // Exercise navigation
  // ---------------------------------------------------------------------------

  /// Change which exercise the UI is paged to (does not "activate" it).
  ///
  /// Returns `true` when the visible index actually changed. Returns `false`
  /// when there is no active session, the index is out of range, or the
  /// requested exercise is already the visible one.
  bool showExercise(int index) {
    final state = _state;
    final plan = _plan;
    if (plan == null || state == null) return false;
    if (index < 0 || index >= plan.exercises.length) return false;
    if (state.currentExerciseIndex == index) return false;
    _state = state.copyWith(
      currentExerciseIndex: index,
      currentSetIndex: 0,
      updatedAt: DateTime.now(),
    );
    onExerciseChanged?.call(index);
    _persist();
    notifyListeners();
    return true;
  }

  /// Mark an exercise as the active one (the one whose sets can be started).
  ///
  /// Returns `true` when the exercise was activated. Returns `false` when
  /// there is no active session, another exercise is already active (call
  /// [clearActiveExercise] first), or [index] is out of range.
  bool setActiveExercise(int index) {
    final state = _state;
    final plan = _plan;
    if (plan == null || state == null) return false;
    if (state.activeExerciseIndex != null) return false;
    if (index < 0 || index >= plan.exercises.length) return false;
    _state = state.copyWith(
      activeExerciseIndex: index,
      currentSetIndex: 0,
      updatedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    return true;
  }

  /// Clears the active exercise. If a set was running for it, the set is
  /// also discarded.
  ///
  /// Returns `true` when there was an active exercise that got cleared,
  /// `false` when there was nothing to clear.
  bool clearActiveExercise() {
    final state = _state;
    if (state == null || state.activeExerciseIndex == null) return false;
    _resetSetState();
    _resetRest();
    _state = state.copyWith(
      activeExerciseIndex: null,
      updatedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Sets
  // ---------------------------------------------------------------------------

  /// Whether [startSet] is currently allowed for [exerciseIndex].
  bool canActivateSet(int exerciseIndex) =>
      _state?.activeExerciseIndex == exerciseIndex;

  /// Start the set ticker for [(exerciseIndex, setIndex)]. Returns `false` if
  /// preconditions are not met (no plan, no active exercise, another set
  /// already running, set already performed, indices out of range).
  bool startSet(int exerciseIndex, int setIndex) {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return false;
    if (!canActivateSet(exerciseIndex)) return false;
    if (_activeSetExerciseIndex != null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final sets = plan.exercises[exerciseIndex].sets;
    if (setIndex < 0 || setIndex >= sets.length) return false;
    if (getPerformedSet(exerciseIndex, setIndex) != null) return false;

    _resetRest();
    _activeSetExerciseIndex = exerciseIndex;
    _activeSetIndex = setIndex;
    _setStartedAt = DateTime.now();
    _setElapsed = Duration.zero;
    _timedTargetFired = false;
    _setTicker?.cancel();
    _setTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _setStartedAt;
      if (startedAt == null) return;
      _setElapsed = DateTime.now().difference(startedAt);
      final target = currentSetTargetDuration;
      if (!_timedTargetFired && target != null && _setElapsed >= target) {
        _timedTargetFired = true;
        onTimedSetTargetReached?.call(setIndex);
      }
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  /// Finish the currently running set with the given actuals.
  Future<bool> finishCurrentSet({
    required int reps,
    double? weight,
    int? rir,
    Duration? setDuration,
    Duration? rest,
  }) async {
    final exIdx = _activeSetExerciseIndex;
    final setIdx = _activeSetIndex;
    if (exIdx == null || setIdx == null) return false;
    final plan = _plan;
    if (plan == null ||
        exIdx < 0 ||
        exIdx >= plan.exercises.length ||
        setIdx < 0 ||
        setIdx >= plan.exercises[exIdx].sets.length) {
      return false;
    }

    final taken = setDuration ?? _setElapsed;
    _setTicker?.cancel();
    _setTicker = null;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
    _timedTargetFired = false;

    final restDuration = rest ?? defaultRest;
    final recorded = await _recordPerformedSet(
      exerciseIndex: exIdx,
      setIndex: setIdx,
      reps: reps,
      weight: weight,
      rir: rir,
      duration: taken,
      pause: restDuration,
    );
    if (!recorded) return false;

    _activeSetExerciseIndex = null;
    _activeSetIndex = null;
    if (restDuration.inSeconds > 0) {
      _beginRest(restDuration);
    }
    notifyListeners();
    return true;
  }

  /// Record a completed set without going through a running ticker (useful
  /// when the user logs sets after the fact).
  Future<bool> logSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    double? weight,
    int? rir,
    Duration? duration,
    Duration? pause,
  }) => _recordPerformedSet(
    exerciseIndex: exerciseIndex,
    setIndex: setIndex,
    reps: reps,
    weight: weight,
    rir: rir,
    duration: duration,
    pause: pause,
  );

  /// Update an already-logged set in-place.
  Future<void> updatePerformedSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    double? weight,
    int? rir,
  }) async {
    final state = _state;
    if (state == null) return;
    final performed =
        state.performed.map((ex) {
          if (ex.exerciseIndex != exerciseIndex) return ex;
          final sets =
              ex.sets.map((s) {
                if (s.setIndex != setIndex) return s;
                return s.copyWith(
                  actualReps: reps,
                  actualWeight: weight,
                  rir: rir,
                );
              }).toList();
          return ex.copyWith(sets: sets);
        }).toList();
    _state = state.copyWith(performed: performed, updatedAt: DateTime.now());
    await _persist();
    notifyListeners();
  }

  PerformedSet? getPerformedSet(int exerciseIndex, int setIndex) {
    final state = _state;
    if (state == null) return null;
    for (final ex in state.performed) {
      if (ex.exerciseIndex != exerciseIndex) continue;
      for (final set in ex.sets) {
        if (set.setIndex == setIndex) return set;
      }
    }
    return null;
  }

  /// Cut the current rest countdown short. Returns `true` when a rest was
  /// actually skipped, `false` when no rest was running.
  bool skipRest() {
    final wasResting = _restTicker != null;
    _resetRest(notify: true);
    if (wasResting) onRestSkipped?.call();
    return wasResting;
  }

  /// Add [extra] to the running rest countdown. No-op when no rest is active
  /// or [extra] is non-positive. Updates [restTotal] so progress UIs stay
  /// consistent.
  void extendRest(Duration extra) {
    if (_restTicker == null || extra <= Duration.zero) return;
    _restRemaining += extra;
    _restTotal += extra;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Plan mutation
  // ---------------------------------------------------------------------------

  /// Append a target set to one of the plan's exercises.
  Future<bool> addSetToExercise(
    int exerciseIndex, {
    int targetReps = 10,
    double? targetWeight,
    Duration? rest,
  }) async {
    final plan = _plan;
    if (plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final ex = plan.exercises[exerciseIndex];
    final newSet = WorkoutSet(
      targetReps: targetReps,
      targetWeight: targetWeight,
      rest: rest ?? defaultRest,
    );
    final updated = ex.copyWith(sets: [...ex.sets, newSet]);
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == exerciseIndex ? updated : plan.exercises[i],
      ],
    );
    await _persistPlan();
    notifyListeners();
    return true;
  }

  /// Remove a target set from one of the plan's exercises. Refuses to remove
  /// sets that already have a performed entry.
  Future<bool> removeSetFromExercise(int exerciseIndex, int setIndex) async {
    final plan = _plan;
    if (plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final ex = plan.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= ex.sets.length) return false;
    if (getPerformedSet(exerciseIndex, setIndex) != null) return false;
    final newSets = [
      for (var i = 0; i < ex.sets.length; i++)
        if (i != setIndex) ex.sets[i],
    ];
    final updated = ex.copyWith(sets: newSets);
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == exerciseIndex ? updated : plan.exercises[i],
      ],
    );
    await _persistPlan();
    notifyListeners();
    return true;
  }

  /// Append a new exercise to the running plan. Returns false when no plan
  /// is active or [exercise.id] collides with an existing one.
  Future<bool> addExercise(WorkoutExercise exercise) async {
    final plan = _plan;
    if (plan == null) return false;
    if (plan.exercises.any((e) => e.id == exercise.id)) return false;
    _plan = plan.copyWith(exercises: [...plan.exercises, exercise]);
    await _persistPlan();
    notifyListeners();
    return true;
  }

  /// Remove an exercise by index. Refuses if any of its sets have been
  /// performed already — drop those sets via [removeSetFromExercise] first
  /// or finish the workout to clear performed state.
  Future<bool> removeExercise(int exerciseIndex) async {
    final plan = _plan;
    final state = _state;
    if (plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    if (state != null &&
        state.performed.any((p) => p.exerciseIndex == exerciseIndex)) {
      return false;
    }
    final newExercises = [
      for (var i = 0; i < plan.exercises.length; i++)
        if (i != exerciseIndex) plan.exercises[i],
    ];
    _plan = plan.copyWith(exercises: newExercises);
    // Active set / exercise pointers may dangle — clear them defensively.
    if (state != null) {
      _state = state.copyWith(
        currentExerciseIndex: state.currentExerciseIndex >= newExercises.length
            ? (newExercises.isEmpty ? 0 : newExercises.length - 1)
            : state.currentExerciseIndex,
        activeExerciseIndex: state.activeExerciseIndex == exerciseIndex
            ? null
            : state.activeExerciseIndex,
        updatedAt: DateTime.now(),
      );
      if (_activeSetExerciseIndex == exerciseIndex) {
        _resetSetState();
      }
      await _persist();
    } else {
      await _persistPlan();
    }
    notifyListeners();
    return true;
  }

  /// Move an exercise from [oldIndex] to [newIndex]. Refuses if either index
  /// is out of range, but does NOT inspect performed sets — those carry an
  /// `exerciseIndex` that is meaningful only for the active session, and the
  /// runner re-binds them to the moved positions automatically.
  Future<bool> moveExercise(int oldIndex, int newIndex) async {
    final plan = _plan;
    final state = _state;
    if (plan == null) return false;
    final n = plan.exercises.length;
    if (oldIndex < 0 || oldIndex >= n || newIndex < 0 || newIndex >= n) {
      return false;
    }
    if (oldIndex == newIndex) return true;
    final list = [...plan.exercises];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    _plan = plan.copyWith(exercises: list);
    if (state != null) {
      // Remap performed-exercise indices via the same permutation.
      final perm = <int, int>{};
      for (var i = 0; i < n; i++) {
        if (i == oldIndex) {
          perm[i] = newIndex;
        } else {
          var target = i;
          if (oldIndex < newIndex && i > oldIndex && i <= newIndex) target -= 1;
          if (oldIndex > newIndex && i >= newIndex && i < oldIndex) target += 1;
          perm[i] = target;
        }
      }
      final remapped = state.performed
          .map((p) => p.copyWith(
                exerciseIndex: perm[p.exerciseIndex] ?? p.exerciseIndex,
                sets: p.sets
                    .map((s) => s.copyWith(
                          exerciseIndex:
                              perm[s.exerciseIndex] ?? s.exerciseIndex,
                        ))
                    .toList(growable: false),
              ))
          .toList(growable: false);
      _state = state.copyWith(
        performed: remapped,
        currentExerciseIndex:
            perm[state.currentExerciseIndex] ?? state.currentExerciseIndex,
        activeExerciseIndex: state.activeExerciseIndex == null
            ? null
            : perm[state.activeExerciseIndex],
        updatedAt: DateTime.now(),
      );
      await _persist();
    } else {
      await _persistPlan();
    }
    notifyListeners();
    return true;
  }

  /// Replace a target set in-place. Refuses to overwrite a set that already
  /// has a performed entry — change the result via [updatePerformedSet]
  /// instead if you want to edit a logged set.
  Future<bool> replaceSet(
    int exerciseIndex,
    int setIndex,
    WorkoutSet replacement,
  ) async {
    final plan = _plan;
    if (plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final ex = plan.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= ex.sets.length) return false;
    if (getPerformedSet(exerciseIndex, setIndex) != null) return false;
    final newSets = [
      for (var i = 0; i < ex.sets.length; i++)
        if (i == setIndex) replacement else ex.sets[i],
    ];
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == exerciseIndex ? ex.copyWith(sets: newSets) : plan.exercises[i],
      ],
    );
    await _persistPlan();
    notifyListeners();
    return true;
  }

  /// Insert a copy of an existing target set right after it. Returns the new
  /// set's index, or `null` if the source is out of range / no plan is active.
  Future<int?> duplicateSet(int exerciseIndex, int setIndex) async {
    final plan = _plan;
    if (plan == null) return null;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return null;
    }
    final ex = plan.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= ex.sets.length) return null;
    final cloned = ex.sets[setIndex];
    final newSets = [...ex.sets];
    newSets.insert(setIndex + 1, cloned);
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == exerciseIndex ? ex.copyWith(sets: newSets) : plan.exercises[i],
      ],
    );
    await _persistPlan();
    notifyListeners();
    return setIndex + 1;
  }

  /// Replace the running plan in-place. When [preservePerformed] is `true`
  /// (default) the performed-sets log is kept — useful when the new plan
  /// keeps the same exercise indices (e.g. mid-session edit from a Plan
  /// Editor). When `false`, performed sets are wiped so the runner starts
  /// the new plan fresh. Refuses when no plan is currently active.
  Future<bool> replacePlan(WorkoutPlan plan, {bool preservePerformed = true}) async {
    final state = _state;
    if (state == null) return false;
    _plan = plan;
    if (!preservePerformed) {
      _resetSetState();
      _resetRest();
      _state = state.copyWith(
        performed: const [],
        currentExerciseIndex: 0,
        activeExerciseIndex: null,
        currentSetIndex: 0,
        updatedAt: DateTime.now(),
      );
    } else {
      // Cap currentExerciseIndex / activeExerciseIndex to the new plan size.
      final n = plan.exercises.length;
      _state = state.copyWith(
        currentExerciseIndex:
            state.currentExerciseIndex >= n ? (n == 0 ? 0 : n - 1) : null,
        activeExerciseIndex:
            (state.activeExerciseIndex != null &&
                    state.activeExerciseIndex! >= n)
                ? null
                : state.activeExerciseIndex,
        updatedAt: DateTime.now(),
      );
    }
    await _persist();
    notifyListeners();
    return true;
  }

  /// Swap the exercise at [index] with [replacement]. Refuses when any set
  /// of the original has already been performed — finish or drop those sets
  /// first via [updatePerformedSet] / [removeSetFromExercise]. On success,
  /// future performed sets at this index carry `substitutedFrom = <original>`
  /// in the [WorkoutResult] so consumers can tell apart "planned this from
  /// the start" vs "swapped mid-session".
  Future<bool> substituteExercise(
    int index,
    WorkoutExercise replacement,
  ) async {
    final plan = _plan;
    final state = _state;
    if (plan == null || state == null) return false;
    if (index < 0 || index >= plan.exercises.length) return false;
    final original = plan.exercises[index];
    if (original.id == replacement.id) return true;
    if (state.performed.any(
      (p) => p.exerciseIndex == index && p.sets.isNotEmpty,
    )) {
      return false;
    }
    // Stash an empty PerformedExercise that future logged sets will inherit
    // `substitutedFrom` from via the merge path in `_recordPerformedSet`.
    final stub = PerformedExercise(
      exerciseIndex: index,
      exerciseName: replacement.name,
      sets: const [],
      substitutedFrom: original.id,
    );
    final newPerformed = [
      for (final p in state.performed)
        if (p.exerciseIndex != index) p,
      stub,
    ];
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == index ? replacement : plan.exercises[i],
      ],
    );
    _state = state.copyWith(performed: newPerformed, updatedAt: DateTime.now());
    if (_activeSetExerciseIndex == index) {
      _resetSetState();
    }
    await _persist();
    notifyListeners();
    return true;
  }

  /// Reorder target sets within one exercise. Refuses when either position
  /// contains a performed set — moving performed sets is intentionally
  /// off-limits because their indices are referenced by callbacks/result
  /// snapshots that have already escaped the runner.
  Future<bool> reorderSets(
    int exerciseIndex,
    int oldIndex,
    int newIndex,
  ) async {
    final plan = _plan;
    if (plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final ex = plan.exercises[exerciseIndex];
    final n = ex.sets.length;
    if (oldIndex < 0 ||
        oldIndex >= n ||
        newIndex < 0 ||
        newIndex >= n) {
      return false;
    }
    if (oldIndex == newIndex) return true;
    if (getPerformedSet(exerciseIndex, oldIndex) != null) return false;
    if (getPerformedSet(exerciseIndex, newIndex) != null) return false;
    final list = [...ex.sets];
    final moved = list.removeAt(oldIndex);
    list.insert(newIndex, moved);
    _plan = plan.copyWith(
      exercises: [
        for (var i = 0; i < plan.exercises.length; i++)
          i == exerciseIndex ? ex.copyWith(sets: list) : plan.exercises[i],
      ],
    );
    await _persistPlan();
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _startGlobalTimer() {
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _state;
      if (state == null || !state.isActive) return;
      _elapsed = _computeElapsed(state);
      notifyListeners();
    });
  }

  Duration _computeElapsed(WorkoutRunnerState state) {
    final raw = DateTime.now().difference(state.startedAt) - state.pausedFor;
    return raw.isNegative ? Duration.zero : raw;
  }

  void _beginRest(Duration duration) {
    _restTicker?.cancel();
    _restRemaining = duration;
    _restTotal = duration;
    onRestStarted?.call(duration);
    _restTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining.inSeconds <= 1) {
        t.cancel();
        _restTicker = null;
        _restRemaining = Duration.zero;
        _restTotal = Duration.zero;
        onRestTick?.call(Duration.zero);
        onRestCompleted?.call();
        notifyListeners();
      } else {
        _restRemaining -= const Duration(seconds: 1);
        onRestTick?.call(_restRemaining);
        notifyListeners();
      }
    });
  }

  void _resetSetState() {
    _setTicker?.cancel();
    _setTicker = null;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
    _activeSetExerciseIndex = null;
    _activeSetIndex = null;
    _timedTargetFired = false;
  }

  void _resetRest({bool notify = false}) {
    _restTicker?.cancel();
    _restTicker = null;
    _restRemaining = Duration.zero;
    _restTotal = Duration.zero;
    if (notify) notifyListeners();
  }

  void _stopAllTimers() {
    _globalTimer?.cancel();
    _globalTimer = null;
    _resetSetState();
    _resetRest();
  }

  Future<bool> _recordPerformedSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    double? weight,
    int? rir,
    Duration? duration,
    Duration? pause,
  }) async {
    final state = _state;
    final plan = _plan;
    if (state == null || plan == null) return false;
    if (exerciseIndex < 0 || exerciseIndex >= plan.exercises.length) {
      return false;
    }
    final sets = plan.exercises[exerciseIndex].sets;
    if (setIndex < 0 || setIndex >= sets.length) return false;

    final current = plan.exercises[exerciseIndex];
    final newSet = PerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      actualReps: reps,
      actualWeight: weight,
      rir: rir,
      duration: duration,
      pause: pause,
      type: sets[setIndex].type,
      completedAt: DateTime.now(),
    );

    final existing = state.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse:
          () => PerformedExercise(
            exerciseIndex: exerciseIndex,
            exerciseName: current.name,
            sets: const [],
          ),
    );

    final mergedSets = [
      for (final s in existing.sets)
        if (s.setIndex == setIndex) newSet else s,
      if (!existing.sets.any((s) => s.setIndex == setIndex)) newSet,
    ];
    final updatedExercise = existing.copyWith(
      exerciseName:
          existing.exerciseName.isEmpty ? current.name : existing.exerciseName,
      sets: mergedSets,
    );

    final hadExisting = state.performed.any(
      (e) => e.exerciseIndex == exerciseIndex,
    );
    final updatedPerformed = [
      for (final e in state.performed)
        if (e.exerciseIndex == exerciseIndex) updatedExercise else e,
      if (!hadExisting) updatedExercise,
    ];

    _state = state.copyWith(
      performed: updatedPerformed,
      currentSetIndex: setIndex + 1,
      updatedAt: DateTime.now(),
    );
    await _persist();
    onSetCompleted?.call(newSet);
    return true;
  }

  Future<void> _persist() async {
    final state = _state;
    if (state == null) return;
    await _storage.saveState(state.toJson(), slot: _slot);
    await _persistPlan();
  }

  Future<void> _persistPlan() async {
    final plan = _plan;
    if (plan == null) return;
    await _storage.savePlan(plan.toJson(), slot: _slot);
  }

  @override
  void dispose() {
    _stopAllTimers();
    _finishedController.close();
    super.dispose();
  }
}
