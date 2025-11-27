class Product {
  final String id;
  final String name;
  final String? description;
  final String categoryId;
  final String? brand;
  final String unit;
  final double mrp;
  final double sellingPrice;
  final double taxPercent;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.brand,
    required this.unit,
    required this.mrp,
    required this.sellingPrice,
    this.taxPercent = 0,
    this.images = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String? get primaryImageUrl => images.isNotEmpty ? images.first : null;

  double get discount => mrp > sellingPrice ? ((mrp - sellingPrice) / mrp * 100) : 0;

  bool get hasDiscount => mrp > sellingPrice;

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle category field - it can be either a string ID or a populated object
    String categoryId = '';
    final categoryField = json['categoryId'] ?? json['category'];
    if (categoryField == null) {
      categoryId = '';
    } else if (categoryField is String) {
      categoryId = categoryField;
    } else if (categoryField is Map<String, dynamic>) {
      categoryId = (categoryField['_id'] ?? categoryField['id'] ?? '').toString();
    } else {
      // If it's some other type, try converting to string
      categoryId = categoryField.toString();
    }
    
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      categoryId: categoryId,
      brand: json['brand']?.toString(),
      unit: (json['unit'] ?? '').toString(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? json['price'] ?? 0).toDouble(),
      taxPercent: (json['taxPercent'] ?? 0).toDouble(),
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'brand': brand,
      'unit': unit,
      'mrp': mrp,
      'sellingPrice': sellingPrice,
      'taxPercent': taxPercent,
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
