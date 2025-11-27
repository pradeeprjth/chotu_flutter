import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class CatalogService {
  final ApiClient _apiClient;

  CatalogService(this._apiClient);

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      final responseData = response.data['data'] ?? response.data;
      final List data = responseData is List ? responseData : responseData['categories'] ?? [];
      return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> getCategoryById(String id) async {
    try {
      final response = await _apiClient.get('/categories/$id');
      final data = response.data['data'] ?? response.data;
      return Category.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (categoryId != null) queryParams['category'] = categoryId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get('/products', queryParameters: queryParams);
      final responseData = response.data['data'] ?? response.data;
      final List data = responseData is List ? responseData : responseData['products'] ?? [];
      return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _apiClient.get('/products/$id');
      final data = response.data['data'] ?? response.data;
      return Product.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await _apiClient.get('/products', queryParameters: {
        'search': query,
      });
      final responseData = response.data['data'] ?? response.data;
      final List data = responseData is List ? responseData : responseData['products'] ?? [];
      return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> advancedSearch({
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (categoryId != null && categoryId.isNotEmpty) queryParams['category'] = categoryId;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final response = await _apiClient.get('/products', queryParameters: queryParams);
      final responseData = response.data['data'] ?? response.data;
      final List data = responseData is List ? responseData : responseData['products'] ?? [];
      return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

final catalogServiceProvider = Provider<CatalogService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CatalogService(apiClient);
});
