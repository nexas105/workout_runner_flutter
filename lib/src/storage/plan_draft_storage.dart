import 'dart:async';

import '../models/workout_plan.dart';

/// Persistence contract for in-progress [WorkoutPlan] drafts produced by
/// the plan editor.
///
/// Drafts live separately from finalized plans so that long edit sessions
/// can survive app restarts without polluting the user's saved plan list.
/// Multiple [slot]s allow editing more than one draft in parallel (e.g.
/// one per template kind, or one per editor instance).
abstract class PlanDraftStorage {
  Future<void> saveDraft(WorkoutPlan draft, {String slot = 'default'});

  Future<WorkoutPlan?> readDraft({String slot = 'default'});

  Future<bool> hasDraft({String slot = 'default'});

  Future<void> discardDraft({String slot = 'default'});

  Future<List<String>> listSlots();
}

class InMemoryPlanDraftStorage implements PlanDraftStorage {
  final Map<String, WorkoutPlan> _drafts = <String, WorkoutPlan>{};

  @override
  Future<void> saveDraft(WorkoutPlan draft, {String slot = 'default'}) async {
    _drafts[slot] = draft;
  }

  @override
  Future<WorkoutPlan?> readDraft({String slot = 'default'}) async {
    return _drafts[slot];
  }

  @override
  Future<bool> hasDraft({String slot = 'default'}) async {
    return _drafts.containsKey(slot);
  }

  @override
  Future<void> discardDraft({String slot = 'default'}) async {
    _drafts.remove(slot);
  }

  @override
  Future<List<String>> listSlots() async {
    return _drafts.keys.toList(growable: false);
  }
}
