import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

// ==================== MODELS ====================

class DashboardMetrics {
  final RevenueMetrics revenue;
  final OrderMetrics orders;
  final CustomerMetrics customers;
  final InventoryMetrics inventory;
  final DeliveryPartnerMetrics deliveryPartners;
  final CatalogMetrics catalog;

  DashboardMetrics({
    required this.revenue,
    required this.orders,
    required this.customers,
    required this.inventory,
    required this.deliveryPartners,
    required this.catalog,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      revenue: RevenueMetrics.fromJson(json['revenue'] ?? {}),
      orders: OrderMetrics.fromJson(json['orders'] ?? {}),
      customers: CustomerMetrics.fromJson(json['customers'] ?? {}),
      inventory: InventoryMetrics.fromJson(json['inventory'] ?? {}),
      deliveryPartners: DeliveryPartnerMetrics.fromJson(json['deliveryPartners'] ?? {}),
      catalog: CatalogMetrics.fromJson(json['catalog'] ?? {}),
    );
  }
}

class RevenueMetrics {
  final double today;
  final double week;
  final double month;

  RevenueMetrics({required this.today, required this.week, required this.month});

  factory RevenueMetrics.fromJson(Map<String, dynamic> json) {
    return RevenueMetrics(
      today: (json['today'] ?? 0).toDouble(),
      week: (json['week'] ?? 0).toDouble(),
      month: (json['month'] ?? 0).toDouble(),
    );
  }
}

class OrderMetrics {
  final int total;
  final int pending;
  final int active;
  final int completed;
  final int cancelled;

  OrderMetrics({
    required this.total,
    required this.pending,
    required this.active,
    required this.completed,
    required this.cancelled,
  });

  factory OrderMetrics.fromJson(Map<String, dynamic> json) {
    return OrderMetrics(
      total: json['total'] ?? 0,
      pending: json['pending'] ?? 0,
      active: json['active'] ?? 0,
      completed: json['completed'] ?? 0,
      cancelled: json['cancelled'] ?? 0,
    );
  }
}

class CustomerMetrics {
  final int active;
  final int total;

  CustomerMetrics({required this.active, required this.total});

  factory CustomerMetrics.fromJson(Map<String, dynamic> json) {
    return CustomerMetrics(
      active: json['active'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class InventoryMetrics {
  final int lowStockAlerts;

  InventoryMetrics({required this.lowStockAlerts});

  factory InventoryMetrics.fromJson(Map<String, dynamic> json) {
    return InventoryMetrics(lowStockAlerts: json['lowStockAlerts'] ?? 0);
  }
}

class DeliveryPartnerMetrics {
  final int available;
  final int total;

  DeliveryPartnerMetrics({required this.available, required this.total});

  factory DeliveryPartnerMetrics.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerMetrics(
      available: json['available'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class CatalogMetrics {
  final int products;
  final int categories;

  CatalogMetrics({required this.products, required this.categories});

  factory CatalogMetrics.fromJson(Map<String, dynamic> json) {
    return CatalogMetrics(
      products: json['products'] ?? 0,
      categories: json['categories'] ?? 0,
    );
  }
}

class DashboardCharts {
  final List<RevenueDataPoint> revenueTrend;
  final List<CategoryOrderData> ordersByCategory;
  final List<PopularProductData> popularProducts;
  final List<OrderStatusData> ordersByStatus;

  DashboardCharts({
    required this.revenueTrend,
    required this.ordersByCategory,
    required this.popularProducts,
    required this.ordersByStatus,
  });

  factory DashboardCharts.fromJson(Map<String, dynamic> json) {
    return DashboardCharts(
      revenueTrend: (json['revenueTrend'] as List? ?? [])
          .map((e) => RevenueDataPoint.fromJson(e))
          .toList(),
      ordersByCategory: (json['ordersByCategory'] as List? ?? [])
          .map((e) => CategoryOrderData.fromJson(e))
          .toList(),
      popularProducts: (json['popularProducts'] as List? ?? [])
          .map((e) => PopularProductData.fromJson(e))
          .toList(),
      ordersByStatus: (json['ordersByStatus'] as List? ?? [])
          .map((e) => OrderStatusData.fromJson(e))
          .toList(),
    );
  }
}

class RevenueDataPoint {
  final String date;
  final double amount;

  RevenueDataPoint({required this.date, required this.amount});

  factory RevenueDataPoint.fromJson(Map<String, dynamic> json) {
    return RevenueDataPoint(
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class CategoryOrderData {
  final String categoryName;
  final int orderCount;
  final double percentage;

  CategoryOrderData({
    required this.categoryName,
    required this.orderCount,
    required this.percentage,
  });

  factory CategoryOrderData.fromJson(Map<String, dynamic> json) {
    return CategoryOrderData(
      categoryName: json['categoryName'] ?? '',
      orderCount: json['orderCount'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class PopularProductData {
  final String productName;
  final int orderCount;

  PopularProductData({required this.productName, required this.orderCount});

  factory PopularProductData.fromJson(Map<String, dynamic> json) {
    return PopularProductData(
      productName: json['productName'] ?? '',
      orderCount: json['orderCount'] ?? 0,
    );
  }
}

class OrderStatusData {
  final String status;
  final int count;
  final double percentage;

  OrderStatusData({
    required this.status,
    required this.count,
    required this.percentage,
  });

  factory OrderStatusData.fromJson(Map<String, dynamic> json) {
    return OrderStatusData(
      status: json['status'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class RecentOrderData {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String status;
  final DateTime createdAt;

  RecentOrderData({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory RecentOrderData.fromJson(Map<String, dynamic> json) {
    return RecentOrderData(
      id: json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? 'Unknown',
      customerPhone: json['customerPhone'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AdminOrder {
  final String id;
  final String orderNumber;
  final Map<String, dynamic> user;
  final List<dynamic> items;
  final double totalAmount;
  final Map<String, dynamic> deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final Map<String, dynamic>? deliveryPartner;
  final DateTime? deliveryAssignedAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.user,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    this.deliveryPartner,
    this.deliveryAssignedAt,
    this.deliveredAt,
    required this.createdAt,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    // Handle user which can be a Map or String (ID)
    Map<String, dynamic> userMap;
    final userData = json['user'];
    if (userData is Map<String, dynamic>) {
      userMap = userData;
    } else if (userData is String) {
      userMap = {'_id': userData};
    } else {
      userMap = {};
    }

    // Handle deliveryAddress which can be a Map or String (ID)
    Map<String, dynamic> addressMap;
    final addressData = json['deliveryAddress'];
    if (addressData is Map<String, dynamic>) {
      addressMap = addressData;
    } else if (addressData is String) {
      addressMap = {'_id': addressData};
    } else {
      addressMap = {};
    }

    // Handle deliveryPartner which can be a Map, String, or null
    Map<String, dynamic>? deliveryPartnerMap;
    final partnerData = json['deliveryPartner'];
    if (partnerData is Map<String, dynamic>) {
      deliveryPartnerMap = partnerData;
    } else if (partnerData is String) {
      deliveryPartnerMap = {'_id': partnerData};
    }

    // Handle items list
    List<dynamic> itemsList;
    final itemsData = json['items'];
    if (itemsData is List) {
      itemsList = itemsData;
    } else {
      itemsList = [];
    }

    return AdminOrder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      user: userMap,
      items: itemsList,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: addressMap,
      paymentMethod: json['paymentMethod']?.toString() ?? 'COD',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PENDING',
      orderStatus: json['orderStatus']?.toString() ?? 'PLACED',
      deliveryPartner: deliveryPartnerMap,
      deliveryAssignedAt: json['deliveryAssignedAt'] != null
          ? DateTime.tryParse(json['deliveryAssignedAt'].toString())
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'].toString())
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get customerName => user['name'] ?? 'Unknown';
  String get customerPhone => user['phone'] ?? '';
  String get customerEmail => user['email'] ?? '';
}

class AdminProduct {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic> category;
  final double price;
  final double mrp;
  final String unit;
  final List<String> images;
  final bool isActive;
  final Map<String, dynamic>? inventory;

  AdminProduct({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.mrp,
    required this.unit,
    required this.images,
    required this.isActive,
    this.inventory,
  });

  factory AdminProduct.fromJson(Map<String, dynamic> json) {
    // Handle category which can be either a String (ID) or a Map (populated object)
    Map<String, dynamic> categoryMap;
    final categoryData = json['category'];
    if (categoryData is Map<String, dynamic>) {
      categoryMap = categoryData;
    } else if (categoryData is String) {
      categoryMap = {'_id': categoryData, 'id': categoryData, 'name': ''};
    } else {
      categoryMap = {};
    }

    // Handle images which can be null, a List, or other types
    List<String> imagesList;
    final imagesData = json['images'];
    if (imagesData is List) {
      imagesList = imagesData.map((e) => e.toString()).toList();
    } else {
      imagesList = [];
    }

    // Handle inventory which can be a Map or null
    Map<String, dynamic>? inventoryMap;
    final inventoryData = json['inventory'];
    if (inventoryData is Map<String, dynamic>) {
      inventoryMap = inventoryData;
    }

    return AdminProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      category: categoryMap,
      price: (json['price'] ?? json['sellingPrice'] ?? 0).toDouble(),
      mrp: (json['mrp'] ?? 0).toDouble(),
      unit: json['unit']?.toString() ?? '',
      images: imagesList,
      isActive: json['isActive'] ?? true,
      inventory: inventoryMap,
    );
  }

  String get categoryName => category['name'] ?? '';
  int get stockQuantity => inventory?['quantity'] ?? 0;
  int get stockAvailable => inventory?['available'] ?? 0;
}

class AdminInventoryItem {
  final String id;
  final Map<String, dynamic> product;
  final int quantity;
  final int reserved;
  final int available;
  final DateTime? lastRestocked;

  AdminInventoryItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.reserved,
    required this.available,
    this.lastRestocked,
  });

  factory AdminInventoryItem.fromJson(Map<String, dynamic> json) {
    // Handle product which can be a Map or String (ID)
    Map<String, dynamic> productMap;
    final productData = json['product'];
    if (productData is Map<String, dynamic>) {
      productMap = productData;
    } else if (productData is String) {
      productMap = {'_id': productData};
    } else {
      productMap = {};
    }

    return AdminInventoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      product: productMap,
      quantity: (json['quantity'] ?? 0) is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      reserved: (json['reserved'] ?? 0) is int ? json['reserved'] : int.tryParse(json['reserved']?.toString() ?? '0') ?? 0,
      available: (json['available'] ?? 0) is int ? json['available'] : int.tryParse(json['available']?.toString() ?? '0') ?? 0,
      lastRestocked: json['lastRestocked'] != null
          ? DateTime.tryParse(json['lastRestocked'].toString())
          : null,
    );
  }

  String get productName => product['name'] ?? '';
  String get productUnit => product['unit'] ?? '';
}

class AdminDeliveryPartner {
  final String id;
  final Map<String, dynamic> user;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final bool isAvailable;
  final int activeOrders;
  final int totalDeliveries;
  final double rating;

  AdminDeliveryPartner({
    required this.id,
    required this.user,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.isAvailable,
    required this.activeOrders,
    required this.totalDeliveries,
    required this.rating,
  });

  factory AdminDeliveryPartner.fromJson(Map<String, dynamic> json) {
    // Handle user which can be a Map or String (ID)
    Map<String, dynamic> userMap;
    final userData = json['user'];
    if (userData is Map<String, dynamic>) {
      userMap = userData;
    } else if (userData is String) {
      userMap = {'_id': userData};
    } else {
      userMap = {};
    }

    return AdminDeliveryPartner(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      user: userMap,
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      isAvailable: json['isAvailable'] ?? false,
      activeOrders: (json['activeOrders'] ?? 0) is int ? json['activeOrders'] : int.tryParse(json['activeOrders']?.toString() ?? '0') ?? 0,
      totalDeliveries: (json['totalDeliveries'] ?? 0) is int ? json['totalDeliveries'] : int.tryParse(json['totalDeliveries']?.toString() ?? '0') ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }

  String get name => user['name'] ?? '';
  String get phone => user['phone'] ?? '';
  String get email => user['email'] ?? '';
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }
}

// ==================== SERVICE ====================

class AdminService {
  final ApiClient _apiClient;

  AdminService(this._apiClient);

  // ==================== DASHBOARD ====================

  Future<DashboardMetrics> getDashboardMetrics() async {
    final response = await _apiClient.get('/admin/dashboard');
    final data = response.data['data'];
    return DashboardMetrics.fromJson(data);
  }

  Future<DashboardCharts> getDashboardCharts({String range = 'week'}) async {
    final response = await _apiClient.get('/admin/dashboard/charts', queryParameters: {
      'range': range,
    });
    final data = response.data['data'];
    return DashboardCharts.fromJson(data);
  }

  Future<List<RecentOrderData>> getRecentOrders({int limit = 10}) async {
    final response = await _apiClient.get('/admin/dashboard/recent-orders', queryParameters: {
      'limit': limit,
    });
    final data = response.data['data'] as List;
    return data.map((e) => RecentOrderData.fromJson(e)).toList();
  }

  // ==================== ORDERS ====================

  Future<({List<AdminOrder> orders, Pagination pagination})> getOrders({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    final response = await _apiClient.get('/admin/orders', queryParameters: {
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    });
    final data = response.data['data'] as List;
    final pagination = Pagination.fromJson(response.data['pagination'] ?? {});
    return (
      orders: data.map((e) => AdminOrder.fromJson(e)).toList(),
      pagination: pagination,
    );
  }

  Future<AdminOrder> getOrderById(String orderId) async {
    final response = await _apiClient.get('/admin/orders/$orderId');
    final data = response.data['data'];
    return AdminOrder.fromJson(data);
  }

  Future<void> updateOrderStatus(String orderId, String status, {String? note}) async {
    await _apiClient.patch('/admin/orders/$orderId/status', data: {
      'status': status,
      if (note != null) 'note': note,
    });
  }

  Future<void> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    await _apiClient.post('/admin/orders/$orderId/assign-delivery', data: {
      'deliveryPartnerId': deliveryPartnerId,
    });
  }

  // ==================== PRODUCTS ====================

  Future<({List<AdminProduct> products, Pagination pagination})> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get('/admin/products', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      if (isActive != null) 'isActive': isActive.toString(),
      'page': page,
      'limit': limit,
    });
    final data = response.data['data'] as List;
    final pagination = Pagination.fromJson(response.data['pagination'] ?? {});
    return (
      products: data.map((e) => AdminProduct.fromJson(e)).toList(),
      pagination: pagination,
    );
  }

  Future<AdminProduct> createProduct({
    required String name,
    String? description,
    required String category,
    required double price,
    required double mrp,
    required String unit,
    List<String>? images,
    int? initialStock,
  }) async {
    final response = await _apiClient.post('/admin/products', data: {
      'name': name,
      if (description != null) 'description': description,
      'category': category,
      'price': price,
      'mrp': mrp,
      'unit': unit,
      if (images != null) 'images': images,
      if (initialStock != null) 'initialStock': initialStock,
    });
    final data = response.data['data'];
    return AdminProduct.fromJson(data);
  }

  Future<AdminProduct> updateProduct(String productId, Map<String, dynamic> updates) async {
    final response = await _apiClient.patch('/admin/products/$productId', data: updates);
    final data = response.data['data'];
    return AdminProduct.fromJson(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _apiClient.delete('/admin/products/$productId');
  }

  // ==================== INVENTORY ====================

  Future<({List<AdminInventoryItem> inventory, Pagination pagination})> getInventory({
    bool lowStockOnly = false,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get('/admin/inventory', queryParameters: {
      'lowStockOnly': lowStockOnly.toString(),
      'page': page,
      'limit': limit,
    });
    final data = response.data['data'] as List;
    final pagination = Pagination.fromJson(response.data['pagination'] ?? {});
    return (
      inventory: data.map((e) => AdminInventoryItem.fromJson(e)).toList(),
      pagination: pagination,
    );
  }

  Future<void> updateInventory(String productId, {int? quantity, int? lowStockThreshold}) async {
    await _apiClient.patch('/admin/inventory/$productId', data: {
      if (quantity != null) 'quantity': quantity,
      if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
    });
  }

  // ==================== DELIVERY PARTNERS ====================

  Future<({List<AdminDeliveryPartner> partners, Pagination pagination})> getDeliveryPartners({
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get('/admin/delivery-partners', queryParameters: {
      if (isAvailable != null) 'isAvailable': isAvailable.toString(),
      'page': page,
      'limit': limit,
    });
    final data = response.data['data'] as List;
    final pagination = Pagination.fromJson(response.data['pagination'] ?? {});
    return (
      partners: data.map((e) => AdminDeliveryPartner.fromJson(e)).toList(),
      pagination: pagination,
    );
  }

  Future<AdminDeliveryPartner> createDeliveryPartner({
    required String userId,
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
  }) async {
    final response = await _apiClient.post('/admin/delivery-partners', data: {
      'userId': userId,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
    });
    final data = response.data['data'];
    return AdminDeliveryPartner.fromJson(data);
  }

  Future<AdminDeliveryPartner> updateDeliveryPartner(
    String partnerId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _apiClient.patch('/admin/delivery-partners/$partnerId', data: updates);
    final data = response.data['data'];
    return AdminDeliveryPartner.fromJson(data);
  }
}

// ==================== PROVIDER ====================

final adminServiceProvider = Provider<AdminService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminService(apiClient);
});
