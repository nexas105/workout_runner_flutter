import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutExercise _ex({Map<String, dynamic>? meta}) =>
    WorkoutExercise(id: 'ex1', name: 'Squat', meta: meta);

void main() {
  group('FormCues.read', () {
    test('returns empty bundle when meta is null', () {
      final bundle = FormCues.read(_ex());
      expect(bundle.isEmpty, isTrue);
      expect(bundle.cues, isEmpty);
      expect(bundle.commonMistakes, isEmpty);
      expect(bundle.setupInstructions, isEmpty);
    });

    test('returns empty bundle when formCues key is missing', () {
      final bundle = FormCues.read(_ex(meta: {'note': 'hi'}));
      expect(bundle.isEmpty, isTrue);
    });

    test('returns empty bundle when formCues is not a Map', () {
      expect(FormCues.read(_ex(meta: {'formCues': 'oops'})).isEmpty, isTrue);
      expect(FormCues.read(_ex(meta: {'formCues': 42})).isEmpty, isTrue);
      expect(FormCues.read(_ex(meta: {'formCues': []})).isEmpty, isTrue);
    });

    test('tolerates non-list fields', () {
      final bundle = FormCues.read(
        _ex(
          meta: {
            'formCues': {
              'cues': 'knees out',
              'commonMistakes': 7,
              'setupInstructions': null,
            },
          },
        ),
      );
      expect(bundle.isEmpty, isTrue);
    });

    test('skips non-string and empty entries inside lists', () {
      final bundle = FormCues.read(
        _ex(
          meta: {
            'formCues': {
              'cues': ['Knees track over toes', 7, null, '', '  brace  '],
              'commonMistakes': ['Heels lift', false],
              'setupInstructions': [42, 'Feet shoulder-width'],
            },
          },
        ),
      );
      expect(bundle.cues, ['Knees track over toes', 'brace']);
      expect(bundle.commonMistakes, ['Heels lift']);
      expect(bundle.setupInstructions, ['Feet shoulder-width']);
    });
  });

  group('FormCues.write', () {
    test('round-trips through read', () {
      const original = FormCueBundle(
        cues: ['Knees track over toes', 'Brace core'],
        commonMistakes: ['Heels lift'],
        setupInstructions: ['Feet shoulder-width'],
      );
      final ex = FormCues.write(_ex(), original);
      final loaded = FormCues.read(ex);
      expect(loaded.cues, original.cues);
      expect(loaded.commonMistakes, original.commonMistakes);
      expect(loaded.setupInstructions, original.setupInstructions);
      expect(loaded, original);
    });

    test('preserves other meta entries', () {
      final ex = _ex(
        meta: {
          'note': 'hello',
          'tags': const ['gym'],
        },
      );
      final written = FormCues.write(ex, const FormCueBundle(cues: ['Brace']));
      expect(written.meta!['note'], 'hello');
      expect(written.meta!['tags'], const ['gym']);
      expect((written.meta!['formCues'] as Map)['cues'], ['Brace']);
    });

    test('empty bundle removes the formCues key', () {
      final seeded = FormCues.write(
        _ex(),
        const FormCueBundle(cues: ['Brace']),
      );
      expect(seeded.meta, contains('formCues'));
      final cleared = FormCues.write(seeded, FormCueBundle.empty);
      expect(cleared.meta, isNot(contains('formCues')));
    });

    test('empty bundle keeps untouched meta entries', () {
      final ex = _ex(
        meta: {
          'note': 'hi',
          'formCues': {
            'cues': ['x'],
          },
        },
      );
      final cleared = FormCues.write(ex, FormCueBundle.empty);
      expect(cleared.meta!.containsKey('formCues'), isFalse);
      expect(cleared.meta!['note'], 'hi');
    });
  });

  group('FormCues.merge', () {
    test('dedups while preserving order', () {
      const a = FormCueBundle(
        cues: ['Brace', 'Knees out'],
        commonMistakes: ['Heels lift'],
        setupInstructions: ['Feet shoulder-width'],
      );
      const b = FormCueBundle(
        cues: ['Knees out', 'Chest up'],
        commonMistakes: ['Heels lift', 'Rounded back'],
        setupInstructions: ['Bar mid-foot'],
      );
      final merged = FormCues.merge(a, b);
      expect(merged.cues, ['Brace', 'Knees out', 'Chest up']);
      expect(merged.commonMistakes, ['Heels lift', 'Rounded back']);
      expect(merged.setupInstructions, ['Feet shoulder-width', 'Bar mid-foot']);
    });

    test('merging with empty returns the non-empty side intact', () {
      const a = FormCueBundle(cues: ['Brace']);
      final merged = FormCues.merge(a, FormCueBundle.empty);
      expect(merged.cues, ['Brace']);
      expect(merged.isNotEmpty, isTrue);
    });
  });

  group('FormCueBundle JSON', () {
    test('toJson/fromJson round-trips', () {
      const bundle = FormCueBundle(
        cues: ['Brace'],
        commonMistakes: ['Heels lift'],
        setupInstructions: ['Bar mid-foot'],
      );
      final restored = FormCueBundle.fromJson(bundle.toJson());
      expect(restored, bundle);
    });
  });
}
