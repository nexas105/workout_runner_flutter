enum ConsentScope { healthExport, backendSync, analytics, crashReports }

class ConsentState {
  final Map<ConsentScope, bool> granted;
  final DateTime? lastUpdated;

  const ConsentState({this.granted = const {}, this.lastUpdated});

  bool isGranted(ConsentScope scope) => granted[scope] ?? false;

  ConsentState grant(ConsentScope scope, {DateTime? at}) =>
      _setScope(scope, true, at);

  ConsentState revoke(ConsentScope scope, {DateTime? at}) =>
      _setScope(scope, false, at);

  ConsentState _setScope(ConsentScope scope, bool value, DateTime? at) {
    final next = Map<ConsentScope, bool>.from(granted);
    next[scope] = value;
    return ConsentState(
      granted: Map.unmodifiable(next),
      lastUpdated: at ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'granted': {
      for (final entry in granted.entries) entry.key.name: entry.value,
    },
    if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
  };

  factory ConsentState.fromJson(Map<String, dynamic> json) {
    final rawGranted = json['granted'];
    final parsed = <ConsentScope, bool>{};
    if (rawGranted is Map) {
      for (final entry in rawGranted.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! bool) continue;
        final scope = _scopeFromName(key);
        if (scope == null) continue;
        parsed[scope] = value;
      }
    }
    final rawUpdated = json['lastUpdated'];
    DateTime? lastUpdated;
    if (rawUpdated is String) {
      lastUpdated = DateTime.tryParse(rawUpdated);
    }
    return ConsentState(
      granted: Map.unmodifiable(parsed),
      lastUpdated: lastUpdated,
    );
  }

  static ConsentScope? _scopeFromName(String name) {
    for (final scope in ConsentScope.values) {
      if (scope.name == name) return scope;
    }
    return null;
  }
}

abstract class ConsentGate {
  const ConsentGate();

  Future<bool> requireConsent(ConsentScope scope, ConsentState current) async =>
      current.isGranted(scope);
}
