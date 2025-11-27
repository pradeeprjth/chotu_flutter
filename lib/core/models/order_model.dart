import 'user_model.dart';
import 'product_model.dart';

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String? customerName;
  final String? customerPhone;
  final List<OrderItem> items;
  final Address deliveryAddress;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double total;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? cancelReason;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.deliveryAddress,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    this.tax = 0,
    this.discount = 0,
    required this.total,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.cancelReason,
    this.estimatedDelivery,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canCancel =>
      status == 'PLACED' || status == 'CONFIRMED';

  bool get isActive =>
      status != 'DELIVERED' && status != 'CANCELLED';

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle user field - can be string ID or populated object
    String userId = '';
    String? customerName;
    String? customerPhone;
    final userField = json['userId'] ?? json['user'];
    if (userField is String) {
      userId = userField;
    } else if (userField is Map<String, dynamic>) {
      userId = userField['_id'] ?? userField['id'] ?? '';
      customerName = userField['name'];
      customerPhone = userField['phone'];
    }
    
    // Handle deliveryPartner field - can be string ID or populated object
    String? deliveryPartnerId;
    String? deliveryPartnerName;
    final partnerField = json['deliveryPartner'];
    if (partnerField is String) {
      deliveryPartnerId = partnerField;
      deliveryPartnerName = json['deliveryPartnerName'];
    } else if (partnerField is Map<String, dynamic>) {
      deliveryPartnerId = partnerField['_id'] ?? partnerField['id'];
      deliveryPartnerName = partnerField['name'];
    }
    
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      userId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: (json['items'] as List?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      deliveryAddress: json['deliveryAddress'] != null
          ? Address.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : Address(
              label: '',
              addressLine1: '',
              city: '',
              state: '',
              pincode: '',
            ),
      status: json['orderStatus'] ?? json['status'] ?? 'PLACED',
      paymentMethod: json['paymentMethod'] ?? 'COD',
      paymentStatus: json['paymentStatus'] ?? 'PENDING',
      subtotal: (json['subtotal'] ?? json['totalAmount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? json['deliveryCharges'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? json['totalAmount'] ?? 0).toDouble(),
      deliveryPartnerId: deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName,
      cancelReason: json['cancelReason'] ?? json['cancellationReason'],
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'userId': userId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'discount': discount,
      'total': total,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'cancelReason': cancelReason,
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String productId;
  final String name;
  final String unit;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;

  OrderItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    if (product != null && product is Map<String, dynamic>) {
      // If product is populated
      return OrderItem(
        productId: product['_id'] ?? product['id'] ?? json['productId'] ?? '',
        name: product['name'] ?? json['name'] ?? '',
        unit: product['unit'] ?? json['unit'] ?? '',
        price: (json['price'] ?? product['price'] ?? product['sellingPrice'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 1,
        total: (json['total'] ?? 0).toDouble(),
        imageUrl: product['images'] != null && (product['images'] as List).isNotEmpty
            ? product['images'][0]
            : json['imageUrl'],
      );
    }

    // Handle when product is just an ID string
    String productId = '';
    if (product is String) {
      productId = product;
    } else {
      productId = json['productId'] ?? '';
    }

    return OrderItem(
      productId: productId,
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'unit': unit,
      'price': price,
      'quantity': quantity,
      'total': total,
      'imageUrl': imageUrl,
    };
  }
}

// Order status constants
class OrderStatus {
  static const String placed = 'PLACED';
  static const String confirmed = 'CONFIRMED';
  static const String preparing = 'PREPARING';
  static const String outForDelivery = 'OUT_FOR_DELIVERY';
  static const String delivered = 'DELIVERED';
  static const String cancelled = 'CANCELLED';

  static String getDisplayText(String status) {
    switch (status) {
      case placed:
        return 'Order Placed';
      case confirmed:
        return 'Confirmed';
      case preparing:
        return 'Preparing';
      case outForDelivery:
        return 'Out for Delivery';
      case delivered:
        return 'Delivered';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  static List<String> get allStatuses => [
    placed,
    confirmed,
    preparing,
    outForDelivery,
    delivered,
    cancelled,
  ];
}
