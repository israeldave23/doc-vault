import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../documents/models/document.dart';
import 'reminder_schedule.dart';

final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// Schedules the local expiry reminders that are the whole point of the app.
///
/// All scheduling is *rebuilt from scratch* on every sync ([syncAll]): cancel
/// everything, then schedule what the current documents need. That keeps ids,
/// edited documents and deletions consistent without per-notification
/// bookkeeping.
class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  /// Cancels every pending reminder and schedules the ones [docs] need now.
  Future<void> syncAll(Iterable<Document> docs, {DateTime? now}) async {
    await init();
    final current = now ?? DateTime.now();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canUseExact = await android?.canScheduleExactNotifications() ?? false;
    final mode = canUseExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_reminders',
        'Expiry reminders',
        channelDescription: 'Warns you before a document expires.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.cancelAll();

    // Deterministic order so notification ids are stable between syncs.
    final sorted = docs.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    var id = 1;
    final dateFormat = DateFormat.yMMMd();
    for (final doc in sorted) {
      for (final reminder in remindersFor(doc, now: current)) {
        await _plugin.zonedSchedule(
          id: id++,
          // The fire time is computed as a device-local [DateTime]; wrapping it
          // in a TZDateTime keeps that exact instant, so 9:00 AM really is
          // 9:00 AM locally without needing a timezone-name lookup package.
          scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
          title: doc.title,
          body: 'Expires ${dateFormat.format(doc.expiryDate)} — '
              '${reminder.daysBefore} ${reminder.daysBefore == 1 ? 'day' : 'days'} left',
          notificationDetails: details,
          androidScheduleMode: mode,
          payload: doc.id,
        );
      }
    }
  }

  /// Makes sure notifications (and exact alarms) may be shown. Explains what
  /// will be sent *before* the system prompt appears. Returns `true` when
  /// reminders can fire.
  Future<bool> ensurePermission(BuildContext context) async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true; // non-Android platform for now

    if (await android.areNotificationsEnabled() ?? false) {
      return _ensureExactAlarm(android);
    }
    if (!context.mounted) return false;

    final explained = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn on reminders'),
        content: const Text(
          'Document Expiry Vault sends a local notification before a document '
          'expires — for example 90, 30, 7 and 1 day ahead. Nothing leaves '
          'your phone: these are on-device notifications only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
    if (explained != true) return false;

    await android.requestNotificationsPermission();
    if (!context.mounted) return false;
    return _ensureExactAlarm(android);
  }

  Future<bool> _ensureExactAlarm(AndroidFlutterLocalNotificationsPlugin android) async {
    if (await android.canScheduleExactNotifications() ?? false) return true;
    // Falls back to inexact scheduling if the user declines; reminders still
    // arrive, just not necessarily to the exact minute.
    await android.requestExactAlarmsPermission();
    return await android.canScheduleExactNotifications() ?? false;
  }
}
