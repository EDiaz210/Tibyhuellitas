import 'package:intl/intl.dart';

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status; // pending, confirmed, delivered, cancelled
  final String deliveryAddress;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    required this.phoneNumber,
    required this.createdAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['items'] != null) {
      if (json['items'] is String) {
        // Si es una cadena JSON, parsearla
        try {
          final parsed = jsonDecode(json['items']);
          items = (parsed as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          items = [];
        }
      } else if (json['items'] is List) {
        items = (json['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    return Order(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      items: items,
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'total_price': totalPrice,
      'status': status,
      'delivery_address': deliveryAddress,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalPrice,
    String? status,
    String? deliveryAddress,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

// Función auxiliar para decodificar JSON
dynamic jsonDecode(String source) {
  return _parseJson(source);
}

dynamic _parseJson(String source) {
  // Implementación simple del parser JSON
  try {
    return _parseValue(source, 0)[0];
  } catch (e) {
    return null;
  }
}

List<dynamic> _parseValue(String source, int index) {
  while (index < source.length && source[index] == ' ') index++;

  if (index >= source.length) throw 'Unexpected end of input';

  switch (source[index]) {
    case 'n':
      return [null, index + 4];
    case 't':
      return [true, index + 4];
    case 'f':
      return [false, index + 5];
    case '"':
      return _parseString(source, index);
    case '[':
      return _parseList(source, index);
    case '{':
      return _parseObject(source, index);
    case '-':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      return _parseNumber(source, index);
    default:
      throw 'Unexpected character: ${source[index]}';
  }
}

List<dynamic> _parseString(String source, int index) {
  index++; // Skip opening quote
  int start = index;
  while (index < source.length && source[index] != '"') {
    if (source[index] == '\\') index++;
    index++;
  }
  if (index >= source.length) throw 'Unterminated string';
  return [source.substring(start, index), index + 1];
}

List<dynamic> _parseNumber(String source, int index) {
  int start = index;
  if (source[index] == '-') index++;
  while (index < source.length && source[index].codeUnitAt(0) >= '0'.codeUnitAt(0) && source[index].codeUnitAt(0) <= '9'.codeUnitAt(0)) {
    index++;
  }
  if (index < source.length && source[index] == '.') {
    index++;
    while (index < source.length && source[index].codeUnitAt(0) >= '0'.codeUnitAt(0) && source[index].codeUnitAt(0) <= '9'.codeUnitAt(0)) {
      index++;
    }
  }
  return [num.parse(source.substring(start, index)), index];
}

List<dynamic> _parseList(String source, int index) {
  List<dynamic> list = [];
  index++; // Skip [
  while (index < source.length && source[index] != ']') {
    while (index < source.length && source[index] == ' ') index++;
    if (source[index] == ']') break;
    var result = _parseValue(source, index);
    list.add(result[0]);
    index = result[1];
    while (index < source.length && source[index] == ' ') index++;
    if (index < source.length && source[index] == ',') {
      index++;
    }
  }
  if (index >= source.length) throw 'Unterminated array';
  return [list, index + 1];
}

List<dynamic> _parseObject(String source, int index) {
  Map<String, dynamic> object = {};
  index++; // Skip {
  while (index < source.length && source[index] != '}') {
    while (index < source.length && source[index] == ' ') index++;
    if (source[index] == '}') break;
    var keyResult = _parseString(source, index);
    String key = keyResult[0];
    index = keyResult[1];
    while (index < source.length && source[index] == ' ') index++;
    if (index >= source.length || source[index] != ':') throw 'Expected colon';
    index++; // Skip :
    var valueResult = _parseValue(source, index);
    object[key] = valueResult[0];
    index = valueResult[1];
    while (index < source.length && source[index] == ' ') index++;
    if (index < source.length && source[index] == ',') {
      index++;
    }
  }
  if (index >= source.length) throw 'Unterminated object';
  return [object, index + 1];
}
