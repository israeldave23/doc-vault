import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../../data/local/hive_service.dart';
import '../models/app_settings.dart';

/// The single settings record, kept in sync with the encrypted Hive box.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  Box<AppSettings> get _box =>
      Hive.box<AppSettings>(HiveService.settingsBox);

  @override
  AppSettings build() =>
      _box.get(AppSettings.storageKey) ?? const AppSettings();

  Future<void> update(AppSettings next) async {
    await _box.put(AppSettings.storageKey, next);
    state = next;
  }

  /// Re-reads from the box — used after a backup restore overwrites it.
  void refresh() {
    state = _box.get(AppSettings.storageKey) ?? const AppSettings();
  }
}
