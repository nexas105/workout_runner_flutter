// Public API snapshot test — Phase 7.3.
//
// Walks `lib/fitness_workout.dart`, follows every `export 'src/...';` line,
// and grep-extracts public top-level declarations (classes, enums, mixins,
// extensions, typedefs, top-level functions, and top-level `final`/`const`
// variables) via simple regexes.
//
// The current symbol list is compared against the checked-in golden file
// `test/api/public_api_snapshot.golden`. Any added, removed or renamed
// public symbol forces the developer to:
//
//   1. Run this test once. It will rewrite the golden file with the new set.
//   2. Eyeball the diff this test prints in the failure message.
//   3. `git add test/api/public_api_snapshot.golden` and commit.
//
// On first run (empty golden) the test populates the golden and `fail()`s on
// purpose so devs notice and commit it. The second run on the same tree must
// be green.
//
// Limitations (also called out in `test/api/README.md`):
//   * Deferred imports, parts and conditional exports are not followed.
//   * `export ... show/hide` clauses are honored only for `show` (rare in
//     this package).
//   * Anonymous extensions are skipped — they have no exportable name.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Library root we snapshot.
const _libraryRelative = 'lib/fitness_workout.dart';

/// Golden file we compare against.
const _goldenRelative = 'test/api/public_api_snapshot.golden';

void main() {
  test('public API snapshot matches the checked-in golden', () {
    final cwd = Directory.current.path;
    final libraryFile = File('$cwd/$_libraryRelative');
    final goldenFile = File('$cwd/$_goldenRelative');

    if (!libraryFile.existsSync()) {
      fail(
        'Library file not found at $_libraryRelative — '
        'running test from wrong working directory?',
      );
    }

    final symbols = _collectPublicSymbols(libraryFile);

    final current = symbols.toList()..sort();
    final currentBlob = current.join('\n');

    final goldenBlob =
        goldenFile.existsSync() ? goldenFile.readAsStringSync().trim() : '';

    if (goldenBlob.isEmpty) {
      goldenFile.writeAsStringSync('$currentBlob\n');
      fail(
        'Initial snapshot written to $_goldenRelative '
        '(${current.length} symbols). Review and commit the golden file.',
      );
    }

    final golden =
        goldenBlob
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final goldenSet = golden.toSet();
    final currentSet = current.toSet();

    final added = currentSet.difference(goldenSet).toList()..sort();
    final removed = goldenSet.difference(currentSet).toList()..sort();

    if (added.isEmpty && removed.isEmpty) {
      // Match — happy path.
      return;
    }

    final buffer =
        StringBuffer()
          ..writeln('Public API drift detected vs $_goldenRelative.')
          ..writeln('')
          ..writeln('  Added (${added.length}):');
    if (added.isEmpty) {
      buffer.writeln('    (none)');
    } else {
      for (final s in added) {
        buffer.writeln('    + $s');
      }
    }
    buffer
      ..writeln('')
      ..writeln('  Removed (${removed.length}):');
    if (removed.isEmpty) {
      buffer.writeln('    (none)');
    } else {
      for (final s in removed) {
        buffer.writeln('    - $s');
      }
    }
    buffer
      ..writeln('')
      ..writeln(
        'If the change is intentional, rerun this test to regenerate the '
        'golden, then commit it. To regenerate manually, delete '
        '$_goldenRelative and rerun.',
      );

    // Helpful side-effect: also overwrite the golden so a second run produces
    // a clean diff. Disabled to avoid masking accidental changes — devs must
    // explicitly delete the golden to regenerate.
    fail(buffer.toString());
  });
}

/// Reads [libraryFile] and produces the sorted set of public top-level
/// symbol names exported through it.
Set<String> _collectPublicSymbols(File libraryFile) {
  final libDir = libraryFile.parent.path; // .../lib
  final libSource = libraryFile.readAsStringSync();

  final exportRe = RegExp(
    r'''^\s*export\s+['"]([^'"]+)['"]([^;]*);''',
    multiLine: true,
  );

  final symbols = <String>{};

  for (final match in exportRe.allMatches(libSource)) {
    final relPath = match.group(1)!;
    final tail = match.group(2) ?? '';

    // Honor `show` clauses: only those identifiers are publicly exported.
    final showed = _parseShowClause(tail);

    // Skip `package:` and `dart:` re-exports — out of repo, can't grep.
    if (relPath.startsWith('package:') || relPath.startsWith('dart:')) {
      if (showed != null) symbols.addAll(showed);
      continue;
    }

    final exportedFile = File('$libDir/$relPath');
    if (!exportedFile.existsSync()) {
      // Tolerate missing files (e.g. mid-refactor deletions). Surface in
      // failure mode only — we keep collecting other symbols.
      continue;
    }

    final fileSymbols = _extractFromFile(exportedFile);

    if (showed != null) {
      symbols.addAll(fileSymbols.where(showed.contains));
    } else {
      symbols.addAll(fileSymbols);
    }
  }

  return symbols;
}

/// Returns the set of names in a `show a, b, c` clause, or `null` if there
/// is no `show` clause. (We intentionally ignore `hide` — uncommon and
/// would require also knowing the unfiltered set first.)
Set<String>? _parseShowClause(String tail) {
  final showRe = RegExp(r'\bshow\s+([A-Za-z_,\s]+)');
  final m = showRe.firstMatch(tail);
  if (m == null) return null;
  return m
      .group(1)!
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
}

/// Reads [file] and extracts public top-level symbol names via regex.
/// Skips:
///   * private names (`_foo`)
///   * extensions with no name (`extension on Foo`)
///   * declarations indented inside another scope (we require start-of-line)
Set<String> _extractFromFile(File file) {
  final out = <String>{};
  final String source;
  try {
    source = file.readAsStringSync();
  } catch (_) {
    return out;
  }

  // Strip block comments and line comments line-by-line so we don't match
  // declaration-looking words inside docstrings. We keep it cheap: a one-pass
  // state machine for `/* ... */` and a per-line strip of `// ...`.
  final stripped = _stripDartComments(source);

  // Top-level declarations live at column 0. We anchor to start-of-line
  // with no leading whitespace so we don't catch indented declarations
  // inside class/function bodies (which would include local variables and
  // private helper classes that aren't part of the public surface).

  // Classes — handles modifiers like abstract / sealed / base / final /
  // interface / mixin (in `mixin class`).
  final classRe = RegExp(
    r'^(?:abstract\s+|sealed\s+|base\s+|interface\s+|final\s+|mixin\s+)*class\s+([A-Za-z_]\w*)',
    multiLine: true,
  );
  for (final m in classRe.allMatches(stripped)) {
    _add(out, m.group(1)!, kind: 'class');
  }

  // Enums.
  final enumRe = RegExp(r'^enum\s+([A-Za-z_]\w*)', multiLine: true);
  for (final m in enumRe.allMatches(stripped)) {
    _add(out, m.group(1)!, kind: 'enum');
  }

  // Mixins — `mixin Foo on X`. Excludes `mixin class Foo` (already caught
  // by classRe).
  final mixinRe = RegExp(
    r'^(?:base\s+)?mixin\s+([A-Za-z_]\w*)',
    multiLine: true,
  );
  for (final m in mixinRe.allMatches(stripped)) {
    final name = m.group(1)!;
    // Filter out `mixin class` — those are classes, handled above.
    if (name == 'class') continue;
    _add(out, name, kind: 'mixin');
  }

  // Extensions — `extension FooX on Bar { ... }`. Anonymous extensions
  // (`extension on Bar`) are intentionally skipped.
  final extRe = RegExp(r'^extension\s+([A-Za-z_]\w*)\s+on\b', multiLine: true);
  for (final m in extRe.allMatches(stripped)) {
    _add(out, m.group(1)!, kind: 'extension');
  }

  // Typedefs — both `typedef Foo = ...;` and the legacy
  // `typedef Foo(...);` form.
  final typedefRe = RegExp(r'^typedef\s+([A-Za-z_]\w*)\b', multiLine: true);
  for (final m in typedefRe.allMatches(stripped)) {
    _add(out, m.group(1)!, kind: 'typedef');
  }

  // Top-level `const` or `final` variables.
  //
  //   const int kFoo = 1;
  //   final List<X> _bar = [];   <- skipped (private)
  //   const kBaz = 0;            <- handled (no type)
  //
  // Anchored at column 0 so we never catch locals inside functions or
  // class fields.
  final varRe = RegExp(
    r'''^(?:const|final)\s+(?:[\w<>,\s\?\[\]]+\s+)?([A-Za-z_]\w*)\s*=''',
    multiLine: true,
  );
  for (final m in varRe.allMatches(stripped)) {
    _add(out, m.group(1)!, kind: 'var');
  }

  return out;
}

void _add(Set<String> out, String name, {required String kind}) {
  if (name.isEmpty) return;
  if (name.startsWith('_')) return;
  // Filter out keywords that can leak from a sloppy regex match.
  const reserved = {
    'class',
    'enum',
    'extension',
    'mixin',
    'typedef',
    'on',
    'return',
    'if',
    'else',
    'for',
    'while',
    'switch',
    'case',
    'true',
    'false',
    'null',
    'this',
    'super',
    'new',
    'const',
    'final',
    'var',
    'void',
    'int',
    'double',
    'num',
    'bool',
    'String',
    'List',
    'Map',
    'Set',
    'Iterable',
    'Future',
    'Stream',
    'Function',
    'Object',
    'dynamic',
    'late',
  };
  if (reserved.contains(name)) return;
  out.add(name);
}

/// Removes `/* ... */` block comments (non-nested) and `// ...` line
/// comments, replacing each removed span with a single space so line
/// positions only shift inside the removed block (good enough for our
/// start-of-line regexes).
String _stripDartComments(String src) {
  final buf = StringBuffer();
  var i = 0;
  final n = src.length;
  while (i < n) {
    final c = src[i];
    final c2 = i + 1 < n ? src[i + 1] : '';
    if (c == '/' && c2 == '*') {
      // Block comment. Find closing.
      final end = src.indexOf('*/', i + 2);
      if (end < 0) {
        // Unterminated — bail, keep rest as-is so we don't lose data.
        buf.write(src.substring(i));
        return buf.toString();
      }
      // Preserve newlines inside the block so line-anchored regexes stay
      // aligned.
      for (var k = i; k < end + 2; k++) {
        if (src[k] == '\n') buf.write('\n');
      }
      i = end + 2;
      continue;
    }
    if (c == '/' && c2 == '/') {
      // Line comment — skip to newline.
      final end = src.indexOf('\n', i + 2);
      if (end < 0) return buf.toString();
      buf.write('\n');
      i = end + 1;
      continue;
    }
    // String literals: skip over them so `//` inside a string doesn't get
    // mistaken for a comment.
    if (c == "'" || c == '"') {
      final close = _skipStringLiteral(src, i);
      buf.write(src.substring(i, close));
      i = close;
      continue;
    }
    buf.write(c);
    i++;
  }
  return buf.toString();
}

/// Returns the index just past the closing quote of the string literal
/// starting at [src][start]. Handles raw strings, triple-quoted strings, and
/// simple `\` escapes. Best-effort — does not parse interpolation.
int _skipStringLiteral(String src, int start) {
  final n = src.length;
  var i = start;
  final raw = i > 0 && src[i - 1] == 'r';
  final quote = src[i];
  // Triple quoted?
  final triple = i + 2 < n && src[i + 1] == quote && src[i + 2] == quote;
  if (triple) {
    i += 3;
    while (i < n) {
      if (i + 2 < n &&
          src[i] == quote &&
          src[i + 1] == quote &&
          src[i + 2] == quote) {
        return i + 3;
      }
      i++;
    }
    return n;
  }
  i++;
  while (i < n) {
    final ch = src[i];
    if (!raw && ch == r'\') {
      i += 2;
      continue;
    }
    if (ch == quote) return i + 1;
    if (ch == '\n') return i; // unterminated; bail
    i++;
  }
  return n;
}
