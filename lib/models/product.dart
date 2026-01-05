class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isVegetarian;
  final bool hasOffer;
  final double? offerPrice;
  final int quantity;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isVegetarian,
    required this.hasOffer,
    this.offerPrice,
    this.quantity = 1,
    required this.createdAt,
  });

  // Convertir de JSON a Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      category: json['category'] ?? '',
      isVegetarian: json['is_vegetarian'] ?? false,
      hasOffer: json['has_offer'] ?? false,
      offerPrice: json['offer_price'] != null ? (json['offer_price'] as num).toDouble() : null,
      quantity: json['quantity'] ?? 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  // Convertir de Product a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_vegetarian': isVegetarian,
      'has_offer': hasOffer,
      'offer_price': offerPrice,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copiar con cambios
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isVegetarian,
    bool? hasOffer,
    double? offerPrice,
    int? quantity,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      hasOffer: hasOffer ?? this.hasOffer,
      offerPrice: offerPrice ?? this.offerPrice,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double getEffectivePrice() => hasOffer && offerPrice != null ? offerPrice! : price;
}
