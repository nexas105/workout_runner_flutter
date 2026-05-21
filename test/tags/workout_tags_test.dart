import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutTags.read', () {
    test('returns empty list when meta is null', () {
      expect(WorkoutTags.read(null), isEmpty);
    });

    test('returns empty list when meta has no tags key', () {
      expect(WorkoutTags.read({'foo': 'bar'}), isEmpty);
    });

    test('returns empty list when tags is not a List', () {
      expect(WorkoutTags.read({'tags': 'strength'}), isEmpty);
      expect(WorkoutTags.read({'tags': 42}), isEmpty);
      expect(WorkoutTags.read({'tags': {'a': 1}}), isEmpty);
    });

    test('normalizes case, whitespace, and duplicates', () {
      final out = WorkoutTags.read({
        'tags': ['Strength', 'STRENGTH', ' strength '],
      });
      expect(out, ['strength']);
    });

    test('skips non-string entries without throwing', () {
      final out = WorkoutTags.read({
        'tags': ['gym', 7, null, 'home', true, 'gym'],
      });
      expect(out, ['gym', 'home']);
    });

    test('skips empty strings after trim', () {
      final out = WorkoutTags.read({
        'tags': ['  ', '', 'rehab'],
      });
      expect(out, ['rehab']);
    });

    test('preserves insertion order of first occurrence', () {
      final out = WorkoutTags.read({
        'tags': ['gym', 'home', 'gym', 'cardio'],
      });
      expect(out, ['gym', 'home', 'cardio']);
    });
  });

  group('WorkoutTags.write', () {
    test('returns a new map and does not mutate the input', () {
      final input = <String, dynamic>{'other': 'keep'};
      final out = WorkoutTags.write(input, ['Gym', 'gym ', 'home']);
      expect(out, {'other': 'keep', 'tags': ['gym', 'home']});
      expect(input.containsKey('tags'), isFalse);
      expect(identical(input, out), isFalse);
    });

    test('accepts null meta', () {
      final out = WorkoutTags.write(null, ['strength']);
      expect(out, {'tags': ['strength']});
    });

    test('overwrites existing tags', () {
      final out = WorkoutTags.write({'tags': ['old']}, ['new', 'new']);
      expect(out['tags'], ['new']);
    });
  });

  group('WorkoutTags.add', () {
    test('appends a tag without mutating input', () {
      final input = <String, dynamic>{
        'tags': ['gym'],
      };
      final out = WorkoutTags.add(input, 'Home');
      expect(out['tags'], ['gym', 'home']);
      expect(input['tags'], ['gym']);
    });

    test('is idempotent for duplicate tags', () {
      final out = WorkoutTags.add({'tags': ['gym']}, 'GYM');
      expect(out['tags'], ['gym']);
    });
  });

  group('WorkoutTags.remove', () {
    test('removes the tag without mutating input', () {
      final input = <String, dynamic>{
        'tags': ['gym', 'home'],
      };
      final out = WorkoutTags.remove(input, 'GYM');
      expect(out['tags'], ['home']);
      expect(input['tags'], ['gym', 'home']);
    });

    test('is a no-op when tag is absent', () {
      final out = WorkoutTags.remove({'tags': ['gym']}, 'rehab');
      expect(out['tags'], ['gym']);
    });
  });

  group('WorkoutTags.has', () {
    test('matches case-insensitively', () {
      final meta = {'tags': ['Strength']};
      expect(WorkoutTags.has(meta, 'strength'), isTrue);
      expect(WorkoutTags.has(meta, 'STRENGTH'), isTrue);
      expect(WorkoutTags.has(meta, 'cardio'), isFalse);
    });

    test('returns false for null meta and empty tag', () {
      expect(WorkoutTags.has(null, 'strength'), isFalse);
      expect(WorkoutTags.has({'tags': ['strength']}, '  '), isFalse);
    });
  });

  group('KnownTag constants', () {
    test('expose the expected literal values', () {
      expect(KnownTag.strength, 'strength');
      expect(KnownTag.hypertrophy, 'hypertrophy');
      expect(KnownTag.rehab, 'rehab');
      expect(KnownTag.home, 'home');
      expect(KnownTag.gym, 'gym');
      expect(KnownTag.deload, 'deload');
      expect(KnownTag.cardio, 'cardio');
      expect(KnownTag.hiit, 'hiit');
      expect(KnownTag.liss, 'liss');
      expect(KnownTag.morning, 'morning');
      expect(KnownTag.evening, 'evening');
    });
  });
}