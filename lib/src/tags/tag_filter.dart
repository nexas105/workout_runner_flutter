import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_result.dart';
import '../models/workout_plan.dart';
import '../models/workout_result.dart';
import 'workout_tags.dart';

enum TagMatchMode { any, all, none }

abstract class TagFilter {
  static List<T> apply<T>(
    List<T> items,
    Map<String, dynamic>? Function(T) metaOf,
    Iterable<String> filterTags, {
    TagMatchMode mode = TagMatchMode.any,
  }) {
    final wanted = <String>{};
    for (final t in filterTags) {
      final c = t.trim().toLowerCase();
      if (c.isNotEmpty) wanted.add(c);
    }
    if (wanted.isEmpty) {
      return mode == TagMatchMode.none ? List<T>.from(items) : <T>[];
    }
    final out = <T>[];
    for (final item in items) {
      final tags = WorkoutTags.read(metaOf(item)).toSet();
      final matches = switch (mode) {
        TagMatchMode.any => wanted.any(tags.contains),
        TagMatchMode.all => wanted.every(tags.contains),
        TagMatchMode.none => !wanted.any(tags.contains),
      };
      if (matches) out.add(item);
    }
    return out;
  }

  static List<WorkoutPlan> filterPlans(
    List<WorkoutPlan> plans,
    Iterable<String> tags, {
    TagMatchMode mode = TagMatchMode.any,
  }) => apply<WorkoutPlan>(plans, (p) => p.meta, tags, mode: mode);

  // WorkoutResult currently exposes no meta field; the metaOf hook returns
  // null so behaviour stays consistent with "no tags" (any/all → empty,
  // none → full list). Swap the hook once results gain a meta map.
  static List<WorkoutResult> filterResults(
    List<WorkoutResult> results,
    Iterable<String> tags, {
    TagMatchMode mode = TagMatchMode.any,
  }) => apply<WorkoutResult>(results, (_) => null, tags, mode: mode);

  static List<CardioPlan> filterCardioPlans(
    List<CardioPlan> plans,
    Iterable<String> tags, {
    TagMatchMode mode = TagMatchMode.any,
  }) => apply<CardioPlan>(plans, (p) => p.meta, tags, mode: mode);

  static List<CardioResult> filterCardioResults(
    List<CardioResult> results,
    Iterable<String> tags, {
    TagMatchMode mode = TagMatchMode.any,
  }) => apply<CardioResult>(results, (r) => r.meta, tags, mode: mode);
}
