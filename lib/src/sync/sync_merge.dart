import 'sync_envelope.dart';

enum SyncMergeStrategy { lastWriteWins, sourcePriority, manual }

class SyncConflict<T> {
  const SyncConflict({
    required this.local,
    required this.remote,
    required this.reason,
  });

  final SyncEnvelope<T> local;
  final SyncEnvelope<T> remote;
  final String reason;
}

class SyncMergeResult<T> {
  const SyncMergeResult({
    required this.resolved,
    required this.conflicts,
  });

  final List<SyncEnvelope<T>> resolved;
  final List<SyncConflict<T>> conflicts;
}

abstract class SyncMerge {
  static SyncEnvelope<T> resolve<T>(
    SyncEnvelope<T> local,
    SyncEnvelope<T> remote, {
    SyncMergeStrategy strategy = SyncMergeStrategy.lastWriteWins,
    List<String>? sourcePriority,
  }) {
    switch (strategy) {
      case SyncMergeStrategy.lastWriteWins:
        return _lastWriteWins(local, remote);
      case SyncMergeStrategy.sourcePriority:
        return _sourcePriority(local, remote, sourcePriority);
      case SyncMergeStrategy.manual:
        throw StateError(
          'SyncMergeStrategy.manual requires the caller to resolve the '
          'conflict between local (${local.id}) and remote (${remote.id}).',
        );
    }
  }

  static SyncMergeResult<T> resolveBatch<T>(
    List<SyncEnvelope<T>> local,
    List<SyncEnvelope<T>> remote, {
    SyncMergeStrategy strategy = SyncMergeStrategy.lastWriteWins,
    List<String>? sourcePriority,
  }) {
    final localById = <String, SyncEnvelope<T>>{
      for (final e in local) e.id: e,
    };
    final remoteById = <String, SyncEnvelope<T>>{
      for (final e in remote) e.id: e,
    };

    final ids = <String>{...localById.keys, ...remoteById.keys};
    final resolved = <SyncEnvelope<T>>[];
    final conflicts = <SyncConflict<T>>[];

    for (final id in ids) {
      final l = localById[id];
      final r = remoteById[id];
      if (l == null && r != null) {
        resolved.add(r);
        continue;
      }
      if (r == null && l != null) {
        resolved.add(l);
        continue;
      }
      if (l == null || r == null) continue;

      if (strategy == SyncMergeStrategy.manual) {
        conflicts.add(SyncConflict<T>(
          local: l,
          remote: r,
          reason: 'manual strategy: caller must resolve',
        ));
        continue;
      }

      resolved.add(resolve<T>(
        l,
        r,
        strategy: strategy,
        sourcePriority: sourcePriority,
      ));
    }

    return SyncMergeResult<T>(resolved: resolved, conflicts: conflicts);
  }

  static SyncEnvelope<T> _lastWriteWins<T>(
    SyncEnvelope<T> a,
    SyncEnvelope<T> b,
  ) {
    final cmp = a.updatedAt.compareTo(b.updatedAt);
    if (cmp > 0) return a;
    if (cmp < 0) return b;
    final aDel = a.operation == SyncOperation.delete;
    final bDel = b.operation == SyncOperation.delete;
    if (aDel && !bDel) return a;
    if (bDel && !aDel) return b;
    return b;
  }

  static SyncEnvelope<T> _sourcePriority<T>(
    SyncEnvelope<T> a,
    SyncEnvelope<T> b,
    List<String>? priority,
  ) {
    if (priority == null || priority.isEmpty) {
      return _lastWriteWins(a, b);
    }
    final ai = priority.indexOf(a.source);
    final bi = priority.indexOf(b.source);
    if (ai == -1 && bi == -1) return _lastWriteWins(a, b);
    if (ai == -1) return b;
    if (bi == -1) return a;
    if (ai == bi) return _lastWriteWins(a, b);
    return ai < bi ? a : b;
  }
}
