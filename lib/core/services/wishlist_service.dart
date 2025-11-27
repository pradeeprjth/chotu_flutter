import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/wishlist_model.dart';

class WishlistService {
  final ApiClient _apiClient;

  WishlistService(this._apiClient);

  Future<Wishlist> getWishlist() async {
    try {
      final response = await _apiClient.get('/wishlist');
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        return Wishlist.fromList(data);
      }
      return Wishlist.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<WishlistItem> addToWishlist(String productId) async {
    try {
      final response = await _apiClient.post('/wishlist/add', data: {
        'productId': productId,
      });
      final data = response.data['data'] ?? response.data;
      return WishlistItem.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    try {
      await _apiClient.post('/wishlist/remove', data: {
        'productId': productId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearWishlist() async {
    try {
      await _apiClient.delete('/wishlist');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isInWishlist(String productId) async {
    try {
      final response = await _apiClient.get('/wishlist/check/$productId');
      final data = response.data['data'] ?? response.data;
      return data['isInWishlist'] ?? false;
    } catch (e) {
      rethrow;
    }
  }
}

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WishlistService(apiClient);
});
