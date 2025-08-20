import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'storage.dart';
import 'package:fitness_workout/src/models/workout_plan.dart';
import 'package:fitness_workout/src/models/runner_result.dart';

class WorkoutRunnerController extends ChangeNotifier {
  static final WorkoutRunnerController _instance =
      WorkoutRunnerController._internal();
  factory WorkoutRunnerController() => _instance;
  WorkoutRunnerController._internal();

  late RunnerStorage _storage;

  WorkoutPlan? _plan;
  WorkoutRunnerState? _state;
  int? _activeExerciseIndex;
  Timer? _globalTimer;
  Duration elapsed = Duration.zero;

  WorkoutPlan? get plan => _plan;
  WorkoutRunnerState? get state => _state;
  bool get isRunning => _state?.isActive == true;
  WorkoutExercise? get currentExercise =>
      _plan?.exercises[_state!.exerciseIndex];
  // Verfügbare Übungen (leer, wenn kein Plan)
  List<WorkoutExercise> get exercises => _plan?.exercises ?? const [];

  // Aktueller Übungsindex (0, wenn noch kein State)
  int get currentExerciseIndex => _state?.exerciseIndex ?? 0;
  int get activeExerciseIndex => _activeExerciseIndex ?? 0;
  // Helper: ist diese Übung die aktuell aktive?
  bool isExerciseActive(int index) => index == currentExerciseIndex;

  Duration tickEvery = const Duration(seconds: 1);
  Duration defaultSetRest = const Duration(seconds: 90);
  Timer? _setTicker;
  DateTime? _setStartedAt;
  Duration _setElapsed = Duration.zero;
  int? _activeSetExerciseIndex;
  int? _activeSetIndex;

  Timer? _restTicker;
  Duration _restRemaining = Duration.zero;

  bool get hasActiveExercise => _state?.activeExerciseIndex != null;
  int? get activeSetExerciseIndex => _activeSetExerciseIndex;
  int? get activeSetIndex => _activeSetIndex;
  bool get isSetRunning => _setTicker != null;
  Duration get currentSetElapsed => _setElapsed;
  bool get isResting => _restTicker != null;
  Duration get restRemaining => _restRemaining;

  Future<void> configure({
    RunnerStorage? storage,
    bool autoResume = true,
  }) async {
    _storage = storage ?? PrefsRunnerStorage();
    if (autoResume) {
      await _autoResume();
    }
  }

  Future<void> _autoResume() async {
    try {
      final savedState = await _storage.readState();
      if (savedState == null) return;

      final savedPlan = await _storage.readPlan();
      if (savedPlan == null) return;

      final st = WorkoutRunnerState.fromJson(savedState);
      if (st.isActive != true) return;

      _plan = WorkoutPlan.fromJson(savedPlan);
      _state = st;
      _activeExerciseIndex = st.activeExerciseIndex;
      _startGlobalTimer(); // Resume Timer
      notifyListeners();
    } catch (_) {}
  }

  Future<void> start(WorkoutPlan plan, {bool resumeIfPossible = true}) async {
    final switchingPlan = _state != null && _state!.planId != plan.id;
    _plan = plan;
    await _storage.savePlan(json: plan.toJson());

    if (_state == null || !resumeIfPossible || switchingPlan) {
      final now = DateTime.now();
      _state = WorkoutRunnerState(
        planId: plan.id,
        exerciseIndex: 0,
        activeExerciseIndex: null,
        setIndex: 0,
        isActive: true,
        startedAt: now,
        updatedAt: now,
        performed: [],
        exerciseStartedAt: now,
        setStartedAt: now,
      );
      _activeExerciseIndex = null;
      elapsed = Duration.zero;
    }
    _setTicker?.cancel();
    _setTicker = null;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
    _activeSetExerciseIndex = null;
    _activeSetIndex = null;
    _restTicker?.cancel();
    _restTicker = null;
    _restRemaining = Duration.zero;
    _startGlobalTimer();
    _persist();
    notifyListeners();
  }

  void _startGlobalTimer() {
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(tickEvery, (_) {
      if (_state?.isActive == true) {
        elapsed = DateTime.now().difference(_state!.startedAt);
        notifyListeners(); // damit Widgets den Timer sehen
      }
    });
  }

  // WorkoutRunnerController.dart
  void changeExerciseIndex(int newIndex) {
    if (_plan == null || _state == null) return;
    if (newIndex < 0 || newIndex >= _plan!.exercises.length) return;
    if (_state!.exerciseIndex == newIndex) return;
    final now = DateTime.now();
    _state = _state!.copyWith(
      exerciseIndex: newIndex,
      setIndex: 0,
      updatedAt: now,
    );
    _persist();
    notifyListeners();
  }

  void setActiveExercise(int index) {
    if (_plan == null || _state == null) return;
    if (index < 0 || index >= _plan!.exercises.length) return;
    final already = _state!.activeExerciseIndex;
    if (already != null) return;
    final now = DateTime.now();
    _activeExerciseIndex = index;
    _state = _state!.copyWith(
      activeExerciseIndex: index,
      setIndex: 0,
      updatedAt: now,
    );
    _persist();
    notifyListeners();
  }

  void clearActiveExercise() {
    if (_plan == null || _state == null) return;
    if (_state!.activeExerciseIndex == null) return;
    final s = _state!;
    _state = WorkoutRunnerState(
      planId: s.planId,
      exerciseIndex: s.exerciseIndex,
      activeExerciseIndex: null,
      setIndex: s.setIndex,
      isActive: s.isActive,
      startedAt: s.startedAt,
      updatedAt: DateTime.now(),
      performed: s.performed,
      exerciseStartedAt: s.exerciseStartedAt,
      setStartedAt: s.setStartedAt,
    );
    _activeExerciseIndex = null;
    _persist();
    notifyListeners();
  }

  // In WorkoutRunnerController: Methoden ergänzen
  bool canActivateSet(int exerciseIndex) {
    if (_state == null) return false;
    return _state!.activeExerciseIndex != null &&
        _state!.activeExerciseIndex == exerciseIndex;
  }

  bool startSet(int exerciseIndex, int setIndex) {
    if (_plan == null || _state == null) return false;
    if (!canActivateSet(exerciseIndex)) return false;
    if (_activeSetExerciseIndex != null || _activeSetIndex != null) {
      return false;
    }
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return false;
    if (setIndex < 0 || setIndex >= exercises[exerciseIndex].sets.length) {
      return false;
    }
    if (getPerformedSet(exerciseIndex, setIndex) != null) return false;
    _restTicker?.cancel();
    _restTicker = null;
    _restRemaining = Duration.zero;
    _activeSetExerciseIndex = exerciseIndex;
    _activeSetIndex = setIndex;
    _setStartedAt = DateTime.now();
    _setElapsed = Duration.zero;
    _setTicker?.cancel();
    _setTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_setStartedAt != null) {
        _setElapsed = DateTime.now().difference(_setStartedAt!);
        notifyListeners();
      }
    });
    notifyListeners();
    return true;
  }

  Future<bool> finishActiveSet({
    required double weight,
    required int reps,
    required int rir,
    Duration? setDuration,
    int restSeconds = 90,
  }) async {
    if (_plan == null || _state == null) return false;
    if (_activeSetExerciseIndex == null || _activeSetIndex == null) {
      return false;
    }
    final taken = setDuration ?? _setElapsed;
    final ex = _activeSetExerciseIndex!;
    final si = _activeSetIndex!;
    _setTicker?.cancel();
    _setTicker = null;
    _setStartedAt = null;
    _setElapsed = Duration.zero;
    await completeSet(
      exerciseIndex: ex,
      setIndex: si,
      weight: weight,
      reps: reps,
      rir: rir,
      setDuration: taken,
    );
    _activeSetExerciseIndex = null;
    _activeSetIndex = null;
    beginRest(seconds: restSeconds);
    notifyListeners();
    return true;
  }

  void beginRest({int seconds = 90}) {
    _restTicker?.cancel();
    if (seconds <= 0) {
      _restTicker = null;
      _restRemaining = Duration.zero;
      notifyListeners();
      return;
    }
    _restRemaining = Duration(seconds: seconds);
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
    notifyListeners();
  }

  void skipRest() {
    _restTicker?.cancel();
    _restTicker = null;
    _restRemaining = Duration.zero;
    notifyListeners();
  }

  Future<void> completeSet({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    required int rir,
    Duration? setDuration,
  }) async {
    if (_state == null || _plan == null) return;

    final currentEx = _plan!.exercises[exerciseIndex];

    final newSet = PerformedSet(
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      actualWeight: weight,
      actualReps: reps,
      rir: rir,
      restTaken: setDuration,
      completedAt: DateTime.now(),
    );

    final existingExercise = _state!.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse:
          () => PerformedExercise(
            exerciseIndex: exerciseIndex,
            exerciseName: currentEx.name,
            sets: const [],
          ),
    );

    final updatedSets = [
      // falls schon einer mit gleichem setIndex vorhanden ist, behalten (kein Duplikat)
      for (final s in existingExercise.sets) s,
      if (!existingExercise.sets.any((s) => s.setIndex == setIndex)) newSet,
    ];

    final updatedExercise = PerformedExercise(
      exerciseIndex: existingExercise.exerciseIndex,
      exerciseName:
          existingExercise.exerciseName.isEmpty
              ? currentEx.name
              : existingExercise.exerciseName,
      sets: updatedSets,
    );

    final updatedPerformed = [
      for (final e in _state!.performed)
        if (e.exerciseIndex == exerciseIndex) updatedExercise else e,
      if (!_state!.performed.any((e) => e.exerciseIndex == exerciseIndex))
        updatedExercise,
    ];

    _state = _state!.copyWith(
      performed: updatedPerformed,
      setIndex: setIndex + 1,
      updatedAt: DateTime.now(),
    );

    await _persist();
    notifyListeners();
  }

  PerformedSet? getPerformedSet(int exerciseIndex, int setIndex) {
    final st = _state;
    if (st == null) return null;
    final ex = st.performed.firstWhere(
      (e) => e.exerciseIndex == exerciseIndex,
      orElse:
          () => PerformedExercise(
            exerciseIndex: exerciseIndex,
            exerciseName: '',
            sets: const [],
          ),
    );
    try {
      return ex.sets.firstWhere((s) => s.setIndex == setIndex);
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePerformedSet({
    required int exerciseIndex,
    required int setIndex,
    required double weight,
    required int reps,
    required int rir,
  }) async {
    if (_state == null) return;

    final updatedPerformed =
        _state!.performed.map((ex) {
          if (ex.exerciseIndex != exerciseIndex) return ex;
          final updatedSets =
              ex.sets.map((s) {
                if (s.setIndex != setIndex) return s;
                return PerformedSet(
                  exerciseIndex: s.exerciseIndex,
                  setIndex: s.setIndex,
                  actualReps: reps,
                  actualWeight: weight,
                  rir: rir,
                  restTaken: s.restTaken,
                  completedAt: s.completedAt,
                );
              }).toList();
          return PerformedExercise(
            exerciseIndex: ex.exerciseIndex,
            exerciseName: ex.exerciseName,
            sets: updatedSets,
          );
        }).toList();

    _state = _state!.copyWith(
      performed: updatedPerformed,
      updatedAt: DateTime.now(),
    );
    await _persist();
    notifyListeners();
  }

  Future<WorkoutResult?> finish() async {
    //TODO DATEN AN SUPABASE!!!
    if (_plan == null || _state == null) return null;

    _state = _state!.copyWith(isActive: false, updatedAt: DateTime.now());
    await _persist();
    await _storage.clearState();
    await _storage.clearPlan();

    final result = WorkoutResult(
      planId: _state!.planId,
      startedAt: _state!.startedAt,
      finishedAt: DateTime.now(),
      exercises: [],
    );

    _globalTimer?.cancel();
    _globalTimer = null;

    _plan = null;
    _state = null;
    elapsed = Duration.zero;

    notifyListeners();
    return result;
  }

  Future<void> _persist() async {
    if (_state == null) return;
    await _storage.saveState(json: _state!.toJson());
    if (_plan != null) {
      await _storage.savePlan(json: _plan!.toJson());
    }
  }

  // String _key(String planId) => planId;
}
