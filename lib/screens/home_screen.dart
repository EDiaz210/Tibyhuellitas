import 'package:flutter/material.dart';
import '../widgets/food_drawer.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onSelect;
  final Function(Product) onAddToCart;
  const HomeScreen({Key? key, required this.onSelect, required this.onAddToCart}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'Pizza';
  final ProductService _productService = ProductService();
  List<Product> _featuredProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        // Mostrar solo los productos que están en oferta
        _featuredProducts = products.where((p) => p.hasOffer).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String promoText;
    String promoImg;
    Color promoColor;
    switch (selectedCategory) {
      case 'Pizza':
        promoText = '¡Pizza familiar gratis en tu primera orden! Prueba la mejor masa artesanal.';
        promoImg = 'https://cdn.tictuk.com/8d2f7265-71c2-bfdd-48f2-a2a7ae575b90/5a4ec404-3310-2c9a-d98f-a6e98ef59fd1.jpeg?a=b5016128-3cc6-82a5-cc2d-357834624aeb';
        promoColor = Colors.deepOrange[100]!;
        break;
      case 'Hamburguesa':
        promoText = 'Hamburguesa doble con papas y bebida por solo 9.99. ¡Sabor irresistible!';
        promoImg = 'https://tofuu.getjusto.com/orioneat-local/resized2/PGJ3c567zfmNs3LPm-300-x.webp';
        promoColor = Colors.amber[100]!;
        break;
      case 'Postres':
        promoText = '2x1 en helados artesanales todo el día. ¡Endulza tu tarde!';
        promoImg = 'https://cazaofertas.com.mx/wp-content/uploads/2019/03/Nutrisa-2x1.jpg';
        promoColor = Colors.purple[100]!;
        break;
      default:
        promoText = '¡Promociones especiales solo por hoy!';
        promoImg = 'https://images.milenio.com/Ewp1cGshblNar9DEw2xnUR7qz44=/942x532/uploads/media/2025/02/04/febrero-llega-promociones-descuentos-especiales.jpg';
        promoColor = Colors.deepPurple[100]!;
    }
    return Scaffold(
      appBar: AppBar(title: Text('TibyFood - Inicio')),
      drawer: FoodDrawer(onSelect: widget.onSelect),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Categorías', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                icon: Icon(
                  Icons.local_pizza,
                  color: selectedCategory == 'Pizza' ? Colors.white : Color(0xFF0066CC),
                ),
                label: Text('Pizza'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCategory == 'Pizza' ? Color(0xFF0066CC) : Colors.white,
                  foregroundColor: selectedCategory == 'Pizza' ? Colors.white : Colors.black,
                  side: BorderSide(color: Color(0xFF0066CC)),
                ),
                onPressed: () {
                  setState(() => selectedCategory = 'Pizza');
                  _loadFeaturedProducts();
                },
              ),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.lunch_dining,
                  color: selectedCategory == 'Hamburguesa' ? Colors.white : Color(0xFF0066CC),
                ),
                label: Text('Hamburguesa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCategory == 'Hamburguesa' ? Color(0xFF0066CC) : Colors.white,
                  foregroundColor: selectedCategory == 'Hamburguesa' ? Colors.white : Colors.black,
                  side: BorderSide(color: Color(0xFF0066CC)),
                ),
                onPressed: () {
                  setState(() => selectedCategory = 'Hamburguesa');
                  _loadFeaturedProducts();
                },
              ),
              ElevatedButton.icon(
                icon: Icon(
                  Icons.icecream,
                  color: selectedCategory == 'Postres' ? Colors.white : Color(0xFF0066CC),
                ),
                label: Text('Postres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedCategory == 'Postres' ? Color(0xFF0066CC) : Colors.white,
                  foregroundColor: selectedCategory == 'Postres' ? Colors.white : Colors.black,
                  side: BorderSide(color: Color(0xFF0066CC)),
                ),
                onPressed: () {
                  setState(() => selectedCategory = 'Postres');
                  _loadFeaturedProducts();
                },
              ),
            ],
          ),
          SizedBox(height: 32),
          Text('Promociones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: promoColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.network(
                    promoImg,
                    width: 140,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        width: 140,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image),
                      ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      promoText,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Text('Productos Destacados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _featuredProducts.isEmpty
                  ? Center(child: Text('No hay productos disponibles'))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _featuredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _featuredProducts[index];
                        return GestureDetector(
                          onTap: () => widget.onAddToCart(product),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    product.imageUrl,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.broken_image),
                                      ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (product.hasOffer)
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '\$${product.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      decoration: TextDecoration.lineThrough,
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${product.offerPrice?.toStringAsFixed(2) ?? product.price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            else
                                              Text(
                                                '\$${product.price.toStringAsFixed(2)}',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            Icon(Icons.add_circle, color: Color(0xFF0066CC), size: 20),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
