import 'package:fitness_workout/fitness_workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StrengthTemplates', () {
    test('every template plan validates', () {
      for (final plan in StrengthTemplates.all) {
        final result = plan.validate();
        expect(
          result.isValid,
          isTrue,
          reason:
              '${plan.id} should validate but produced errors: '
              '${result.errors.map((e) => '${e.code}:${e.message}').join(', ')}',
        );
      }
    });

    test('plan ids are unique within the catalogue', () {
      final ids = StrengthTemplates.all.map((p) => p.id).toList();
      final unique = ids.toSet();
      expect(
        unique.length,
        ids.length,
        reason: 'Duplicate plan id in StrengthTemplates.all: $ids',
      );
    });

    test('all template ids carry the tmpl_ prefix', () {
      for (final plan in StrengthTemplates.all) {
        expect(
          plan.id.startsWith('tmpl_'),
          isTrue,
          reason: 'Plan id "${plan.id}" must start with "tmpl_".',
        );
      }
    });

    test('every template plan has at least three exercises', () {
      for (final plan in StrengthTemplates.all) {
        expect(
          plan.exercises.length,
          greaterThanOrEqualTo(3),
          reason:
              '${plan.id} should have >= 3 exercises, '
              'got ${plan.exercises.length}.',
        );
      }
    });

    test('fiveByFive emits five working sets at five reps per exercise', () {
      final plan = StrengthTemplates.fiveByFive;
      expect(plan.exercises, isNotEmpty);
      for (final exercise in plan.exercises) {
        final workingSets = exercise.sets
            .where((s) => s.type == SetType.working)
            .toList();
        expect(
          workingSets.length,
          5,
          reason:
              '5x5 exercise "${exercise.name}" should have 5 working sets, '
              'got ${workingSets.length}.',
        );
        for (final set in workingSets) {
          expect(
            set.targetReps,
            5,
            reason:
                '5x5 exercise "${exercise.name}" working set should target '
                '5 reps, got ${set.targetReps}.',
          );
        }
      }
    });

    test('catalogue exposes the documented template plans', () {
      expect(StrengthTemplates.all, hasLength(7));
      expect(StrengthTemplates.fullBodyBeginner.id, 'tmpl_full_body_beginner');
      expect(StrengthTemplates.pushDay.id, 'tmpl_push_day');
      expect(StrengthTemplates.pullDay.id, 'tmpl_pull_day');
      expect(StrengthTemplates.legDay.id, 'tmpl_leg_day');
      expect(StrengthTemplates.upperA.id, 'tmpl_upper_a');
      expect(StrengthTemplates.lowerA.id, 'tmpl_lower_a');
      expect(StrengthTemplates.fiveByFive.id, 'tmpl_five_by_five');
    });
  });
}
