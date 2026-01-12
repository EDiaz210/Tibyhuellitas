import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener usuario actual
  Future<AppUser?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', session.user.id)
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Registrar nuevo usuario
  Future<AppUser?> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Crear usuario en Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user');
      }

      // Crear perfil en la tabla users
      final userResponse = await _supabase
          .from('users')
          .insert({
            'id': response.user!.id,
            'email': email,
            'full_name': fullName,
            'is_email_verified': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return AppUser.fromJson(userResponse);
    } catch (e) {
      print('Error during registration: $e');
      rethrow;
    }
  }

  // Iniciar sesión
  Future<AppUser?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in');
      }

      // Actualizar último login
      await _supabase
          .from('users')
          .update({
            'last_login': DateTime.now().toIso8601String(),
          })
          .eq('id', response.user!.id);

      // Obtener datos del usuario
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromJson(userResponse);
    } catch (e) {
      print('Error during login: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Google Sign-In DIRECTO - sin pasar clientId, deja que Android lo maneje
  Future<bool> signInWithGoogle() async {
    try {
      print('🔵 [GOOGLE SIGNIN] Iniciando proceso de Google Sign-In...');
      
      // GoogleSignIn sin parámetros - Android obtiene el clientId automáticamente
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      print('🔵 [GOOGLE SIGNIN] Limpiando sesión anterior...');
      await googleSignIn.signOut();

      print('🔵 [GOOGLE SIGNIN] Abriendo selector de cuentas de Google...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ [GOOGLE SIGNIN] Usuario canceló Google Sign-In');
        return false;
      }

      print('✅ [GOOGLE SIGNIN] Usuario seleccionó: ${googleUser.email}');
      print('   Nombre: ${googleUser.displayName}');
      print('   ID: ${googleUser.id}');
      return true;
      
    } catch (e) {
      print('❌ [GOOGLE SIGNIN ERROR] $e');
      return false;
    }
  }

  // Enviar correo de recuperación de contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Actualizar contraseña
  Future<bool> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      return true;
    } catch (e) {
      print('Error updating password: $e');
      return false;
    }
  }

  // Actualizar perfil de usuario
  Future<AppUser?> updateUserProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (profileImageUrl != null) updateData['profile_image_url'] = profileImageUrl;

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Verificar si usuario está autenticado
  bool isUserAuthenticated() {
    return _supabase.auth.currentSession != null;
  }

  // Obtener ID del usuario actual
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Verificar y crear usuario en tabla users si no existe
  Future<bool> ensureUserExists() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Verificar si el usuario existe en la tabla users
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        // El usuario no existe en la tabla users, crear registro
        await _supabase
            .from('users')
            .insert({
              'id': userId,
              'email': user.email ?? '',
              'full_name': user.userMetadata?['display_name'] ?? '',
              'is_email_verified': user.emailConfirmedAt != null,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true;
      }
      return true;
    } catch (e) {
      print('Error ensuring user exists: $e');
      return false;
    }
  }

  // Escuchar cambios de autenticación
  Stream<AuthState> authStateChanges() {
    return _supabase.auth.onAuthStateChange;
  }

  // Verificar correo electrónico
  Future<bool> verifyEmail() async {
    try {
      await _supabase.auth.signInWithOtp(email: _supabase.auth.currentUser?.email ?? '');
      return true;
    } catch (e) {
      print('Error verifying email: $e');
      return false;
    }
  }

  // Eliminar cuenta
  Future<bool> deleteAccount(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      await _supabase.auth.signOut();
      return true;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
