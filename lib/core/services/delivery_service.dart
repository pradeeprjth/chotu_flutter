import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/delivery_partner_model.dart';
import '../models/order_model.dart';

class DeliveryService {
  final ApiClient _apiClient;

  DeliveryService(this._apiClient);

  /// Get delivery partner profile with stats
  Future<DeliveryPartnerProfile> getProfile() async {
    try {
      final response = await _apiClient.get('/delivery/profile');
      return DeliveryPartnerProfile.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Create delivery partner profile
  Future<DeliveryPartnerProfile> createProfile({
    required String vehicleType,
    required String vehicleNumber,
    required String licenseNumber,
  }) async {
    try {
      final response = await _apiClient.post('/delivery/profile', data: {
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'licenseNumber': licenseNumber,
      });
      return DeliveryPartnerProfile.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update delivery partner profile (including availability)
  Future<DeliveryPartnerProfile> updateProfile({
    String? vehicleType,
    String? vehicleNumber,
    String? licenseNumber,
    bool? isAvailable,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (vehicleType != null) data['vehicleType'] = vehicleType;
      if (vehicleNumber != null) data['vehicleNumber'] = vehicleNumber;
      if (licenseNumber != null) data['licenseNumber'] = licenseNumber;
      if (isAvailable != null) data['isAvailable'] = isAvailable;

      final response = await _apiClient.put('/delivery/profile', data: data);
      return DeliveryPartnerProfile.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle availability status
  Future<DeliveryPartnerProfile> toggleAvailability(bool isAvailable) async {
    return updateProfile(isAvailable: isAvailable);
  }

  /// Get assigned deliveries
  Future<List<Order>> getMyDeliveries({String? status}) async {
    try {
      String url = '/delivery/my-deliveries';
      if (status != null && status.isNotEmpty) {
        url += '?status=$status';
      }

      final response = await _apiClient.get(url);

      final data = response.data;
      List<dynamic> ordersList;

      if (data is Map && data['data'] != null) {
        ordersList = data['data'] as List;
      } else if (data is List) {
        ordersList = data;
      } else {
        ordersList = [];
      }

      return ordersList
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Update delivery status (OUT_FOR_DELIVERY or DELIVERED)
  Future<Order> updateDeliveryStatus(String orderId, String status) async {
    try {
      final response = await _apiClient.put('/delivery/status', data: {
        'orderId': orderId,
        'status': status,
      });
      return Order.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for DeliveryService
final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeliveryService(apiClient);
});
