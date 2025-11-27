import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/order_model.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService(this._apiClient);

  // Create order from cart
  Future<Order> createOrder({
    required int addressIndex,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiClient.post('/orders', data: {
        'addressIndex': addressIndex,
        'paymentMethod': paymentMethod,
      });

      return Order.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get customer's orders
  Future<List<Order>> getMyOrders({String? status}) async {
    try {
      String url = '/orders/my-orders';
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

  // Get order by ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _apiClient.get('/orders/$orderId');
      return Order.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Cancel order
  Future<Order> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await _apiClient.post('/orders/$orderId/cancel', data: {
        'reason': reason ?? 'Cancelled by user',
      });

      return Order.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get all orders (Admin/Delivery)
  Future<List<Order>> getAllOrders({String? status, int? limit}) async {
    try {
      String url = '/orders';
      final params = <String>[];

      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
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

  // Update order status (Admin/Delivery)
  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiClient.put('/orders/$orderId/status', data: {
        'status': status,
      });

      return Order.fromJson(response.data['data'] ?? response.data);
    } catch (e) {
      rethrow;
    }
  }

  // Get delivery partner's assigned orders
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

  // Update delivery status (Delivery partner)
  Future<void> updateDeliveryStatus(String orderId, String status) async {
    try {
      await _apiClient.put('/delivery/status', data: {
        'orderId': orderId,
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Assign delivery partner (Admin)
  Future<void> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    try {
      await _apiClient.post('/delivery/assign', data: {
        'orderId': orderId,
        'deliveryPartnerId': deliveryPartnerId,
      });
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for OrderService
final orderServiceProvider = Provider<OrderService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderService(apiClient);
});
