import '../exercise_category.dart';
import 'cardio_interval.dart';
import 'cardio_plan.dart';

/// Fluent builder for creating [CardioPlan]s. Mirrors `WorkoutPlanBuilder`.
///
/// Example:
///
/// ```dart
/// final plan = CardioPlanBuilder('5x400m intervals',
///         discipline: CardioDiscipline.running)
///     .warmup(duration: Duration(minutes: 5))
///     .interval(name: '400m', duration: Duration(minutes: 2), met: 11)
///     .rest(duration: Duration(minutes: 1))
///     // … repeat …
///     .cooldown(duration: Duration(minutes: 5))
///     .build();
/// ```
class CardioPlanBuilder {
  CardioPlanBuilder(
    this.name, {
    String? id,
    this.description,
    this.discipline = CardioDiscipline.mixed,
    this.category,
    Map<String, dynamic>? meta,
  })  : id = id ?? _slug(name),
        meta = meta == null ? null : Map<String, dynamic>.from(meta);

  final String id;
  final String name;
  final String? description;
  final CardioDiscipline discipline;
  final ExerciseCategory? category;
  final Map<String, dynamic>? meta;

  final List<CardioInterval> _intervals = [];

  CardioPlanBuilder interval({
    required String name,
    CardioPhase phase = CardioPhase.work,
    Duration? duration,
    double? distanceMeters,
    String? intensity,
    Duration? pacePerKm,
    String? notes,
    double? met,
    String? id,
  }) {
    final baseId = id ?? _slug(name);
    _intervals.add(
      CardioInterval(
        id: _uniqueIntervalId(baseId),
        name: name,
        phase: phase,
        targetDuration: duration,
        targetDistanceMeters: distanceMeters,
        intensity: intensity,
        targetPacePerKm: pacePerKm,
        notes: notes,
        met: met,
      ),
    );
    return this;
  }

  CardioPlanBuilder warmup({Duration? duration, double? distanceMeters}) =>
      interval(
        name: 'Warmup',
        phase: CardioPhase.warmup,
        duration: duration,
        distanceMeters: distanceMeters,
      );

  CardioPlanBuilder cooldown({Duration? duration, double? distanceMeters}) =>
      interval(
        name: 'Cooldown',
        phase: CardioPhase.cooldown,
        duration: duration,
        distanceMeters: distanceMeters,
      );

  CardioPlanBuilder rest({Duration? duration, String? name}) => interval(
        name: name ?? 'Rest',
        phase: CardioPhase.rest,
        duration: duration,
      );

  /// Append an already-constructed interval.
  CardioPlanBuilder addInterval(CardioInterval interval) {
    _intervals.add(interval);
    return this;
  }

  CardioPlan build() => CardioPlan(
        id: id,
        name: name,
        description: description,
        discipline: discipline,
        category: category,
        intervals: List<CardioInterval>.unmodifiable(_intervals),
        meta: meta,
      );

  String _uniqueIntervalId(String baseId) {
    final base = baseId.isEmpty ? 'interval' : baseId;
    var candidate = base;
    var suffix = 2;
    final existing = _intervals.map((i) => i.id).toSet();
    while (existing.contains(candidate)) {
      candidate = '$base-$suffix';
      suffix++;
    }
    return candidate;
  }
}

String _slug(String input) {
  final normalized = input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'plan' : normalized;
}
