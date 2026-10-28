import 'package:hive_ce/hive.dart';

/// A person whose documents are tracked (Me, Spouse, Child, Parent...).
class Profile {
  const Profile({required this.id, required this.name, this.avatarEmoji});

  /// The default profile that always exists.
  static const selfId = 'me';

  final String id;
  final String name;
  final String? avatarEmoji;

  /// Backup / restore interchange format.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'avatarEmoji': avatarEmoji,
      };

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        name: map['name'] as String,
        avatarEmoji: map['avatarEmoji'] as String?,
      );

  Profile copyWith({String? name, String? avatarEmoji}) {
    return Profile(
      id: id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    );
  }
}

class ProfileAdapter extends TypeAdapter<Profile> {
  @override
  final int typeId = 1;

  @override
  Profile read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < count; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Profile(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarEmoji: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Profile obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarEmoji);
  }
}
