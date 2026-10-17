import 'package:doc_vault/core/utils/expiry_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpiryStatus.fromDaysRemaining', () {
    test('negative days is expired', () {
      expect(ExpiryStatus.fromDaysRemaining(-1), ExpiryStatus.expired);
    });

    test('0 to 29 days is critical', () {
      expect(ExpiryStatus.fromDaysRemaining(0), ExpiryStatus.critical);
      expect(ExpiryStatus.fromDaysRemaining(29), ExpiryStatus.critical);
    });

    test('30 to 89 days is warning', () {
      expect(ExpiryStatus.fromDaysRemaining(30), ExpiryStatus.warning);
      expect(ExpiryStatus.fromDaysRemaining(89), ExpiryStatus.warning);
    });

    test('90+ days is ok', () {
      expect(ExpiryStatus.fromDaysRemaining(90), ExpiryStatus.ok);
      expect(ExpiryStatus.fromDaysRemaining(3650), ExpiryStatus.ok);
    });
  });

  group('daysUntil', () {
    final today = DateTime(2026, 10, 17, 15, 30);

    test('ignores time of day', () {
      expect(daysUntil(DateTime(2026, 10, 17, 1), now: today), 0);
      expect(daysUntil(DateTime(2026, 10, 18, 23), now: today), 1);
    });

    test('is negative for past dates', () {
      expect(daysUntil(DateTime(2026, 10, 10), now: today), -7);
    });
  });

  group('daysRemainingLabel', () {
    test('formats common cases', () {
      expect(daysRemainingLabel(-1), 'Expired 1 day ago');
      expect(daysRemainingLabel(-5), 'Expired 5 days ago');
      expect(daysRemainingLabel(0), 'Expires today');
      expect(daysRemainingLabel(1), 'Expires tomorrow');
      expect(daysRemainingLabel(45), '45 days left');
    });
  });
}
