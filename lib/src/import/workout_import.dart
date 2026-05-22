import 'dart:convert';

import '../models/cardio/cardio_plan.dart';
import '../models/workout_plan.dart';

enum ImportConflictPolicy { replace, duplicate, skip }

class ImportError {
  final String key;
  final String message;
  final String? planId;

  const ImportError({required this.key, required this.message, this.planId});

  Map<String, dynamic> toJson() => {
    'key': key,
    'message': message,
    if (planId != null) 'planId': planId,
  };
}

class ImportResult {
  final List<WorkoutPlan> importedWorkouts;
  final List<CardioPlan> importedCardio;
  final List<String> skippedIds;
  final List<String> duplicatedIds;
  final List<ImportError> errors;

  const ImportResult({
    this.importedWorkouts = const [],
    this.importedCardio = const [],
    this.skippedIds = const [],
    this.duplicatedIds = const [],
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
  int get total => importedWorkouts.length + importedCardio.length;

  Map<String, dynamic> toJson() => {
    'importedWorkouts': importedWorkouts.map((p) => p.toJson()).toList(),
    'importedCardio': importedCardio.map((p) => p.toJson()).toList(),
    'skippedIds': skippedIds,
    'duplicatedIds': duplicatedIds,
    'errors': errors.map((e) => e.toJson()).toList(),
  };
}

abstract class WorkoutImport {
  static ImportResult fromBundle(
    Map<String, dynamic> bundle, {
    ImportConflictPolicy policy = ImportConflictPolicy.skip,
    Iterable<String> existingPlanIds = const [],
    Iterable<String> existingCardioIds = const [],
  }) {
    final importedWorkouts = <WorkoutPlan>[];
    final importedCardio = <CardioPlan>[];
    final skippedIds = <String>[];
    final duplicatedIds = <String>[];
    final errors = <ImportError>[];

    final takenWorkoutIds = existingPlanIds.toSet();
    final takenCardioIds = existingCardioIds.toSet();

    final rawWorkouts = bundle['workoutPlans'];
    if (rawWorkouts is List) {
      for (var i = 0; i < rawWorkouts.length; i++) {
        final entry = rawWorkouts[i];
        if (entry is! Map) {
          errors.add(
            ImportError(
              key: 'workoutPlans[$i]',
              message: 'Expected an object, got ${entry.runtimeType}.',
            ),
          );
          continue;
        }
        final json = entry.cast<String, dynamic>();
        WorkoutPlan plan;
        try {
          plan = WorkoutPlan.fromJson(json);
        } catch (e) {
          errors.add(
            ImportError(
              key: 'workoutPlans[$i]',
              message: e.toString(),
              planId: json['id'] is String ? json['id'] as String : null,
            ),
          );
          continue;
        }

        final outcome = _resolveConflict(plan.id, takenWorkoutIds, policy);
        if (outcome.skip) {
          skippedIds.add(plan.id);
          continue;
        }
        final finalId = outcome.id;
        final finalPlan = finalId == plan.id ? plan : plan.cloneWithId(finalId);
        importedWorkouts.add(finalPlan);
        takenWorkoutIds.add(finalId);
        if (outcome.duplicated) duplicatedIds.add(finalId);
      }
    }

    final rawCardio = bundle['cardioPlans'];
    if (rawCardio is List) {
      for (var i = 0; i < rawCardio.length; i++) {
        final entry = rawCardio[i];
        if (entry is! Map) {
          errors.add(
            ImportError(
              key: 'cardioPlans[$i]',
              message: 'Expected an object, got ${entry.runtimeType}.',
            ),
          );
          continue;
        }
        final json = entry.cast<String, dynamic>();
        CardioPlan plan;
        try {
          plan = CardioPlan.fromJson(json);
        } catch (e) {
          errors.add(
            ImportError(
              key: 'cardioPlans[$i]',
              message: e.toString(),
              planId: json['id'] is String ? json['id'] as String : null,
            ),
          );
          continue;
        }

        final outcome = _resolveConflict(plan.id, takenCardioIds, policy);
        if (outcome.skip) {
          skippedIds.add(plan.id);
          continue;
        }
        final finalId = outcome.id;
        final finalPlan = finalId == plan.id ? plan : plan.cloneWithId(finalId);
        importedCardio.add(finalPlan);
        takenCardioIds.add(finalId);
        if (outcome.duplicated) duplicatedIds.add(finalId);
      }
    }

    return ImportResult(
      importedWorkouts: importedWorkouts,
      importedCardio: importedCardio,
      skippedIds: skippedIds,
      duplicatedIds: duplicatedIds,
      errors: errors,
    );
  }

  static ImportResult fromJsonString(
    String json, {
    ImportConflictPolicy policy = ImportConflictPolicy.skip,
    Iterable<String> existingPlanIds = const [],
    Iterable<String> existingCardioIds = const [],
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } catch (e) {
      return ImportResult(
        errors: [ImportError(key: 'json', message: e.toString())],
      );
    }
    if (decoded is! Map) {
      return ImportResult(
        errors: [
          ImportError(
            key: 'json',
            message:
                'Expected top-level JSON object, got ${decoded.runtimeType}.',
          ),
        ],
      );
    }
    return fromBundle(
      decoded.cast<String, dynamic>(),
      policy: policy,
      existingPlanIds: existingPlanIds,
      existingCardioIds: existingCardioIds,
    );
  }

  static _ConflictOutcome _resolveConflict(
    String originalId,
    Set<String> taken,
    ImportConflictPolicy policy,
  ) {
    if (!taken.contains(originalId)) {
      return _ConflictOutcome(id: originalId);
    }
    switch (policy) {
      case ImportConflictPolicy.replace:
        return _ConflictOutcome(id: originalId);
      case ImportConflictPolicy.skip:
        return const _ConflictOutcome.skipped();
      case ImportConflictPolicy.duplicate:
        var n = 1;
        var candidate = '${originalId}_imported_$n';
        while (taken.contains(candidate)) {
          n++;
          candidate = '${originalId}_imported_$n';
        }
        return _ConflictOutcome(id: candidate, duplicated: true);
    }
  }
}

class _ConflictOutcome {
  final String id;
  final bool duplicated;
  final bool skip;

  const _ConflictOutcome({required this.id, this.duplicated = false})
    : skip = false;
  const _ConflictOutcome.skipped() : id = '', duplicated = false, skip = true;
}
