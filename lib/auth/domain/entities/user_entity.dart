// auth/domain/entities/user_entity.dart

class UserEntity {
  UserEntity({required this.id, required this.email, this.name});

  final String id;
  String get uid => id;
  final String email;
  final String? name;
  
  UserEntity copyWith({String? id, String? email, String? name}) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode;
}
