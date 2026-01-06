import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role; // adopter, refuge, admin
  final bool emailVerified;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Usuario',
      role: json['role'] ?? 'adopter',
      emailVerified: json['email_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'email_verified': emailVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

abstract class UserRepository {
  Future<UserProfile?> getCurrentUserProfile();
  Future<void> updateUserProfile(String name, String email);
  Future<void> updatePassword(String oldPassword, String newPassword);
}

class UserRepositoryImpl implements UserRepository {
  final SupabaseClient supabase;

  UserRepositoryImpl({required this.supabase});

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      try {
        final response = await supabase
            .from('users')
            .select()
            .eq('id', user.id)
            .single();

        return UserProfile.fromJson(response);
      } catch (e) {
        // Si no existe el usuario en la tabla, crearlo
        if (e.toString().contains('0 rows')) {
          final newProfile = UserProfile(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'Usuario',
            role: 'adopter',
            emailVerified: user.emailConfirmedAt != null,
            createdAt: DateTime.now(),
          );

          try {
            await supabase.from('users').insert(newProfile.toJson());
          } catch (insertError) {
            print('Error inserting user: $insertError');
          }

          return newProfile;
        }
        print('Error fetching user profile: $e');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateUserProfile(String name, String email) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await supabase.from('users').update({
        'name': name,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // También actualizar el email en auth
      await supabase.auth.updateUser(
        UserAttributes(email: email),
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verificar contraseña antigua
      await supabase.auth.signInWithPassword(
        email: user.email ?? '',
        password: oldPassword,
      );

      // Actualizar a nueva contraseña
      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      print('Error updating password: $e');
      rethrow;
    }
  }
}
