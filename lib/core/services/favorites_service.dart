import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();

  factory FavoritesService() {
    return _instance;
  }

  FavoritesService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Crear tabla de favoritos si no existe
  Future<void> initializeFavorites() async {
    try {
      // La tabla se debe crear en Supabase manualmente o via SQL
      // Aquí solo verificamos que el usuario pueda acceder
      await _supabase.from('favorites').select().limit(1);
    } catch (e) {
      print('Favorites table not found: $e');
    }
  }

  /// Agregar mascota a favoritos
  Future<bool> addFavorite(String petId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('favorites').insert({
        'user_id': userId,
        'pet_id': petId,
      });
      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  /// Remover mascota de favoritos
  Future<bool> removeFavorite(String petId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('pet_id', petId);
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Verificar si una mascota es favorita
  Future<bool> isFavorite(String petId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('pet_id', petId);

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  /// Obtener todos los favoritos del usuario
  Future<List<String>> getUserFavorites() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final result = await _supabase
          .from('favorites')
          .select('pet_id')
          .eq('user_id', userId);

      return List<String>.from(result.map((e) => e['pet_id'] as String));
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }
}
