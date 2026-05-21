import 'dart:async';

import 'coach_signal.dart';
import 'coaching_message.dart';

typedef CoachingMessageMapper = CoachingMessage? Function(CoachSignalEvent);

abstract class CoachEngine {
  Stream<CoachingMessage> get messages;

  void emitSignal(CoachSignalEvent event);
}

class DefaultCoachEngine extends CoachEngine {
  final CoachingMessageMapper? _mapper;
  final StreamController<CoachingMessage> _controller =
      StreamController<CoachingMessage>.broadcast();
  int _seq = 0;

  DefaultCoachEngine({CoachingMessageMapper? mapper}) : _mapper = mapper;

  @override
  Stream<CoachingMessage> get messages => _controller.stream;

  @override
  void emitSignal(CoachSignalEvent event) {
    if (_controller.isClosed) return;
    final CoachingMessage? message = _mapper != null
        ? _mapper(event)
        : defaultMessageFor(event, idSuffix: _seq);
    _seq++;
    if (message != null) {
      _controller.add(message);
    }
  }

  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }

  static CoachingMessage defaultMessageFor(
    CoachSignalEvent event, {
    int idSuffix = 0,
  }) {
    final tpl = defaultTemplates[event.signal]!;
    return CoachingMessage(
      id: '${event.signal.id}-${event.at.microsecondsSinceEpoch}-$idSuffix',
      severity: tpl.severity,
      title: tpl.title,
      body: tpl.body,
      at: event.at,
      source: tpl.source,
      meta: event.payload,
    );
  }

  static const Map<CoachSignal, CoachingMessageTemplate> defaultTemplates = {
    CoachSignal.setMissed: CoachingMessageTemplate(
      severity: CoachSeverity.warning,
      title: 'Missed the target',
      body: 'You fell short of the target reps. Adjust load or rest more.',
      source: 'runner',
    ),
    CoachSignal.restSkipped: CoachingMessageTemplate(
      severity: CoachSeverity.warning,
      title: 'Rest skipped',
      body: 'Skipping rest can hurt the next set. Take a breath if you need it.',
      source: 'rest',
    ),
    CoachSignal.restExtended: CoachingMessageTemplate(
      severity: CoachSeverity.info,
      title: 'Rest extended',
      body: 'Longer rest noted. Use the extra time to refocus.',
      source: 'rest',
    ),
    CoachSignal.prAchieved: CoachingMessageTemplate(
      severity: CoachSeverity.success,
      title: 'New PR!',
      body: 'You just set a new personal record.',
      source: 'overload',
    ),
    CoachSignal.deloadSuggested: CoachingMessageTemplate(
      severity: CoachSeverity.info,
      title: 'Deload suggested',
      body: 'Recent performance suggests a lighter session would help recovery.',
      source: 'readiness',
    ),
    CoachSignal.longRest: CoachingMessageTemplate(
      severity: CoachSeverity.info,
      title: 'Long rest detected',
      body: 'You\'ve been resting a while. Ready for the next set?',
      source: 'rest',
    ),
    CoachSignal.fastPace: CoachingMessageTemplate(
      severity: CoachSeverity.encouragement,
      title: 'Strong pace',
      body: 'You\'re moving quickly through this session. Keep it steady.',
      source: 'runner',
    ),
    CoachSignal.slowPace: CoachingMessageTemplate(
      severity: CoachSeverity.info,
      title: 'Slower pace',
      body: 'Take the time you need, but watch the clock if you\'re short on time.',
      source: 'runner',
    ),
    CoachSignal.hitTarget: CoachingMessageTemplate(
      severity: CoachSeverity.success,
      title: 'Target hit',
      body: 'Clean set right on target. Nice work.',
      source: 'runner',
    ),
  };
}

class CoachingMessageTemplate {
  final CoachSeverity severity;
  final String title;
  final String body;
  final String source;

  const CoachingMessageTemplate({
    required this.severity,
    required this.title,
    required this.body,
    required this.source,
  });
}
