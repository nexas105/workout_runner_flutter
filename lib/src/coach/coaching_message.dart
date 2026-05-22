enum CoachSeverity { info, success, warning, encouragement, alert }

extension CoachSeveritySerializer on CoachSeverity {
  String get id => name;

  static CoachSeverity fromId(String? raw) {
    if (raw == null) return CoachSeverity.info;
    return CoachSeverity.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => CoachSeverity.info,
    );
  }
}

final class CoachingAction {
  final String label;
  final String actionId;
  final Map<String, dynamic>? args;

  const CoachingAction({
    required this.label,
    required this.actionId,
    this.args,
  });

  CoachingAction copyWith({
    String? label,
    String? actionId,
    Map<String, dynamic>? args,
  }) {
    return CoachingAction(
      label: label ?? this.label,
      actionId: actionId ?? this.actionId,
      args: args ?? this.args,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'actionId': actionId,
    if (args != null) 'args': args,
  };

  static CoachingAction fromJson(Map<String, dynamic> json) {
    final rawArgs = json['args'];
    return CoachingAction(
      label: json['label'] as String,
      actionId: json['actionId'] as String,
      args: rawArgs == null ? null : Map<String, dynamic>.from(rawArgs as Map),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachingAction &&
        other.label == label &&
        other.actionId == actionId &&
        _mapEquals(other.args, args);
  }

  @override
  int get hashCode => Object.hash(label, actionId, args?.length ?? 0);
}

final class CoachingMessage {
  final String id;
  final CoachSeverity severity;
  final String title;
  final String body;
  final CoachingAction? action;
  final DateTime at;
  final String? source;
  final Map<String, dynamic>? meta;

  const CoachingMessage({
    required this.id,
    required this.severity,
    required this.title,
    required this.body,
    required this.at,
    this.action,
    this.source,
    this.meta,
  });

  CoachingMessage copyWith({
    String? id,
    CoachSeverity? severity,
    String? title,
    String? body,
    CoachingAction? action,
    DateTime? at,
    String? source,
    Map<String, dynamic>? meta,
  }) {
    return CoachingMessage(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      body: body ?? this.body,
      action: action ?? this.action,
      at: at ?? this.at,
      source: source ?? this.source,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'severity': severity.id,
    'title': title,
    'body': body,
    if (action != null) 'action': action!.toJson(),
    'at': at.toIso8601String(),
    if (source != null) 'source': source,
    if (meta != null) 'meta': meta,
  };

  static CoachingMessage fromJson(Map<String, dynamic> json) {
    final rawAction = json['action'];
    final rawMeta = json['meta'];
    return CoachingMessage(
      id: json['id'] as String,
      severity: CoachSeveritySerializer.fromId(json['severity'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      action:
          rawAction == null
              ? null
              : CoachingAction.fromJson(
                Map<String, dynamic>.from(rawAction as Map),
              ),
      at: DateTime.parse(json['at'] as String),
      source: json['source'] as String?,
      meta: rawMeta == null ? null : Map<String, dynamic>.from(rawMeta as Map),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoachingMessage &&
        other.id == id &&
        other.severity == severity &&
        other.title == title &&
        other.body == body &&
        other.action == action &&
        other.at == at &&
        other.source == source &&
        _mapEquals(other.meta, meta);
  }

  @override
  int get hashCode =>
      Object.hash(id, severity, title, body, action, at, source);
}

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key)) return false;
    if (a[key] != b[key]) return false;
  }
  return true;
}
