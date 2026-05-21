import 'dart:async';

import '../models/workout_plan.dart';
import 'plan_draft_storage.dart';

class PlanDraftController {
  PlanDraftController({
    required this.storage,
    this.slot = 'default',
    this.debounce = const Duration(milliseconds: 800),
  });

  final PlanDraftStorage storage;
  final String slot;
  final Duration debounce;

  Timer? _timer;
  WorkoutPlan? _pending;
  bool _disposed = false;

  Future<void> onPlanChanged(WorkoutPlan plan) async {
    if (_disposed) return;
    _pending = plan;
    _timer?.cancel();
    _timer = Timer(debounce, _flush);
  }

  Future<WorkoutPlan?> resume() => storage.readDraft(slot: slot);

  Future<void> publish() async {
    _timer?.cancel();
    _timer = null;
    _pending = null;
    await storage.discardDraft(slot: slot);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    if (_pending != null) {
      final plan = _pending!;
      _pending = null;
      await storage.saveDraft(plan, slot: slot);
    }
  }

  void _flush() {
    final plan = _pending;
    _timer = null;
    if (plan == null) return;
    _pending = null;
    storage.saveDraft(plan, slot: slot);
  }
}
