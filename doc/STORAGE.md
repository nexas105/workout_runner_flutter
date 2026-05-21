# Storage

`WorkoutRunner` persists through a `RunnerStorage`. The package ships two
implementations, and you can write your own — the contract is small and
schema-free, so it maps cleanly onto SharedPreferences, Hive, SQLite,
Supabase, Firestore, an HTTP API, an encrypted wrapper, etc.

See [API.md](API.md#storage) for the interface signature and
[ARCHITECTURE.md](ARCHITECTURE.md#persistence-model) for *when* the runner
calls into storage.

---

## The contract

```dart
abstract class RunnerStorage {
  Future<void> saveState(Map<String, dynamic> json, {String slot = 'default'});
  Future<Map<String, dynamic>?> readState({String slot = 'default'});
  Future<void> clearState({String slot = 'default'});

  Future<void> savePlan(Map<String, dynamic> json, {String slot = 'default'});
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'});
  Future<void> clearPlan({String slot = 'default'});
}
```

Three rules:

1. **Round-trip JSON unchanged.** What the runner saves must come back from
   the matching read. The `Map<String, dynamic>` may contain nested maps,
   lists and primitive JSON types only.
2. **Two independent buckets per slot.** State and plan are written
   separately because plan mutations and state mutations happen at
   different points. Treat them as independent rows / keys / documents.
3. **Slot is a free string key.** Pass it through unchanged. The default
   value is `'default'`.

`read*` returns `null` for missing entries (do not throw). `clear*` is
idempotent.

---

## Slots

A slot identifies one independent runner. Common reasons to use multiple
slots:

- **Multi-user app.** One slot per signed-in user. The app does not have to
  clear storage when switching accounts.
- **Strength and cardio side-by-side.** The cardio controller in this
  package shares the `RunnerStorage` contract; pass it a different slot
  (e.g. `'cardio'`) so the strength and cardio runners do not collide.
- **Demo / sandbox mode.** Run a separate slot with an `InMemoryRunnerStorage`
  so demo workouts never touch real data.

```dart
final strength = WorkoutRunner(slot: 'strength');
final cardio   = CardioRunner(slot: 'cardio');
```

---

## `PrefsRunnerStorage` (default)

Backed by `SharedPreferences`. Keys are derived as:

| Bucket | Key                                |
| ------ | ---------------------------------- |
| state  | `workout_runner.state.{slot}`      |
| plan   | `workout_runner.plan.{slot}`       |

Both values are JSON-encoded strings (via `jsonEncode`). For
`slot: 'default'` the keys are `workout_runner.state.default` and
`workout_runner.plan.default`.

You do not need to initialise `SharedPreferences` explicitly — the storage
calls `SharedPreferences.getInstance()` on demand and awaits it.

---

## `InMemoryRunnerStorage`

A `Map`-backed implementation that lives for the process lifetime.
Convenient for:

- **Tests** that exercise the runner end-to-end without touching the
  platform channels.
- **`devicePreview` / widgetbook** snapshots where you do not want previous
  runs to bleed in.
- **Demo / kiosk mode**.

```dart
final runner = WorkoutRunner(storage: InMemoryRunnerStorage());
```

---

## Worked example: `SupabaseRunnerStorage`

Pseudo-code — replace `db` with your real Supabase client. The table
schema below has one row per `(user_id, slot, bucket)`:

```sql
create table runner_storage (
  user_id text not null,
  slot    text not null,
  bucket  text not null check (bucket in ('state', 'plan')),
  payload jsonb,
  primary key (user_id, slot, bucket)
);
```

```dart
import 'package:fitness_workout/fitness_workout.dart';

class SupabaseRunnerStorage implements RunnerStorage {
  SupabaseRunnerStorage({required this.userId, required this.db});

  final String userId;
  final dynamic db; // your Supabase client

  Future<void> _upsert(String slot, String bucket, Map<String, dynamic> json) {
    return db.from('runner_storage').upsert({
      'user_id': userId,
      'slot': slot,
      'bucket': bucket,
      'payload': json,
    });
  }

  Future<Map<String, dynamic>?> _read(String slot, String bucket) async {
    final row = await db.from('runner_storage')
        .select('payload')
        .eq('user_id', userId)
        .eq('slot', slot)
        .eq('bucket', bucket)
        .maybeSingle();
    return row?['payload'] as Map<String, dynamic>?;
  }

  Future<void> _delete(String slot, String bucket) {
    return db.from('runner_storage')
        .delete()
        .eq('user_id', userId)
        .eq('slot', slot)
        .eq('bucket', bucket);
  }

  @override
  Future<void> saveState(Map<String, dynamic> j, {String slot = 'default'}) =>
      _upsert(slot, 'state', j);
  @override
  Future<Map<String, dynamic>?> readState({String slot = 'default'}) =>
      _read(slot, 'state');
  @override
  Future<void> clearState({String slot = 'default'}) => _delete(slot, 'state');

  @override
  Future<void> savePlan(Map<String, dynamic> j, {String slot = 'default'}) =>
      _upsert(slot, 'plan', j);
  @override
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'}) =>
      _read(slot, 'plan');
  @override
  Future<void> clearPlan({String slot = 'default'}) => _delete(slot, 'plan');
}
```

Wire it up:

```dart
final runner = WorkoutRunner(
  storage: SupabaseRunnerStorage(userId: currentUserId, db: db),
  slot: currentUserId,
);

await runner.tryAutoResume();
```

Notes:

- The runner persists after **every mutation** — that includes per-second
  ticks? No, only the tick of *state* is not persisted (no method is
  called). State writes happen on starts, finishes, navigation,
  performed-set updates and plan mutations. Still, a heavy backend may
  prefer to debounce; you can do that inside your storage implementation
  with a `Timer` and a dirty flag.
- For multi-user use the user id as `slot` so the same backend can host
  several users and the local `RunnerScope` does not have to be
  re-created on sign-in.
- Storage errors must not throw out of the runner — `tryAutoResume()` will
  swallow them, but `saveState` / `savePlan` will propagate. If your
  backend can fail transiently, wrap your writes in a retry / queue.

---

## Worked example: `EncryptedRunnerStorage`

Composition pattern — wrap any `RunnerStorage` to encrypt the JSON before
it hits the inner store.

```dart
import 'dart:convert';
import 'package:fitness_workout/fitness_workout.dart';

class EncryptedRunnerStorage implements RunnerStorage {
  EncryptedRunnerStorage({required this.inner, required this.cipher});

  final RunnerStorage inner;
  final Cipher cipher; // your encrypt / decrypt boundary

  Map<String, dynamic> _wrap(Map<String, dynamic> json) =>
      {'enc': cipher.encrypt(jsonEncode(json))};

  Map<String, dynamic>? _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final blob = raw['enc'] as String?;
    if (blob == null) return null;
    return jsonDecode(cipher.decrypt(blob)) as Map<String, dynamic>;
  }

  @override
  Future<void> saveState(Map<String, dynamic> j, {String slot = 'default'}) =>
      inner.saveState(_wrap(j), slot: slot);
  @override
  Future<Map<String, dynamic>?> readState({String slot = 'default'}) async =>
      _unwrap(await inner.readState(slot: slot));
  @override
  Future<void> clearState({String slot = 'default'}) =>
      inner.clearState(slot: slot);

  @override
  Future<void> savePlan(Map<String, dynamic> j, {String slot = 'default'}) =>
      inner.savePlan(_wrap(j), slot: slot);
  @override
  Future<Map<String, dynamic>?> readPlan({String slot = 'default'}) async =>
      _unwrap(await inner.readPlan(slot: slot));
  @override
  Future<void> clearPlan({String slot = 'default'}) =>
      inner.clearPlan(slot: slot);
}

abstract class Cipher {
  String encrypt(String s);
  String decrypt(String s);
}
```

Use it:

```dart
final runner = WorkoutRunner(
  storage: EncryptedRunnerStorage(
    inner: PrefsRunnerStorage(),
    cipher: MyAesGcmCipher(key: secretKey),
  ),
);
```

The runner does not know — and does not need to know — that the bytes on
disk are ciphertext.
