/// Delivery partner stats model
class DeliveryStats {
  final int todayDeliveries;
  final double todayEarnings;
  final int weekDeliveries;
  final double weekEarnings;
  final int totalDeliveries;
  final double totalEarnings;

  DeliveryStats({
    required this.todayDeliveries,
    required this.todayEarnings,
    required this.weekDeliveries,
    required this.weekEarnings,
    required this.totalDeliveries,
    required this.totalEarnings,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      todayDeliveries: json['todayDeliveries'] ?? 0,
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      weekDeliveries: json['weekDeliveries'] ?? 0,
      weekEarnings: (json['weekEarnings'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
    );
  }

  factory DeliveryStats.empty() {
    return DeliveryStats(
      todayDeliveries: 0,
      todayEarnings: 0,
      weekDeliveries: 0,
      weekEarnings: 0,
      totalDeliveries: 0,
      totalEarnings: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayDeliveries': todayDeliveries,
      'todayEarnings': todayEarnings,
      'weekDeliveries': weekDeliveries,
      'weekEarnings': weekEarnings,
      'totalDeliveries': totalDeliveries,
      'totalEarnings': totalEarnings,
    };
  }
}

/// Delivery partner profile model
class DeliveryPartnerProfile {
  final String id;
  final String visibleUserId;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final bool isAvailable;
  final int activeOrders;
  final double rating;
  final DeliveryStats stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryPartnerProfile({
    required this.id,
    required this.visibleUserId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.isAvailable,
    required this.activeOrders,
    required this.rating,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryPartnerProfile.fromJson(Map<String, dynamic> json) {
    // Handle user field which can be populated or just an ID
    String visibleUserId = '';
    String name = '';
    String email = '';
    String phone = '';

    final userField = json['user'];
    if (userField is String) {
      visibleUserId = userField;
    } else if (userField is Map<String, dynamic>) {
      visibleUserId = userField['_id'] ?? userField['id'] ?? '';
      name = userField['name'] ?? '';
      email = userField['email'] ?? '';
      phone = userField['phone'] ?? '';
    }

    return DeliveryPartnerProfile(
      id: json['_id'] ?? json['id'] ?? '',
      visibleUserId: visibleUserId,
      name: name,
      email: email,
      phone: phone,
      vehicleType: json['vehicleType'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      activeOrders: json['activeOrders'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      stats: json['stats'] != null
          ? DeliveryStats.fromJson(json['stats'])
          : DeliveryStats.empty(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': visibleUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'licenseNumber': licenseNumber,
      'isAvailable': isAvailable,
      'activeOrders': activeOrders,
      'rating': rating,
      'stats': stats.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DeliveryPartnerProfile copyWith({
    String? id,
    String? visibleUserId,
    String? name,
    String? email,
    String? phone,
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    bool? isAvailable,
    int? activeOrders,
    double? rating,
    DeliveryStats? stats,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryPartnerProfile(
      id: id ?? this.id,
      visibleUserId: visibleUserId ?? this.visibleUserId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isAvailable: isAvailable ?? this.isAvailable,
      activeOrders: activeOrders ?? this.activeOrders,
      rating: rating ?? this.rating,
      stats: stats ?? this.stats,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
