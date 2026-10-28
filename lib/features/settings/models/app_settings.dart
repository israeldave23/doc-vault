import 'package:hive_ce/hive.dart';

class AppSettings {
  const AppSettings({
    this.defaultReminderDays = const <int>[90, 30, 7, 1],
    this.appLockEnabled = false,
    this.biometricsEnabled = false,
    this.isPro = false,
    this.darkMode = false,
    this.themeMode = 'system',
    this.onboardingCompleted = false,
  });

  /// `system`, `light` or `dark`.
  static const themeSystem = 'system';
  static const themeLight = 'light';
  static const themeDark = 'dark';

  /// Single-record box key.
  static const storageKey = 'settings';

  final List<int> defaultReminderDays;
  final bool appLockEnabled;
  final bool biometricsEnabled;
  final bool isPro;
  final bool darkMode;
  final String themeMode;
  final bool onboardingCompleted;

  AppSettings copyWith({
    List<int>? defaultReminderDays,
    bool? appLockEnabled,
    bool? biometricsEnabled,
    bool? isPro,
    bool? darkMode,
    String? themeMode,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
      defaultReminderDays: defaultReminderDays ?? this.defaultReminderDays,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      isPro: isPro ?? this.isPro,
      darkMode: darkMode ?? this.darkMode,
      themeMode: themeMode ?? this.themeMode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Backup / restore interchange format.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'defaultReminderDays': defaultReminderDays,
        'appLockEnabled': appLockEnabled,
        'biometricsEnabled': biometricsEnabled,
        'isPro': isPro,
        'darkMode': darkMode,
        'themeMode': themeMode,
        'onboardingCompleted': onboardingCompleted,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        defaultReminderDays:
            (map['defaultReminderDays'] as List?)?.cast<int>() ??
                const <int>[90, 30, 7, 1],
        appLockEnabled: map['appLockEnabled'] as bool? ?? false,
        biometricsEnabled: map['biometricsEnabled'] as bool? ?? false,
        isPro: map['isPro'] as bool? ?? false,
        darkMode: map['darkMode'] as bool? ?? false,
        themeMode: map['themeMode'] as String? ?? themeSystem,
        onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      );
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
      // Field 5 added later — old records simply fall back to the default.
      themeMode: fields[5] as String? ?? AppSettings.themeSystem,
      // Field 6 added later.
      onboardingCompleted: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.defaultReminderDays)
      ..writeByte(1)
      ..write(obj.appLockEnabled)
      ..writeByte(2)
      ..write(obj.biometricsEnabled)
      ..writeByte(3)
      ..write(obj.isPro)
      ..writeByte(4)
      ..write(obj.darkMode)
      ..writeByte(5)
      ..write(obj.themeMode)
      ..writeByte(6)
      ..write(obj.onboardingCompleted);
  }
}
