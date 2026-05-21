/// Persistence for user-defined catalogue entries — exercises, muscles,
/// categories, plans, cardio plans. Independent from [RunnerStorage] so the
/// implementation can pick a different backend (SQLite, IndexedDB, …) without
/// touching the runner.
///
/// Entries are stored as JSON maps so the registry stays type-agnostic.
/// `Catalog` (the merge helper) layers concrete decoders on top.
abstract class CustomEntityRegistry {
  Future<List<Map<String, dynamic>>> readAll(String kind);
  Future<void> put(String kind, Map<String, dynamic> json);
  Future<void> remove(String kind, String id);
  Future<void> clear(String kind);
  Future<void> clearAll();
}

/// Well-known `kind` ids used by `Catalog`. Storage adapters can support
/// arbitrary kinds — these are the ones the bundled merger understands.
abstract class CustomEntityKinds {
  CustomEntityKinds._();
  static const String exercises = 'exercises';
  static const String muscles = 'muscles';
  static const String categories = 'categories';
  static const String plans = 'plans';
  static const String cardioPlans = 'cardio_plans';
}
