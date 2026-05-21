import '../models/workout_result.dart';
import 'workout_notes.dart';

class NotesTimelineEntry {
  final String label;
  final String note;
  final DateTime? at;

  const NotesTimelineEntry({required this.label, required this.note, this.at});
}

abstract class NotesTimeline {
  static List<NotesTimelineEntry> buildFor(
    WorkoutResult result, {
    Map<String, String>? setNotes,
  }) {
    final out = <NotesTimelineEntry>[];
    if (result.exercises.isEmpty) return out;

    for (var i = 0; i < result.exercises.length; i++) {
      final ex = result.exercises[i];

      final dyn = ex as dynamic;
      String? exerciseNote;
      try {
        final meta = dyn.meta;
        if (meta is Map) {
          final raw = meta['note'];
          if (raw is String) exerciseNote = raw;
        }
      } catch (_) {}

      DateTime? firstAt;
      if (ex.sets.isNotEmpty) firstAt = ex.sets.first.completedAt;
      if (exerciseNote != null) {
        out.add(
          NotesTimelineEntry(
            label: ex.exerciseName,
            note: exerciseNote,
            at: firstAt,
          ),
        );
      }

      for (var j = 0; j < ex.sets.length; j++) {
        final s = ex.sets[j];
        final key = WorkoutNotes.setNoteKey(i, j);
        final note = setNotes?[key];
        if (note == null) continue;
        out.add(
          NotesTimelineEntry(
            label: '${ex.exerciseName} · Set ${j + 1}',
            note: note,
            at: s.completedAt,
          ),
        );
      }
    }

    out.sort((a, b) {
      final aAt = a.at;
      final bAt = b.at;
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return aAt.compareTo(bAt);
    });

    return out;
  }
}
