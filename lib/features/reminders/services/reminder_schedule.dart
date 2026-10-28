/// Pure-Dart reminder scheduling maths — no plugin import, so it is unit
/// testable on the VM.
///
/// Rules:
/// * Every configured lead time in `reminderDaysBefore` fires at 09:00 local
///   time on `expiry - lead`.
/// * If the document has any lead of 7 days or fewer, the whole final week
///   (expiry-7 .. expiry-1) also fires daily at 09:00 — the "repeat daily in
///   the final week" behaviour from the product spec.
/// * Times already in the past, and anything on/after the expiry date, are
///   dropped, so an expired document schedules nothing.
library;

import '../../documents/models/document.dart';

/// Hour of day (local time) reminders are delivered.
const reminderNotificationHour = 9;

/// Longest lead time that also triggers the daily final-week repeats.
const _finalWeekDays = 7;

class Reminder {
  const Reminder({required this.fireAt, required this.daysBefore});

  /// Local date-time the notification should be shown.
  final DateTime fireAt;

  /// Whole days between [fireAt] and the expiry date, for the message body.
  final int daysBefore;

  @override
  String toString() => 'Reminder($fireAt, in $daysBefore days)';
}

/// All upcoming reminders for [doc], ascending by time.
List<Reminder> remindersFor(Document doc, {DateTime? now}) {
  if (!doc.remindersEnabled) return const <Reminder>[];

  final current = now ?? DateTime.now();
  final today = _dateOnly(current);
  final expiry = _dateOnly(doc.expiryDate);
  if (!expiry.isAfter(today)) return const <Reminder>[]; // expired or expiring today

  final leads = doc.reminderDaysBefore.toSet();
  if (leads.isEmpty) return const <Reminder>[];

  final dates = <DateTime>{};
  for (final lead in leads) {
    if (lead >= 0) dates.add(_addDays(expiry, -lead));
  }

  // Daily repeats across the final week when the document uses short leads.
  if (leads.any((lead) => lead <= _finalWeekDays)) {
    for (var daysBefore = _finalWeekDays; daysBefore >= 1; daysBefore--) {
      dates.add(_addDays(expiry, -daysBefore));
    }
  }

  final reminders = <Reminder>[];
  for (final date in dates) {
    final fireAt = DateTime(
      date.year,
      date.month,
      date.day,
      reminderNotificationHour,
    );
    if (!fireAt.isAfter(current)) continue; // today's 9:00 AM may already be gone
    reminders.add(
      Reminder(fireAt: fireAt, daysBefore: expiry.difference(date).inDays),
    );
  }
  return reminders..sort((a, b) => a.fireAt.compareTo(b.fireAt));
}

DateTime _addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
