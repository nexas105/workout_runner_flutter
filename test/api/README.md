# Public API Snapshot

`public_api_snapshot_test.dart` walks `lib/fitness_workout.dart`, follows
every `export 'src/...';` line, and grep-extracts public top-level symbol
names from each exported file. The sorted list is compared against
`public_api_snapshot.golden`. Any add / remove / rename trips a failing
test so the change has to be acknowledged before release.

## When the test fails

You changed the public surface (renamed a class, deleted an enum, added a
new export, etc.). That's fine — but it needs a paper trail.

1. Read the failure message. It lists `+ added` and `- removed` symbols.
2. If the change is intentional, regenerate the golden:

   ```bash
   rm test/api/public_api_snapshot.golden
   touch test/api/public_api_snapshot.golden
   flutter test test/api/public_api_snapshot_test.dart
   ```

   The first run rewrites the golden and fails on purpose with
   `Initial snapshot written; commit the golden file.`.

3. Inspect the new file (`git diff test/api/public_api_snapshot.golden`)
   and make sure only the symbols you meant to change appear.
4. `git add test/api/public_api_snapshot.golden` and commit it together
   with the API change.
5. Rerun the test — it should now pass.

If the change was **not** intentional, fix the source instead of
regenerating the golden.

## What gets snapshotted

Symbols collected (only public — names starting with `_` are skipped):

- `class Foo` (incl. `abstract`, `sealed`, `base`, `final`, `interface`,
  `mixin class` modifiers)
- `enum Foo`
- `mixin Foo`
- `extension FooX on Bar`
- `typedef Foo = ...`
- top-level `const`/`final` variables (`const int kPluginSchemaVersion = 1;`)

Only the **name** is snapshotted, not the signature. A signature change
(e.g. constructor parameters, generic bounds, return type) will **not**
trip this test. Pair it with focused unit tests when you need contract
guarantees.

## Limitations

- Deferred imports, `part` / `part of` and conditional exports are not
  followed.
- `export ... show X, Y` is honored; `export ... hide ...` is ignored
  (would need to know the unfiltered set first).
- Anonymous extensions (`extension on Foo`) are skipped — they have no
  exportable identifier.
- Top-level functions and getters are intentionally **not** captured —
  the regex shapes for those are noisy and produce too many false
  positives. If we ever publish a free-floating top-level function we
  want to lock down, prefer wrapping it on a class or extension.
- Parser is regex-based, not the `analyzer` package — keeps the test
  free of dependencies but assumes idiomatic formatting (declaration at
  start of line, no exotic macros).

## First-time setup

The repo ships an **empty** `public_api_snapshot.golden`. The first time
the test runs it populates the file with the current API and fails with
an "Initial snapshot written" message. Commit the golden, rerun — green.
