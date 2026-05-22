import '../models/workout_exercise.dart';

class FormCueBundle {
  final List<String> cues;
  final List<String> commonMistakes;
  final List<String> setupInstructions;

  const FormCueBundle({
    this.cues = const [],
    this.commonMistakes = const [],
    this.setupInstructions = const [],
  });

  static const FormCueBundle empty = FormCueBundle();

  bool get isEmpty =>
      cues.isEmpty && commonMistakes.isEmpty && setupInstructions.isEmpty;

  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() => {
    'cues': List<String>.unmodifiable(cues),
    'commonMistakes': List<String>.unmodifiable(commonMistakes),
    'setupInstructions': List<String>.unmodifiable(setupInstructions),
  };

  factory FormCueBundle.fromJson(Map<String, dynamic> json) => FormCueBundle(
    cues: _readStringList(json['cues']),
    commonMistakes: _readStringList(json['commonMistakes']),
    setupInstructions: _readStringList(json['setupInstructions']),
  );

  static List<String> _readStringList(Object? raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final entry in raw) {
      if (entry is! String) continue;
      final trimmed = entry.trim();
      if (trimmed.isEmpty) continue;
      out.add(trimmed);
    }
    return List<String>.unmodifiable(out);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FormCueBundle) return false;
    return _listEq(cues, other.cues) &&
        _listEq(commonMistakes, other.commonMistakes) &&
        _listEq(setupInstructions, other.setupInstructions);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(cues),
    Object.hashAll(commonMistakes),
    Object.hashAll(setupInstructions),
  );

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract class FormCues {
  static const String _key = 'formCues';

  static FormCueBundle read(WorkoutExercise ex) {
    final meta = ex.meta;
    if (meta == null) return FormCueBundle.empty;
    final raw = meta[_key];
    if (raw is! Map) return FormCueBundle.empty;
    return FormCueBundle.fromJson(raw.cast<String, dynamic>());
  }

  static WorkoutExercise write(WorkoutExercise ex, FormCueBundle bundle) {
    final next = <String, dynamic>{...?ex.meta};
    if (bundle.isEmpty) {
      next.remove(_key);
    } else {
      next[_key] = bundle.toJson();
    }
    return ex.copyWith(meta: next.isEmpty ? <String, dynamic>{} : next);
  }

  static FormCueBundle merge(FormCueBundle a, FormCueBundle b) => FormCueBundle(
    cues: _concatDedup(a.cues, b.cues),
    commonMistakes: _concatDedup(a.commonMistakes, b.commonMistakes),
    setupInstructions: _concatDedup(a.setupInstructions, b.setupInstructions),
  );

  static List<String> _concatDedup(List<String> a, List<String> b) {
    final seen = <String>{};
    final out = <String>[];
    for (final entry in a) {
      if (seen.add(entry)) out.add(entry);
    }
    for (final entry in b) {
      if (seen.add(entry)) out.add(entry);
    }
    return List<String>.unmodifiable(out);
  }
}
