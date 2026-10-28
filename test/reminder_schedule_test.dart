import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/reminders/services/reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed "now": 27 Oct 2026, 15:30 local — after 9:00 AM, so today's slot is
  // already gone.
  final now = DateTime(2026, 10, 27, 15, 30);

  Document doc({
    required DateTime expiry,
    List<int> leads = Document.defaultReminderDays,
    bool enabled = true,
  }) =>
      Document(
        id: 'doc-1',
        title: 'Passport',
        category: 'passport',
        expiryDate: expiry,
        profileId: 'me',
        reminderDaysBefore: leads,
        remindersEnabled: enabled,
      );

  group('remindersFor', () {
    test('schedules configured leads and fills the final week', () {
      // Expiry 20 Dec 2026, default leads 90/30/7/1.
      // 90 days = 21 Sep (past -> dropped), 30 days = 20 Nov, plus the
      // final-week daily fill 13..19 Dec.
      final reminders = remindersFor(doc(expiry: DateTime(2026, 12, 20)), now: now);

      final days = reminders.map((r) => r.daysBefore).toList();
      expect(days, [30, 7, 6, 5, 4, 3, 2, 1]);
      expect(reminders.first.fireAt, DateTime(2026, 11, 20, 9));
      expect(reminders.last.fireAt, DateTime(2026, 12, 19, 9));
    });

    test('every reminder fires at 9:00 AM local and is in the future', () {
      final reminders = remindersFor(doc(expiry: DateTime(2026, 12, 20)), now: now);
      for (final r in reminders) {
        expect(r.fireAt.hour, 9);
        expect(r.fireAt.minute, 0);
        expect(r.fireAt.isAfter(now), isTrue);
      }
      expect(
        reminders.map((r) => r.fireAt).toList(),
        List.of(reminders.map((r) => r.fireAt))
          ..sort((a, b) => a.compareTo(b)),
        reason: 'reminders must be returned in ascending order',
      );
    });

    test('long-lead-only documents do not get final-week dailies', () {
      final reminders = remindersFor(
        doc(expiry: DateTime(2026, 12, 20), leads: [90, 30]),
        now: now,
      );
      expect(reminders.map((r) => r.daysBefore).toList(), [30]);
    });

    test('keeps todays 9:00 AM slot when it has not passed yet', () {
      final morning = DateTime(2026, 10, 27, 7, 0);
      final reminders = remindersFor(doc(expiry: DateTime(2026, 10, 28)), now: morning);
      expect(reminders.map((r) => r.daysBefore), contains(1));
      expect(reminders.first.fireAt, DateTime(2026, 10, 27, 9));
    });

    test('drops todays 9:00 AM slot once it has passed', () {
      final reminders = remindersFor(doc(expiry: DateTime(2026, 10, 28)), now: now);
      expect(reminders, isEmpty);
    });

    test('returns nothing for a disabled document', () {
      final reminders = remindersFor(
        doc(expiry: DateTime(2026, 12, 20), enabled: false),
        now: now,
      );
      expect(reminders, isEmpty);
    });

    test('returns nothing for an expired document', () {
      final reminders = remindersFor(doc(expiry: DateTime(2026, 1, 1)), now: now);
      expect(reminders, isEmpty);
    });

    test('returns nothing for a document expiring today', () {
      final reminders = remindersFor(doc(expiry: DateTime(2026, 10, 27)), now: now);
      expect(reminders, isEmpty);
    });

    test('drops leads whose date is already in the past', () {
      // Expiry in 10 days: the 90 and 30 day leads are meaningless, 7 and 1
      // are also past (10 - 7 = 3 days ago... 10-7=3 days from now -> future).
      final reminders = remindersFor(
        doc(expiry: DateTime(2026, 11, 6), leads: [90, 30, 7, 1]),
        now: now,
      );
      // 90/30 land in the past; 7 days before = 30 Oct and 1 day before =
      // 5 Nov are still ahead, plus the final-week fill.
      expect(reminders.every((r) => r.fireAt.isAfter(now)), isTrue);
      expect(reminders.map((r) => r.daysBefore), containsAll([7, 1]));
      expect(reminders.map((r) => r.daysBefore), isNot(contains(90)));
      expect(reminders.map((r) => r.daysBefore), isNot(contains(30)));
    });
  });
}
