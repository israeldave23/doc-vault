import 'package:hive_ce/hive.dart';

class AppSettings {
  const AppSettings({
    this.defaultReminderDays = const <int>[90, 30, 7, 1],
    this.appLockEnabled = false,
    this.biometricsEnabled = false,
    this.isPro = false,
    this.darkMode = false,
  });

  /// Single-record box key.
  static const storageKey = 'settings';

  final List<int> defaultReminderDays;
  final bool appLockEnabled;
  final bool biometricsEnabled;
  final bool isPro;
  final bool darkMode;

  AppSettings copyWith({
    List<int>? defaultReminderDays,
    bool? appLockEnabled,
    bool? biometricsEnabled,
    bool? isPro,
    bool? darkMode,
  }) {
    return AppSettings(
      defaultReminderDays: defaultReminderDays ?? this.defaultReminderDays,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      isPro: isPro ?? this.isPro,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return AppSettings(
      defaultReminderDays:
          (fields[0] as List?)?.cast<int>() ?? const <int>[90, 30, 7, 1],
      appLockEnabled: fields[1] as bool? ?? false,
      biometricsEnabled: fields[2] as bool? ?? false,
      isPro: fields[3] as bool? ?? false,
      darkMode: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.defaultReminderDays)
      ..writeByte(1)
      ..write(obj.appLockEnabled)
      ..writeByte(2)
      ..write(obj.biometricsEnabled)
      ..writeByte(3)
      ..write(obj.isPro)
      ..writeByte(4)
      ..write(obj.darkMode);
  }
}
