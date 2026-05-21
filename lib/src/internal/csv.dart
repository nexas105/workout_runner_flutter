/// Tiny CSV helpers used by the `toCsv` exports on result models.
///
/// Not exposed publicly — package-private and intentionally minimal. If a
/// consumer needs full RFC-4180 parsing they should plug a real CSV package
/// in on the application side and feed it `toJson` output instead.
library;

String csvField(Object? value) {
  if (value == null) return '';
  final str = value is Duration ? value.inSeconds.toString() : value.toString();
  final needsQuoting =
      str.contains(',') ||
      str.contains('"') ||
      str.contains('\n') ||
      str.contains('\r');
  if (!needsQuoting) return str;
  return '"${str.replaceAll('"', '""')}"';
}

String csvRow(List<Object?> values) => values.map(csvField).join(',');
