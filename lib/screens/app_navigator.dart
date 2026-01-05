import 'package:flutter/material.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../models/product.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class AppNavigator extends StatefulWidget {
  final UserEntity user;

  const AppNavigator({Key? key, required this.user}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _selectedIndex = 0;
  final List<Product> _cart = [];

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carrito vaciado')),
    );
  }

  void _onDrawerSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((p) => p.id == product.id);
      if (idx >= 0) {
        // Aumentar cantidad si ya existe
        _cart[idx] = _cart[idx].copyWith(
          quantity: _cart[idx].quantity + 1,
        );
      } else {
        // Agregar nuevo producto
        _cart.add(product.copyWith(quantity: 1));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} agregado al carrito')),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = HomeScreen(
          onSelect: _onDrawerSelect,
          onAddToCart: _addToCart,
        );
        break;
      case 1:
        body = ProductsScreen(
          onSelect: _onDrawerSelect,
          onAddToCart: _addToCart,
        );
        break;
      case 2:
        body = CartScreen(
          onSelect: _onDrawerSelect,
          cart: _cart,
          onClearCart: _clearCart,
        );
        break;
      case 3:
        body = OrdersScreen(
          onSelect: _onDrawerSelect,
        );
        break;
      default:
        body = HomeScreen(
          onSelect: _onDrawerSelect,
          onAddToCart: _addToCart,
        );
    }
    return body;
  }
}
