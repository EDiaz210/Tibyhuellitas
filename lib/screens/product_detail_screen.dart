import 'package:flutter/material.dart';
import '../widgets/food_drawer.dart';

class ProductDetailScreen extends StatelessWidget {
  final Function(int) onSelect;
  final String name;
  final String image;
  final double price;
  const ProductDetailScreen({Key? key, required this.onSelect, required this.name, required this.image, required this.price}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      drawer: FoodDrawer(onSelect: onSelect),
      body: Stack(
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('Descripción del producto aquí.', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 24),
                    Row(
                      children: [
                      Text('\$${price.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Spacer(),
                            ElevatedButton(
                              onPressed: null, // Acción deshabilitada temporalmente
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0066CC),
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Agregar al carrito'),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
