import '../models/cardio/cardio_lap.dart';
import '../models/cardio/cardio_plan.dart';
import '../models/cardio/cardio_result.dart';
import '../models/performed_set.dart';
import '../models/workout_result.dart';

/// Pure formatting helpers for sharing [WorkoutResult] and [CardioResult]
/// snapshots as plain text or Markdown. No Social SDK integration, no I/O —
/// callers wire these into share sheets, clipboard buttons, or messaging.
abstract class ShareHelpers {
  /// Short, ~3-line plain-text summary of a strength session, suitable for a
  /// share sheet body or chat message.
  static String toShareText(WorkoutResult result) {
    final buf = StringBuffer();
    buf.writeln('Workout: ${result.planId}');
    buf.writeln(
      'Duration ${_formatDuration(result.duration)} '
      '- ${result.totalSets} sets, ${result.totalReps} reps',
    );
    buf.write('Total volume: ${_formatVolume(result.totalVolume)} kg');
    return buf.toString();
  }

  /// Short, ~3-line plain-text summary of a cardio session.
  static String toShareTextCardio(CardioResult result) {
    final buf = StringBuffer();
    final title = result.planName.isEmpty ? result.planId : result.planName;
    buf.writeln('Cardio: $title (${_disciplineLabel(result.discipline)})');
    buf.writeln(
      'Duration ${_formatDuration(result.duration)} '
      '- ${_formatDistance(result.totalDistanceMeters)}',
    );
    final pace = result.avgPacePerKm;
    buf.write(
      pace == null
          ? 'Laps: ${result.totalLaps}'
          : 'Avg pace: ${_formatDuration(pace)} /km - ${result.totalLaps} laps',
    );
    return buf.toString();
  }

  /// Multi-line Markdown report of a strength session. Header line always
  /// renders, even for an empty result, so consumers can paste it without
  /// post-processing.
  static String toMarkdown(WorkoutResult result) {
    final buf = StringBuffer();
    buf.writeln('# Workout - ${result.planId}');
    buf.writeln(
      '**Duration:** ${_formatDuration(result.duration)} - '
      '**Sets:** ${result.totalSets} - '
      '**Reps:** ${result.totalReps} - '
      '**Volume:** ${_formatVolume(result.totalVolume)} kg',
    );
    if (result.exercises.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Exercises');
      for (final ex in result.exercises) {
        final totalReps = ex.sets.fold<int>(0, (a, s) => a + s.actualReps);
        buf.writeln(
          '- ${ex.exerciseName} - ${ex.sets.length} sets, '
          '$totalReps reps total',
        );
        if (ex.sets.isNotEmpty) {
          buf.writeln('  - ${ex.sets.map(_formatSet).join(', ')}');
        }
      }
    }
    return buf.toString();
  }

  /// Multi-line Markdown report of a cardio session, one bullet per lap.
  static String toMarkdownCardio(CardioResult result) {
    final buf = StringBuffer();
    final title = result.planName.isEmpty ? result.planId : result.planName;
    buf.writeln('# Cardio - $title');
    final pace = result.avgPacePerKm;
    buf.writeln(
      '**Discipline:** ${_disciplineLabel(result.discipline)} - '
      '**Duration:** ${_formatDuration(result.duration)} - '
      '**Distance:** ${_formatDistance(result.totalDistanceMeters)} - '
      '**Laps:** ${result.totalLaps}'
      '${pace == null ? '' : ' - **Avg pace:** ${_formatDuration(pace)} /km'}',
    );
    if (result.laps.isNotEmpty) {
      buf.writeln();
      buf.writeln('## Laps');
      for (var i = 0; i < result.laps.length; i++) {
        buf.writeln('- Lap ${i + 1}: ${_formatLap(result.laps[i])}');
      }
    }
    return buf.toString();
  }

  static String _formatSet(PerformedSet set) {
    final reps = set.actualReps;
    final w = set.actualWeight;
    if (w == null) return '$reps reps';
    return '$reps x ${_formatVolume(w)} kg';
  }

  static String _formatLap(CardioLap lap) {
    final parts = <String>[_formatDuration(lap.duration)];
    if ((lap.distanceMeters ?? 0) > 0) {
      parts.add(_formatDistance(lap.distanceMeters!));
    }
    if (lap.avgPacePerKm != null) {
      parts.add('${_formatDuration(lap.avgPacePerKm!)} /km');
    }
    if (lap.avgHeartRate != null) parts.add('${lap.avgHeartRate} bpm');
    if (lap.rpe != null) parts.add('RPE ${lap.rpe}');
    return parts.join(' - ');
  }

  static String _formatDuration(Duration d) {
    final v = d.abs();
    final h = v.inHours;
    final m = v.inMinutes.remainder(60);
    final s = v.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$mm:$ss' : '$mm:$ss';
  }

  static String _formatVolume(double kg) {
    if (kg == kg.roundToDouble()) return kg.toStringAsFixed(0);
    return kg.toStringAsFixed(1);
  }

  static String _formatDistance(double meters) {
    if (meters <= 0) return '0 m';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(2)} km';
  }

  static String _disciplineLabel(CardioDiscipline d) {
    switch (d) {
      case CardioDiscipline.running:
        return 'Running';
      case CardioDiscipline.cycling:
        return 'Cycling';
      case CardioDiscipline.rowing:
        return 'Rowing';
      case CardioDiscipline.swimming:
        return 'Swimming';
      case CardioDiscipline.jumpRope:
        return 'Jump rope';
      case CardioDiscipline.walk:
        return 'Walk';
      case CardioDiscipline.mixed:
        return 'Mixed';
    }
  }
}
