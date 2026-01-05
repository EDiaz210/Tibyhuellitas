import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Crear una nueva orden
  Future<Order?> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double totalPrice,
    required String deliveryAddress,
    required String phoneNumber,
  }) async {
    try {
      final response = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'items': items.map((e) => e.toJson()).toList(),
            'total_price': totalPrice,
            'status': 'pending',
            'delivery_address': deliveryAddress,
            'phone_number': phoneNumber,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Obtener órdenes del usuario
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching user orders: $e');
      rethrow;
    }
  }

  // Obtener una orden por ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Actualizar estado de la orden
  Future<Order?> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId)
          .select()
          .single();

      return Order.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Cancelar una orden
  Future<bool> cancelOrder(String orderId) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId);
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // Obtener órdenes recientes (para dashboard admin)
  Future<List<Order>> getRecentOrders(int limit) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching recent orders: $e');
      rethrow;
    }
  }

  // Obtener órdenes pendientes (para dashboard admin)
  Future<List<Order>> getPendingOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching pending orders: $e');
      rethrow;
    }
  }
}
