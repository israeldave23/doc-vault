/// Pure-Dart extraction of a plausible expiry date from recognized text.
///
/// Kept free of any ML Kit import so it can be unit tested on the VM. The
/// formats match the ones real PH documents and driver's licences use:
///
/// * ISO:      `2028-11-03`, `2028/11/03`
/// * Longhand: `03 Nov 2028`, `3 November 2028`
/// * Numeric:  `03/11/2028` (day-first) and `11/03/2028` (month-first) — the
///   ambiguity is resolved by keeping the later of the two readings, which is
///   the safer choice for a "before it expires" reminder.
/// * MRZ:      `YYMMDD` fields inside machine-readable travel documents.
///
/// Returns the latest **future** date found, or `null` when nothing usable is
/// present (an already-expired date is never suggested).
library;

DateTime? suggestExpiryDate(String text, {DateTime? now}) {
  if (text.trim().isEmpty) return null;
  final today = _dateOnly(now ?? DateTime.now());

  DateTime? best;
  void consider(DateTime? candidate) {
    if (candidate == null) return;
    final date = _dateOnly(candidate);
    if (!date.isAfter(today)) return; // only future dates are suggestions
    final currentBest = best;
    if (currentBest == null || date.isAfter(currentBest)) best = date;
  }

  for (final line in text.split('\n')) {
    consider(_isoDate(line));
    consider(_longhandDate(line));
    for (final numeric in _numericDates(line)) {
      consider(numeric);
    }
    if (_looksLikeMrz(line)) {
      for (final mrz in _mrzDates(line)) {
        consider(mrz);
      }
    }
  }
  return best;
}

/// `2028-11-03` or `2028/11/03`.
DateTime? _isoDate(String line) {
  final match = RegExp(r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b').firstMatch(line);
  if (match == null) return null;
  return _build(
    year: int.parse(match.group(1)!),
    month: int.parse(match.group(2)!),
    day: int.parse(match.group(3)!),
  );
}

/// `03 Nov 2028` / `3 November 2028` / `03-Nov-2028`.
DateTime? _longhandDate(String line) {
  final match = RegExp(
    r'\b(\d{1,2})[\s\-/.]+([A-Za-z]{3,9})[\s\-/.]+(\d{4})\b',
  ).firstMatch(line);
  if (match == null) return null;
  final month = _monthFromName(match.group(2)!);
  if (month == null) return null;
  return _build(
    year: int.parse(match.group(3)!),
    month: month,
    day: int.parse(match.group(1)!),
  );
}

/// `DD/MM/YYYY` and `MM/DD/YYYY` — both readings are produced so the caller
/// keeps the later valid one.
List<DateTime> _numericDates(String line) {
  const pattern = r'\b(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{4})\b';
  final results = <DateTime?>[];
  for (final match in RegExp(pattern).allMatches(line)) {
    final first = int.parse(match.group(1)!);
    final second = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    results.add(_build(year: year, month: second, day: first));
    results.add(_build(year: year, month: first, day: second));
  }
  return results.whereType<DateTime>().toList();
}

/// Machine-readable zone: a fixed-width line stuffed with `<` fillers.
bool _looksLikeMrz(String line) =>
    line.contains('<') && line.trim().length >= 30;

/// `YYMMDD` fields from an MRZ line. The digits of an MRZ field run together
/// with their check digits (e.g. `8501315F2811034`), so every 6-digit window
/// inside a digit run is considered and validated.
List<DateTime> _mrzDates(String line) {
  final results = <DateTime?>[];
  for (final run in RegExp(r'\d{6,}').allMatches(line)) {
    final digits = run.group(0)!;
    for (var i = 0; i + 6 <= digits.length; i++) {
      final window = digits.substring(i, i + 6);
      final year = int.parse(window.substring(0, 2));
      final month = int.parse(window.substring(2, 4));
      final day = int.parse(window.substring(4, 6));
      // MRZ two-digit years: 00-30 => 2000s, 31-99 => 1900s. Expiry dates in
      // the 1900s are filtered out later by the "future only" rule anyway.
      results.add(_build(year: year <= 30 ? 2000 + year : 1900 + year, month: month, day: day));
    }
  }
  return results.whereType<DateTime>().toList();
}

DateTime? _build({required int year, required int month, required int day}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (year < 1900 || year > 2200) return null;
  final date = DateTime(year, month, day);
  // Reject overflow such as 31 February, which DateTime rolls into March.
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

int? _monthFromName(String name) {
  const months = <String, int>{
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };
  return months[name.toLowerCase()];
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
