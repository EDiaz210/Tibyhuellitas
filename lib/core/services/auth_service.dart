import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Obtener el usuario actual autenticado
  User? get currentUser => _supabase.auth.currentUser;

  /// Obtener el nombre del usuario actual
  String get currentUserName {
    final user = currentUser;
    if (user == null) return 'Usuario';
    
    // Intentar obtener del metadata del usuario
    final metadata = user.userMetadata;
    if (metadata != null && metadata['full_name'] != null) {
      return metadata['full_name'] as String;
    }
    
    // Si no, usar el email
    return user.email?.split('@')[0] ?? 'Usuario';
  }

  /// Obtener email del usuario
  String? get currentUserEmail => currentUser?.email;

  /// Verificar si está autenticado
  bool get isAuthenticated => currentUser != null;

  /// Cerrar sesión
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
