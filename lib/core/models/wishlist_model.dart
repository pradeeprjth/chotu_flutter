import 'product_model.dart';

class WishlistItem {
  final String id;
  final String productId;
  final Product? product;
  final DateTime addedAt;

  WishlistItem({
    required this.id,
    required this.productId,
    this.product,
    required this.addedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    // Handle product field - it can be either a string ID or a populated object
    String productId = '';
    Product? product;

    final productField = json['productId'] ?? json['product'];
    if (productField is String) {
      productId = productField;
    } else if (productField is Map<String, dynamic>) {
      productId = (productField['_id'] ?? productField['id'] ?? '').toString();
      product = Product.fromJson(productField);
    }

    return WishlistItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      productId: productId,
      product: product,
      addedAt: DateTime.parse(
        json['addedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}

class Wishlist {
  final List<WishlistItem> items;

  Wishlist({this.items = const []});

  int get itemCount => items.length;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool containsProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  Set<String> get productIds => items.map((item) => item.productId).toSet();

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return Wishlist(
      items: itemsList.map((item) => WishlistItem.fromJson(item)).toList(),
    );
  }

  factory Wishlist.fromList(List<dynamic> list) {
    return Wishlist(
      items: list.map((item) => WishlistItem.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Wishlist copyWith({List<WishlistItem>? items}) {
    return Wishlist(items: items ?? this.items);
  }
}
