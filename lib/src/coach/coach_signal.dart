enum CoachSignal {
  setMissed,
  restSkipped,
  restExtended,
  prAchieved,
  deloadSuggested,
  longRest,
  fastPace,
  slowPace,
  hitTarget,
}

extension CoachSignalSerializer on CoachSignal {
  String get id => name;

  static CoachSignal? fromId(String? raw) {
    if (raw == null) return null;
    for (final s in CoachSignal.values) {
      if (s.name == raw) return s;
    }
    return null;
  }
}

final class CoachSignalEvent {
  final CoachSignal signal;
  final DateTime at;
  final Map<String, dynamic>? payload;

  const CoachSignalEvent({
    required this.signal,
    required this.at,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'signal': signal.id,
    'at': at.toIso8601String(),
    if (payload != null) 'payload': payload,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachSignalEvent &&
        other.signal == signal &&
        other.at == at;
  }

  @override
  int get hashCode => Object.hash(signal, at);
}
