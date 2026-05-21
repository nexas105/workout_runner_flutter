enum SyncOperation { create, update, delete }

class SyncEnvelope<T> {
  const SyncEnvelope({
    required this.id,
    required this.operation,
    required this.updatedAt,
    required this.source,
    required this.schemaVersion,
    this.deletedAt,
    this.payload,
  });

  final String id;
  final SyncOperation operation;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String source;
  final int schemaVersion;
  final T? payload;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) payloadToJson) {
    return <String, dynamic>{
      'id': id,
      'operation': operation.name,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (deletedAt != null) 'deletedAt': deletedAt!.toUtc().toIso8601String(),
      'source': source,
      'schemaVersion': schemaVersion,
      if (payload != null) 'payload': payloadToJson(payload as T),
    };
  }

  static SyncEnvelope<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) payloadFromJson,
  ) {
    final opRaw = json['operation'];
    final operation = SyncOperation.values.firstWhere(
      (e) => e.name == opRaw,
      orElse: () => SyncOperation.update,
    );
    final updatedAt = DateTime.parse(json['updatedAt'] as String);
    final deletedAtRaw = json['deletedAt'];
    final deletedAt = deletedAtRaw is String ? DateTime.parse(deletedAtRaw) : null;
    final payloadRaw = json['payload'];
    final payload = payloadRaw is Map<String, dynamic>
        ? payloadFromJson(payloadRaw)
        : null;
    return SyncEnvelope<T>(
      id: json['id'] as String,
      operation: operation,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      source: json['source'] as String,
      schemaVersion: (json['schemaVersion'] as num).toInt(),
      payload: payload,
    );
  }
}
