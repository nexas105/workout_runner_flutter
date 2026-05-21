import 'package:fitness_workout/fitness_workout.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunnerActionResult.ok', () {
    test('has success true and null error/message', () {
      final result = RunnerActionResult.ok();
      expect(result.success, isTrue);
      expect(result.error, isNull);
      expect(result.message, isNull);
    });

    test('toString reflects ok state', () {
      expect(RunnerActionResult.ok().toString(), 'RunnerActionResult.ok()');
    });
  });

  group('RunnerActionResult.fail', () {
    test('populates error and uses default message when none provided', () {
      final result = RunnerActionResult.fail(RunnerActionError.noActivePlan);
      expect(result.success, isFalse);
      expect(result.error, RunnerActionError.noActivePlan);
      expect(
        result.message,
        RunnerErrorMessages.defaultMessage(RunnerActionError.noActivePlan),
      );
    });

    test('uses custom message when provided', () {
      final result = RunnerActionResult.fail(
        RunnerActionError.indexOutOfRange,
        'Custom hint.',
      );
      expect(result.success, isFalse);
      expect(result.error, RunnerActionError.indexOutOfRange);
      expect(result.message, 'Custom hint.');
    });

    test('provides a default message for every RunnerActionError value', () {
      for (final code in RunnerActionError.values) {
        final result = RunnerActionResult.fail(code);
        expect(result.error, code);
        expect(result.message, isNotNull);
        expect(result.message, isNotEmpty);
      }
    });
  });

  group('RunnerActionResult JSON', () {
    test('round-trips an ok result', () {
      final original = RunnerActionResult.ok();
      final encoded = jsonEncode(original.toJson());
      final decoded = RunnerActionResult.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.success, isTrue);
      expect(decoded.error, isNull);
      expect(decoded.message, isNull);
      expect(decoded, original);
    });

    test('round-trips a failure result preserving error.id and message', () {
      final original = RunnerActionResult.fail(
        RunnerActionError.performedSetLocked,
        'Locked.',
      );
      final json = original.toJson();
      expect(json['success'], isFalse);
      expect(json['error'], 'performedSetLocked');
      expect(json['message'], 'Locked.');

      final encoded = jsonEncode(json);
      final decoded = RunnerActionResult.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.success, isFalse);
      expect(decoded.error, RunnerActionError.performedSetLocked);
      expect(decoded.message, 'Locked.');
      expect(decoded, original);
    });

    test('decodes unknown error names as null error', () {
      final decoded = RunnerActionResult.fromJson(<String, dynamic>{
        'success': false,
        'error': 'somethingNew',
        'message': 'msg',
      });
      expect(decoded.success, isFalse);
      expect(decoded.error, isNull);
      expect(decoded.message, 'msg');
    });
  });

  group('RunnerActionResult equality', () {
    test('two ok results are equal and share hashCode', () {
      final a = RunnerActionResult.ok();
      final b = RunnerActionResult.ok();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('failures with same fields are equal', () {
      final a = RunnerActionResult.fail(
        RunnerActionError.invalidPlan,
        'Bad plan.',
      );
      final b = RunnerActionResult.fail(
        RunnerActionError.invalidPlan,
        'Bad plan.',
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different error codes are not equal', () {
      final a = RunnerActionResult.fail(RunnerActionError.invalidPlan);
      final b = RunnerActionResult.fail(RunnerActionError.storageFailed);
      expect(a, isNot(equals(b)));
    });

    test('different messages are not equal', () {
      final a = RunnerActionResult.fail(
        RunnerActionError.unknown,
        'message a',
      );
      final b = RunnerActionResult.fail(
        RunnerActionError.unknown,
        'message b',
      );
      expect(a, isNot(equals(b)));
    });

    test('ok and fail with same logical content are not equal', () {
      final ok = RunnerActionResult.ok();
      final fail = RunnerActionResult.fail(RunnerActionError.unknown);
      expect(ok, isNot(equals(fail)));
    });
  });
}