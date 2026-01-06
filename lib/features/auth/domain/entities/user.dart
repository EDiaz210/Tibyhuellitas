import 'package:equatable/equatable.dart';

enum UserRole { adopter, refuge, admin }

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool emailVerified;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.emailVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? emailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  List<Object?> get props =>
      [id, email, name, photoUrl, role, createdAt, lastLogin, emailVerified];
}
