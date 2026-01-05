import 'package:flutter/material.dart';
import '../widgets/food_drawer.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  final Function(int) onSelect;
  const OrdersScreen({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final orders = await _orderService.getUserOrders(userId);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders')),
      );
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await _orderService.cancelOrder(orderId);
      _loadOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Orden cancelada')),
      );
    } catch (e) {
      print('Error cancelling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar la orden')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = _authService.isUserAuthenticated();

    return Scaffold(
      appBar: AppBar(title: Text('Mis Órdenes')),
      drawer: FoodDrawer(onSelect: widget.onSelect),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : !isAuthenticated
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Debes iniciar sesión para ver tus órdenes'),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(child: Text('No tienes órdenes aún'))
                  : ListView.separated(
                      padding: EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          elevation: 4,
                          child: ExpansionTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Orden #${order.id.substring(0, 8)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  order.getFormattedDate(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              'Total: \$${order.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0066CC),
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.getStatusLabel(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Productos:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ...order.items.map((item) => Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.productName),
                                                  Text(
                                                    'Cantidad: ${item.quantity}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                    SizedBox(height: 12),
                                    Divider(),
                                    SizedBox(height: 12),
                                    Text(
                                      'Dirección de entrega:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(order.deliveryAddress),
                                    SizedBox(height: 12),
                                    Text(
                                      'Teléfono: ${order.phoneNumber}',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 16),
                                    if (order.status == 'pending')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: Icon(Icons.cancel),
                                          label: Text('Cancelar orden'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => _cancelOrder(order.id),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
