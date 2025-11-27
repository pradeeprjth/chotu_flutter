import 'package:json_annotation/json_annotation.dart';

// Commented out until we run build_runner
// part 'user_model.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'admin', 'delivery'
  final List<Address> addresses;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.addresses = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCustomer => role == 'customer';
  bool get isAdmin => role == 'admin';
  bool get isDelivery => role == 'delivery';

  Address? get defaultAddress =>
      addresses.isEmpty ? null : addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.first,
      );

  // Commented out until we run build_runner
  // factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  // Map<String, dynamic> toJson() => _$UserToJson(this);

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
      addresses: (json['addresses'] as List?)
          ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'addresses': addresses.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

@JsonSerializable()
class Address {
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;

  Address({
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2,
      if (landmark != null && landmark!.isNotEmpty) landmark,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }

  // factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  // Map<String, dynamic> toJson() => _$AddressToJson(this);

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      label: json['label'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      landmark: json['landmark'],
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }
}
