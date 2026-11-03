enum UserRole { admin, usuario }

class UserEntity {
  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? photoUrl;

  bool get isAdmin => role == UserRole.admin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          role == other.role &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode =>
      Object.hash(uid, email, displayName, role, photoUrl);
}
