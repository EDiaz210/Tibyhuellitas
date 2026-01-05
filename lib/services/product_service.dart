import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todos los productos
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  // Obtener productos por categoría
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching products by category: $e');
      rethrow;
    }
  }

  // Obtener un producto por ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Crear un nuevo producto (solo admin)
  Future<Product?> createProduct(Product product) async {
    try {
      final json = product.toJson();
      json.remove('id'); // Dejar que Supabase genere el ID

      final response = await _supabase
          .from('products')
          .insert(json)
          .select()
          .single();

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  // Actualizar un producto (solo admin)
  Future<Product?> updateProduct(String id, Product product) async {
    try {
      final json = product.toJson();
      json.remove('id');

      final response = await _supabase
          .from('products')
          .update(json)
          .eq('id', id)
          .select()
          .single();

      return Product.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  // Eliminar un producto (solo admin)
  Future<bool> deleteProduct(String id) async {
    try {
      await _supabase
          .from('products')
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Buscar productos
  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
    }
  }
}
