import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum ExpiryStatus {
  expired,
  critical, // less than 30 days
  warning, // less than 90 days
  ok;

  /// Thresholds are deliberately simple so the meaning is obvious to users.
  static ExpiryStatus fromDaysRemaining(int days) {
    if (days < 0) return ExpiryStatus.expired;
    if (days < 30) return ExpiryStatus.critical;
    if (days < 90) return ExpiryStatus.warning;
    return ExpiryStatus.ok;
  }

  Color get color {
    switch (this) {
      case ExpiryStatus.expired:
        return AppColors.statusExpired;
      case ExpiryStatus.critical:
        return AppColors.statusCritical;
      case ExpiryStatus.warning:
        return AppColors.statusWarning;
      case ExpiryStatus.ok:
        return AppColors.statusOk;
    }
  }

  String get label {
    switch (this) {
      case ExpiryStatus.expired:
        return 'Expired';
      case ExpiryStatus.critical:
        return 'Expiring soon';
      case ExpiryStatus.warning:
        return 'Renew soon';
      case ExpiryStatus.ok:
        return 'Valid';
    }
  }
}

/// Whole days from today (local midnight) until [expiry]. Negative if past.
int daysUntil(DateTime expiry, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final target = _dateOnly(expiry);
  return target.difference(today).inDays;
}

String daysRemainingLabel(int days) {
  if (days < 0) {
    final past = -days;
    return past == 1 ? 'Expired 1 day ago' : 'Expired $past days ago';
  }
  if (days == 0) return 'Expires today';
  if (days == 1) return 'Expires tomorrow';
  return '$days days left';
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
