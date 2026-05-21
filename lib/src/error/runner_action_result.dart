import 'error_messages.dart';

enum RunnerActionError {
  noActivePlan,
  indexOutOfRange,
  alreadyRunning,
  invalidPlan,
  performedSetLocked,
  idCollision,
  notRunning,
  storageFailed,
  unknown,
}

class RunnerActionResult {
  final bool success;
  final RunnerActionError? error;
  final String? message;

  const RunnerActionResult._({
    required this.success,
    this.error,
    this.message,
  });

  factory RunnerActionResult.ok() {
    return const RunnerActionResult._(success: true);
  }

  factory RunnerActionResult.fail(
    RunnerActionError error, [
    String? message,
  ]) {
    return RunnerActionResult._(
      success: false,
      error: error,
      message: message ?? RunnerErrorMessages.defaultMessage(error),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      if (error != null) 'error': error!.name,
      if (message != null) 'message': message,
    };
  }

  factory RunnerActionResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final rawError = json['error'];
    final rawMessage = json['message'];
    RunnerActionError? parsedError;
    if (rawError is String) {
      for (final candidate in RunnerActionError.values) {
        if (candidate.name == rawError) {
          parsedError = candidate;
          break;
        }
      }
    }
    return RunnerActionResult._(
      success: success,
      error: parsedError,
      message: rawMessage is String ? rawMessage : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RunnerActionResult &&
        other.success == success &&
        other.error == error &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(success, error, message);

  @override
  String toString() {
    if (success) return 'RunnerActionResult.ok()';
    return 'RunnerActionResult.fail(${error?.name}, $message)';
  }
}
