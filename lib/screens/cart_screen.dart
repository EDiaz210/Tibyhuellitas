import 'package:flutter/material.dart';
import '../widgets/food_drawer.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../models/order.dart';

class CartScreen extends StatefulWidget {
  final Function(int) onSelect;
  final List<Product> cart;
  final VoidCallback onClearCart;
  const CartScreen({Key? key, required this.onSelect, required this.cart, required this.onClearCart}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
      return;
    }

    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión')),
        );
        return;
      }

      // Asegurar que el usuario existe en la tabla users
      final userExists = await _authService.ensureUserExists();
      if (!userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al verificar usuario')),
        );
        return;
      }

      final items = widget.cart
          .map((product) => OrderItem(
                productId: product.id,
                productName: product.name,
                price: product.getEffectivePrice(),
                quantity: product.quantity ?? 1,
                imageUrl: product.imageUrl,
              ))
          .toList();

      final totalPrice = items.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      await _orderService.createOrder(
        userId: userId,
        items: items,
        totalPrice: totalPrice,
        deliveryAddress: _addressController.text,
        phoneNumber: _phoneController.text,
      );

      widget.onClearCart();
      _addressController.clear();
      _phoneController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Orden confirmada!')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onSelect(0);
        });
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear la orden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (var item in widget.cart) {
      total += item.getEffectivePrice() * item.quantity;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Carrito')),
      drawer: FoodDrawer(onSelect: widget.onSelect),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: widget.cart.isEmpty
                  ? Center(child: Text('El carrito está vacío'))
                  : ListView.separated(
                      itemCount: widget.cart.length,
                      separatorBuilder: (_, __) => SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final product = widget.cart[i];
                        return Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.deepPurple[100],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.broken_image, size: 28),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Cantidad: ${product.quantity}'),
                                  if (product.hasOffer)
                                    Text(
                                      'Oferta: \$${product.offerPrice}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${(product.getEffectivePrice() * product.quantity).toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),
            if (widget.cart.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Dirección de entrega',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClearCart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF0066CC),
                        side: BorderSide(color: Color(0xFF0066CC)),
                      ),
                      child: Text('Vaciar carrito'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (widget.cart.isEmpty || _isProcessing) ? null : _placeOrder,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Confirmar orden'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
