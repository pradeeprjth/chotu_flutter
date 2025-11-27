import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/cart_model.dart';

class CartService {
  final ApiClient _apiClient;

  CartService(this._apiClient);

  Future<Cart> getCart() async {
    try {
      final response = await _apiClient.get('/cart');
      final data = response.data['data'] ?? response.data;
      return Cart.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Cart> addToCart(String productId, int quantity) async {
    try {
      final response = await _apiClient.post('/cart/add', data: {
        'productId': productId,
        'quantity': quantity,
      });
      final data = response.data['data'] ?? response.data;
      return Cart.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Cart> updateCartItem(String productId, int quantity) async {
    try {
      final response = await _apiClient.put('/cart/update', data: {
        'productId': productId,
        'quantity': quantity,
      });
      final data = response.data['data'] ?? response.data;
      return Cart.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Cart> removeFromCart(String productId) async {
    try {
      final response = await _apiClient.delete('/cart/$productId');
      final data = response.data['data'] ?? response.data;
      return Cart.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _apiClient.delete('/cart');
    } catch (e) {
      rethrow;
    }
  }
}

final cartServiceProvider = Provider<CartService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CartService(apiClient);
});
