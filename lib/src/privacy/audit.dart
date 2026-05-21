class ExportAuditEntry {
  final String id;
  final String kind;
  final String? target;
  final int itemCount;
  final DateTime at;
  final Map<String, dynamic>? meta;

  const ExportAuditEntry({
    required this.id,
    required this.kind,
    required this.itemCount,
    required this.at,
    this.target,
    this.meta,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    if (target != null) 'target': target,
    'itemCount': itemCount,
    'at': at.toIso8601String(),
    if (meta != null) 'meta': meta,
  };

  factory ExportAuditEntry.fromJson(Map<String, dynamic> json) {
    final rawAt = json['at'];
    final at = rawAt is String
        ? (DateTime.tryParse(rawAt) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final rawCount = json['itemCount'];
    final itemCount = rawCount is num ? rawCount.toInt() : 0;
    final rawMeta = json['meta'];
    Map<String, dynamic>? meta;
    if (rawMeta is Map) {
      meta = rawMeta.cast<String, dynamic>();
    }
    return ExportAuditEntry(
      id: json['id'] is String ? json['id'] as String : '',
      kind: json['kind'] is String ? json['kind'] as String : '',
      target: json['target'] is String ? json['target'] as String : null,
      itemCount: itemCount,
      at: at,
      meta: meta,
    );
  }
}

abstract class ExportAuditSink {
  const ExportAuditSink();

  Future<void> record(ExportAuditEntry entry) async {}

  Future<List<ExportAuditEntry>> recent({int? limit, DateTime? since}) async =>
      const [];
}

class InMemoryExportAuditSink implements ExportAuditSink {
  final List<ExportAuditEntry> _entries = [];

  InMemoryExportAuditSink();

  @override
  Future<void> record(ExportAuditEntry entry) async {
    _entries.add(entry);
  }

  @override
  Future<List<ExportAuditEntry>> recent({int? limit, DateTime? since}) async {
    final sorted = List<ExportAuditEntry>.from(_entries)
      ..sort((a, b) => b.at.compareTo(a.at));
    Iterable<ExportAuditEntry> filtered = sorted;
    if (since != null) {
      filtered = filtered.where((e) => e.at.isAfter(since));
    }
    if (limit != null && limit >= 0) {
      filtered = filtered.take(limit);
    }
    return List.unmodifiable(filtered);
  }
}
