import 'package:doc_vault/features/documents/services/expiry_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed "today" so date expectations never drift.
  final today = DateTime(2026, 10, 27);

  group('suggestExpiryDate', () {
    test('reads ISO dates', () {
      expect(
        suggestExpiryDate('VALID UNTIL 2028-11-03', now: today),
        DateTime(2028, 11, 3),
      );
      expect(
        suggestExpiryDate('2029/01/15', now: today),
        DateTime(2029, 1, 15),
      );
    });

    test('reads DD MMM YYYY including full month names', () {
      expect(
        suggestExpiryDate('Expires 03 Nov 2028', now: today),
        DateTime(2028, 11, 3),
      );
      expect(
        suggestExpiryDate('EXPIRY DATE 15 September 2027', now: today),
        DateTime(2027, 9, 15),
      );
    });

    test('reads numeric dates and keeps the later reading of ambiguous ones', () {
      // 03/11/2028: day-first = 3 Nov, month-first = 3 Nov — same date.
      expect(suggestExpiryDate('03/11/2028', now: today), DateTime(2028, 11, 3));
      // 05/06/2029: day-first = 5 Jun, month-first = 6 May -> later wins.
      expect(suggestExpiryDate('05/06/2029', now: today), DateTime(2029, 6, 5));
      // Impossible as day-first (month 13), works as month/day.
      expect(suggestExpiryDate('12/13/2029', now: today), DateTime(2029, 12, 13));
    });

    test('rejects impossible calendar dates', () {
      expect(suggestExpiryDate('31/02/2029', now: today), isNull);
      expect(suggestExpiryDate('2029-02-31', now: today), isNull);
      expect(suggestExpiryDate('2029-13-01', now: today), isNull);
    });

    test('reads MRZ YYMMDD fields from a passport line', () {
      // TD3 second line: birth 850131 (past -> ignored), expiry 281103.
      const mrz =
          'P<PHLMARIA<<JOSEFA<<<<<<<<<<<<<<<<<<<<<<<<<<<\n'
          '1234567890<4PHL8501315F2811034PHL<<<<<<<<<<<<<<6';
      expect(suggestExpiryDate(mrz, now: today), DateTime(2028, 11, 3));
    });

    test('ignores dates that are not in the future', () {
      expect(suggestExpiryDate('Expired 2020-05-01', now: today), isNull);
      expect(suggestExpiryDate('31/12/2025', now: today), isNull);
      expect(suggestExpiryDate('01 Jan 2026', now: today), isNull);
    });

    test('ignores today itself', () {
      expect(suggestExpiryDate('27/10/2026', now: today), isNull);
    });

    test('returns null for empty text and unrelated text', () {
      expect(suggestExpiryDate('', now: today), isNull);
      expect(suggestExpiryDate('   \n ', now: today), isNull);
      expect(suggestExpiryDate('REPUBLIC OF THE PHILIPPINES', now: today), isNull);
      expect(suggestExpiryDate('12345', now: today), isNull);
    });

    test('returns the latest of several candidates', () {
      const text = 'ISSUED 01/03/2027\nEXPIRES 09/08/2030';
      expect(suggestExpiryDate(text, now: today), DateTime(2030, 9, 8));
    });

    test('parses a driver license style block', () {
      const license = 'LTO DRIVER LICENSE\nDL NO 1234567890\n'
          'EXP 04/15/2029\nNAME DELA CRUZ JUAN';
      expect(suggestExpiryDate(license, now: today), DateTime(2029, 4, 15));
    });
  });
}
