import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/performed_exercise.dart';
import '../models/performed_set.dart';
import '../models/workout_exercise.dart';
import '../models/workout_plan.dart';
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

  Timer? _setTicker;
  DateTime? _setStartedAt;
  Duration _setElapsed = Duration.zero;
  int? _activeSetExerciseIndex;
  int? _activeSetIndex;

  Timer? _restTicker;
  Duration _restRemaining = Duration.zero;

  /// Default rest applied when [finishCurrentSet] is called without
  /// `restSeconds`, and when [addSetToExercise] is called without `rest`.
  Duration defaultRest = const Duration(seconds: 90);

  final StreamController<WorkoutResult> _finishedController =
      StreamController<WorkoutResult>.broadcast();

  /// Stream of [WorkoutResult]s, one per completed workout. Convenient when
  /// you want to send results to a remote sink (Supabase, Firestore, …) from
  /// anywhere in the tree.
  Stream<WorkoutResult> get finished => _finishedController.stream;

  /// Optional fire-and-forget callback. Alternative to [finished].
  WorkoutFinishedCallback? onFinished;

  // ---------------------------------------------------------------------------
  // Read-only accessors
  // ---------------------------------------------------------------------------

  WorkoutPlan? get plan => _plan;
  WorkoutRunnerState? get state => _state;
  bool get isRunning => _state?.isActive == true;
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

  // Set tracking
  int? get activeSetExerciseIndex => _activeSetExerciseIndex;
  int? get activeSetIndex => _activeSetIndex;
  bool get isSetRunning => _setTicker != null;
  Duration get currentSetElapsed => _setElapsed;

  bool get isResting => _restTicker != null;
  Duration get restRemaining => _restRemaining;

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
      if (!state.isActive) return false;

      _plan = WorkoutPlan.fromJson(rawPlan);
      _state = state;
      _elapsed = DateTime.now().difference(state.startedAt);
      _startGlobalTimer();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Start a new workout. If [resumeIfPossible] is true and an active state
  /// for the same plan id exists, that state is reused.
  Future<void> start(
    WorkoutPlan plan, {
    bool resumeIfPossible = true,
  }) async {
    final canResume = resumeIfPossible &&
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
      _elapsed = DateTime.now().difference(_state!.startedAt);
    }

    _resetSetState();
    _resetRest();
    _startGlobalTimer();
    await _persist();
    notifyListeners();
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

    final details = state.performed.map((perf) {
      final original = perf.exerciseIndex < plan.exercises.length
          ? plan.exercises[perf.exerciseIndex]
          : null;
      return PerformedExerciseDetails(
        exerciseId: original?.id ?? '',
        exerciseName: perf.exerciseName,
        sets: perf.sets,
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
  void showExercise(int index) {
    final state = _state;
    final plan = _plan;
    if (plan == null || state == null) return;
    if (index < 0 || index >= plan.exercises.length) return;
    if (state.currentExerciseIndex == index) return;
    _state = state.copyWith(
      currentExerciseIndex: index,
      currentSetIndex: 0,
      updatedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  /// Mark an exercise as the active one (the one whose sets can be started).
  /// No-op if another exercise is already active.
  void setActiveExercise(int index) {
    final state = _state;
    final plan = _plan;
    if (plan == null || state == null) return;
    if (state.activeExerciseIndex != null) return;
    if (index < 0 || index >= plan.exercises.length) return;
    _state = state.copyWith(
      activeExerciseIndex: index,
      currentSetIndex: 0,
      updatedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
  }

  /// Clears the active exercise. If a set was running for it, the set is
  /// also discarded.
  void clearActiveExercise() {
    final state = _state;
    if (state == null || state.activeExerciseIndex == null) return;
    _resetSetState();
    _resetRest();
    _state = state.copyWith(
      activeExerciseIndex: null,
      updatedAt: DateTime.now(),
    );
    _persist();
    notifyListeners();
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
    _setTicker?.cancel();
    _setTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _setStartedAt;
      if (startedAt == null) return;
      _setElapsed = DateTime.now().difference(startedAt);
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

    final taken = setDuration ?? _setElapsed;
    _setTicker?.cancel();
    _setTicker = null;
    _setStartedAt = null;
    _setElapsed = Duration.zero;

    final restDuration = rest ?? defaultRest;
    await _recordPerformedSet(
      exerciseIndex: exIdx,
      setIndex: setIdx,
      reps: reps,
      weight: weight,
      rir: rir,
      duration: taken,
      pause: restDuration,
    );

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
  Future<void> logSet({
    required int exerciseIndex,
    required int setIndex,
    required int reps,
    double? weight,
    int? rir,
    Duration? duration,
    Duration? pause,
  }) async {
    await _recordPerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      reps: reps,
      weight: weight,
      rir: rir,
      duration: duration,
      pause: pause,
    );
  }

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
    final performed = state.performed.map((ex) {
      if (ex.exerciseIndex != exerciseIndex) return ex;
      final sets = ex.sets.map((s) {
        if (s.setIndex != setIndex) return s;
        return s.copyWith(
          actualReps: reps,
          actualWeight: weight,
          rir: rir,
        );
      }).toList();
      return ex.copyWith(sets: sets);
    }).toList();
    _state = state.copyWith(
      performed: performed,
      updatedAt: DateTime.now(),
    );
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

  void skipRest() => _resetRest(notify: true);

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

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _startGlobalTimer() {
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = _state;
      if (state == null || !state.isActive) return;
      _elapsed = DateTime.now().difference(state.startedAt);
      notifyListeners();
    });
  }

  void _beginRest(Duration duration) {
    _restTicker?.cancel();
    _restRemaining = duration;
    _restTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining.inSeconds <= 1) {
        t.cancel();
        _restTicker = null;
        _restRemaining = Duration.zero;
        notifyListeners();
      } else {
        _restRemaining -= const Duration(seconds: 1);
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
  }

  void _resetRest({bool notify = false}) {
    _restTicker?.cancel();
    _restTicker = null;
    _restRemaining = Duration.zero;
    if (notify) notifyListeners();
  }

  void _stopAllTimers() {
    _globalTimer?.cancel();
    _globalTimer = null;
    _resetSetState();
    _resetRest();
  }

  Future<void> _recordPerformedSet({
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
    if (state == null || plan == null) return;

    final current = plan.exercises[exerciseIndex];
    final newSet = PerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      actualReps: reps,
      actualWeight: weight,
      rir: rir,
      duration: duration,
      pause: pause,
      completedAt: DateTime.now(),
    );

    final existing = state.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse: () => PerformedExercise(
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

    final hadExisting =
        state.performed.any((e) => e.exerciseIndex == exerciseIndex);
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
