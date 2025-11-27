class Category {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? parentId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      parentId: json['parentId']?.toString(),
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
