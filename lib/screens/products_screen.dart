import 'package:flutter/material.dart';
import '../widgets/food_drawer.dart';
import '../services/product_service.dart';
import '../models/product.dart';

class ProductsScreen extends StatefulWidget {
  final Function(int) onSelect;
  final Function(Product) onAddToCart;
  const ProductsScreen({Key? key, required this.onSelect, required this.onAddToCart}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String search = '';
  bool showOnlyOffers = false;
  String selectedType = 'Todos';
  final ProductService _productService = ProductService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<String> _categories = ['Todos'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getAllProducts();
      
      // Extraer categorías únicas de los productos
      final categoriesSet = products
          .map((p) => p.category)
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList();
      categoriesSet.sort();
      final categories = ['Todos'] + categoriesSet;
      
      setState(() {
        _allProducts = products;
        _categories = categories;
        selectedType = 'Todos';
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products')),
      );
    }
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((p) {
      if (showOnlyOffers && !p.hasOffer) return false;
      if (selectedType != 'Todos' && p.category.toLowerCase() != selectedType.toLowerCase()) return false;
      if (search.isNotEmpty && !p.name.toLowerCase().contains(search.toLowerCase())) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Productos')),
      drawer: FoodDrawer(onSelect: widget.onSelect),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Buscar producto',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        search = value;
                        _applyFilters();
                      });
                    },
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          title: Text('Solo ofertas'),
                          value: showOnlyOffers,
                          onChanged: (v) {
                            setState(() {
                              showOnlyOffers = v;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Categoría: '),
                      Expanded(
                        child: Wrap(
                          children: _categories
                              .map((type) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: FilterChip(
                                      label: Text(type),
                                      selected: selectedType == type,
                                      labelStyle: TextStyle(
                                        color: selectedType == type ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      backgroundColor: Colors.grey[200],
                                      selectedColor: Color(0xFF0066CC),
                                      side: BorderSide(
                                        color: selectedType == type ? Color(0xFF0066CC) : Colors.grey[400]!,
                                      ),
                                      onSelected: (v) {
                                        setState(() {
                                          selectedType = type;
                                          _applyFilters();
                                        });
                                      },
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? Center(child: Text('No hay productos disponibles'))
                        : GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                            children: _filteredProducts
                                .map((product) => GestureDetector(
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
                                                height: 180,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Container(
                                                      height: 180,
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
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          product.name,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        if (product.isVegetarian)
                                                          Text(
                                                            'Vegetariano',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                      ],
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
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
