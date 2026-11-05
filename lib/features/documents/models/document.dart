import 'package:hive_ce/hive.dart';

import '../../../core/utils/expiry_status.dart';

/// A single tracked document (passport, license, permit, ...).
/// Stored in an AES-encrypted Hive box. Image paths point to files inside the
/// app sandbox; the files themselves get encrypted in Week 2.
class Document {
  Document({
    required this.id,
    required this.title,
    required this.category,
    required this.expiryDate,
    required this.profileId,
    this.idNumber,
    this.issueDate,
    List<String>? imagePaths,
    this.notes,
    List<int>? reminderDaysBefore,
    this.remindersEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : imagePaths = imagePaths ?? <String>[],
        reminderDaysBefore = reminderDaysBefore ?? defaultReminderDays,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const defaultReminderDays = <int>[90, 30, 7, 1];

  final String id;
  final String title;
  final String category; // DocumentCategory.key
  final String? idNumber;
  final DateTime? issueDate;
  final DateTime expiryDate;
  final String profileId;
  final List<String> imagePaths;
  final String? notes;
  final List<int> reminderDaysBefore;
  final bool remindersEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get daysRemaining => daysUntil(expiryDate);
  ExpiryStatus get status => ExpiryStatus.fromDaysRemaining(daysRemaining);

  /// Last 4 characters only, for list views.
  String? get maskedIdNumber {
    final value = idNumber;
    if (value == null || value.isEmpty) return null;
    if (value.length <= 4) return value;
    return '•••• ${value.substring(value.length - 4)}';
  }

  /// Backup / restore interchange format; dates as ISO-8601 strings.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'category': category,
        'idNumber': idNumber,
        'issueDate': issueDate?.toIso8601String(),
        'expiryDate': expiryDate.toIso8601String(),
        'profileId': profileId,
        'imagePaths': imagePaths,
        'notes': notes,
        'reminderDaysBefore': reminderDaysBefore,
        'remindersEnabled': remindersEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Document.fromMap(Map<String, dynamic> map) {
    String requiredString(String key, int maxLength) {
      final value = map[key];
      if (value is! String || value.isEmpty || value.length > maxLength) {
        throw FormatException('Invalid document $key');
      }
      return value;
    }

    String? optionalString(String key, int maxLength) {
      final value = map[key];
      if (value == null) return null;
      if (value is! String || value.length > maxLength) {
        throw FormatException('Invalid document $key');
      }
      return value;
    }

    DateTime date(String key, {bool optional = false}) {
      final value = map[key];
      if (optional && value == null) return DateTime.now();
      if (value is! String || value.length > 64) {
        throw FormatException('Invalid document $key');
      }
      try {
        final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T|$)').firstMatch(value);
        if (match == null) throw const FormatException('Invalid date');
        final year = int.parse(match[1]!);
        final month = int.parse(match[2]!);
        final day = int.parse(match[3]!);
        final calendarDate = DateTime.utc(year, month, day);
        if (year < 1 || calendarDate.year != year ||
            calendarDate.month != month || calendarDate.day != day) {
          throw const FormatException('Invalid date');
        }
        final time = RegExp(r'T(\d{2}):(\d{2}):(\d{2})').firstMatch(value);
        if (time != null && (int.parse(time[1]!) > 23 ||
            int.parse(time[2]!) > 59 || int.parse(time[3]!) > 59)) {
          throw const FormatException('Invalid time');
        }
        return DateTime.parse(value);
      } on FormatException {
        throw FormatException('Invalid document $key');
      }
    }

    final rawImages = map['imagePaths'];
    if (rawImages != null &&
        (rawImages is! List || rawImages.length > 20 ||
            rawImages.any((value) => value is! String || value.isEmpty || value.length > 255))) {
      throw const FormatException('Invalid document imagePaths');
    }
    final rawReminders = map['reminderDaysBefore'];
    if (rawReminders != null &&
        (rawReminders is! List || rawReminders.length > 32 ||
            rawReminders.any((value) => value is! int || value < 0 || value > 36500))) {
      throw const FormatException('Invalid document reminderDaysBefore');
    }
    final enabled = map['remindersEnabled'];
    if (enabled != null && enabled is! bool) {
      throw const FormatException('Invalid document remindersEnabled');
    }

    return Document(
      id: requiredString('id', 256),
      title: requiredString('title', 500),
      category: requiredString('category', 100),
      idNumber: optionalString('idNumber', 500),
      issueDate: map['issueDate'] == null ? null : date('issueDate'),
      expiryDate: date('expiryDate'),
      profileId: requiredString('profileId', 256),
      imagePaths: rawImages == null ? null : List<String>.from(rawImages as List),
      notes: optionalString('notes', 10000),
      reminderDaysBefore: rawReminders == null ? null : List<int>.from(rawReminders as List),
      remindersEnabled: enabled as bool? ?? true,
      createdAt: date('createdAt', optional: true),
      updatedAt: date('updatedAt', optional: true),
    );
  }

  Document copyWith({
    String? title,
    String? category,
    String? idNumber,
    bool clearIdNumber = false,
    DateTime? issueDate,
    bool clearIssueDate = false,
    DateTime? expiryDate,
    String? profileId,
    List<String>? imagePaths,
    String? notes,
    bool clearNotes = false,
    List<int>? reminderDaysBefore,
    bool? remindersEnabled,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      idNumber: clearIdNumber ? null : (idNumber ?? this.idNumber),
      issueDate: clearIssueDate ? null : (issueDate ?? this.issueDate),
      expiryDate: expiryDate ?? this.expiryDate,
      profileId: profileId ?? this.profileId,
      imagePaths: imagePaths ?? this.imagePaths,
      notes: clearNotes ? null : (notes ?? this.notes),
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Hand-written adapter (no build_runner needed). Field numbers must never be
/// reused or changed once the app ships; add new fields with new numbers.
class DocumentAdapter extends TypeAdapter<Document> {
  @override
  final int typeId = 0;

  @override
  Document read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Document(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      idNumber: fields[3] as String?,
      issueDate: fields[4] as DateTime?,
      expiryDate: fields[5] as DateTime,
      profileId: fields[6] as String,
      imagePaths: (fields[7] as List?)?.cast<String>() ?? <String>[],
      notes: fields[8] as String?,
      reminderDaysBefore: (fields[9] as List?)?.cast<int>(),
      remindersEnabled: fields[10] as bool? ?? true,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Document obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.idNumber)
      ..writeByte(4)
      ..write(obj.issueDate)
      ..writeByte(5)
      ..write(obj.expiryDate)
      ..writeByte(6)
      ..write(obj.profileId)
      ..writeByte(7)
      ..write(obj.imagePaths)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.reminderDaysBefore)
      ..writeByte(10)
      ..write(obj.remindersEnabled)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }
}
