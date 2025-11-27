import 'product_model.dart';

class CartItem {
  final String productId;
  final Product product;
  final int quantity;
  final double priceAtAdd;

  CartItem({
    required this.productId,
    required this.product,
    required this.quantity,
    required this.priceAtAdd,
  });

  double get itemTotal => priceAtAdd * quantity;

  CartItem copyWith({
    String? productId,
    Product? product,
    int? quantity,
    double? priceAtAdd,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      priceAtAdd: priceAtAdd ?? this.priceAtAdd,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Handle product field - it can be either a product ID string or a populated product object
    String productId = '';
    Product? productData;
    
    final productField = json['product'];
    if (productField is String) {
      productId = productField;
      // If we only have ID, create minimal product object
      productData = Product.fromJson({
        '_id': productField,
        'name': json['name'] ?? '',
        'unit': json['unit'] ?? '',
        'price': json['price'] ?? 0,
        'mrp': json['price'] ?? 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else if (productField is Map<String, dynamic>) {
      productData = Product.fromJson(productField);
      productId = productData.id;
    } else {
      // Fallback
      productId = json['productId'] ?? '';
      productData = Product.fromJson(json['product'] ?? {});
    }
    
    return CartItem(
      productId: productId,
      product: productData,
      quantity: json['quantity'] ?? 1,
      priceAtAdd: (json['priceAtAdd'] ?? json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'product': product.toJson(),
      'quantity': quantity,
      'priceAtAdd': priceAtAdd,
    };
  }
}

class Cart {
  final String? id;
  final String? userId;
  final List<CartItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cart({
    this.id,
    this.userId,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.itemTotal);

  bool get isEmpty => items.isEmpty;

  /// Calculate delivery charges based on order subtotal
  /// - 30 for orders >= 1000
  /// - 40 for orders >= 500 and < 1000
  /// - 50 for orders < 500
  double get deliveryCharges {
    if (subtotal >= 1000) {
      return 30;
    } else if (subtotal >= 500) {
      return 40;
    } else {
      return 50;
    }
  }

  /// Total amount including delivery charges
  double get total => subtotal + deliveryCharges;

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      items: (json['items'] as List?)
          ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'items': items.map((e) => e.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
