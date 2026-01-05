import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';

class FoodDrawer extends StatefulWidget {
  final Function(int) onSelect;
  const FoodDrawer({Key? key, required this.onSelect}) : super(key: key);

  @override
  State<FoodDrawer> createState() => _FoodDrawerState();
}

class _FoodDrawerState extends State<FoodDrawer> {
  final AuthService _authService = AuthService();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  void _checkAuthentication() {
    setState(() {
      _isAuthenticated = _authService.isUserAuthenticated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: const Color.fromARGB(255, 0, 102, 204)),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 64,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'TibyFood',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.fastfood),
            title: Text('Inicio'),
            onTap: () {
              widget.onSelect(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.restaurant_menu),
            title: Text('Productos'),
            onTap: () {
              widget.onSelect(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Carrito'),
            onTap: () {
              widget.onSelect(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt),
            title: Text('Mis Órdenes'),
            onTap: () {
              widget.onSelect(3);
              Navigator.pop(context);
            },
          ),
          Divider(),
          if (_isAuthenticated)
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Cerrar Sesión'),
              onTap: () async {
                await _authService.logout();
                Navigator.pop(context);
                // Notificar al BLoC que se cerró sesión
                context.read<AuthBloc>().add(const SignOutRequested());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sesión cerrada')),
                );
              },
            )
          else
            ListTile(
              leading: Icon(Icons.login),
              title: Text('Iniciar Sesión'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sistema de login disponible próximamente')),
                );
              },
            ),
        ],
      ),
    );
  }
}
