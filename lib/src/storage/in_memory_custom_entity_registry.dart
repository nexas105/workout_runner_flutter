import 'custom_entity_registry.dart';

/// In-memory [CustomEntityRegistry] for tests, demos and prototypes. Not
/// persisted across app launches — wire a real registry (Hive, Isar, …) for
/// production.
class InMemoryCustomEntityRegistry implements CustomEntityRegistry {
  final Map<String, Map<String, Map<String, dynamic>>> _byKind = {};

  @override
  Future<List<Map<String, dynamic>>> readAll(String kind) async {
    final entries = _byKind[kind];
    if (entries == null) return const [];
    return entries.values
        .map((m) => Map<String, dynamic>.from(m))
        .toList(growable: false);
  }

  @override
  Future<void> put(String kind, Map<String, dynamic> json) async {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw ArgumentError('CustomEntityRegistry entries need a non-empty id.');
    }
    final bucket = _byKind.putIfAbsent(kind, () => {});
    bucket[id] = Map<String, dynamic>.from(json);
  }

  @override
  Future<void> remove(String kind, String id) async {
    _byKind[kind]?.remove(id);
  }

  @override
  Future<void> clear(String kind) async {
    _byKind.remove(kind);
  }

  @override
  Future<void> clearAll() async {
    _byKind.clear();
  }
}
