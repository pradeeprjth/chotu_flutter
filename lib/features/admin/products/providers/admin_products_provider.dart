import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

/// Admin products state
class AdminProductsState {
  final bool isLoading;
  final String? error;
  final List<AdminProduct> products;
  final Pagination? pagination;
  final String? categoryFilter;
  final String searchQuery;
  final bool? activeFilter;

  AdminProductsState({
    this.isLoading = false,
    this.error,
    this.products = const [],
    this.pagination,
    this.categoryFilter,
    this.searchQuery = '',
    this.activeFilter,
  });

  AdminProductsState copyWith({
    bool? isLoading,
    String? error,
    List<AdminProduct>? products,
    Pagination? pagination,
    String? categoryFilter,
    String? searchQuery,
    bool? activeFilter,
    bool clearError = false,
    bool clearCategoryFilter = false,
    bool clearActiveFilter = false,
  }) {
    return AdminProductsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      products: products ?? this.products,
      pagination: pagination ?? this.pagination,
      categoryFilter: clearCategoryFilter ? null : categoryFilter ?? this.categoryFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: clearActiveFilter ? null : activeFilter ?? this.activeFilter,
    );
  }
}

/// Admin products notifier
class AdminProductsNotifier extends StateNotifier<AdminProductsState> {
  final AdminService _adminService;

  AdminProductsNotifier(this._adminService) : super(AdminProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _adminService.getProducts(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        categoryId: state.categoryFilter,
        isActive: state.activeFilter,
        page: 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        products: result.products,
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading) return;
    if (state.pagination == null) return;
    if (state.pagination!.page >= state.pagination!.totalPages) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _adminService.getProducts(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        categoryId: state.categoryFilter,
        isActive: state.activeFilter,
        page: state.pagination!.page + 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        products: [...state.products, ...result.products],
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void filterByCategory(String? categoryId) {
    if (categoryId == state.categoryFilter) return;

    state = state.copyWith(
      categoryFilter: categoryId,
      clearCategoryFilter: categoryId == null,
      products: [],
      pagination: null,
    );
    loadProducts();
  }

  void filterByActive(bool? isActive) {
    if (isActive == state.activeFilter) return;

    state = state.copyWith(
      activeFilter: isActive,
      clearActiveFilter: isActive == null,
      products: [],
      pagination: null,
    );
    loadProducts();
  }

  void search(String query) {
    if (query == state.searchQuery) return;

    state = state.copyWith(
      searchQuery: query,
      products: [],
      pagination: null,
    );
    loadProducts();
  }

  Future<AdminProduct?> createProduct({
    required String name,
    String? description,
    required String category,
    required double price,
    required double mrp,
    required String unit,
    List<String>? images,
    int? initialStock,
  }) async {
    try {
      final product = await _adminService.createProduct(
        name: name,
        description: description,
        category: category,
        price: price,
        mrp: mrp,
        unit: unit,
        images: images,
        initialStock: initialStock,
      );

      // Refresh the list
      loadProducts(refresh: true);
      return product;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return null;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _adminService.updateProduct(productId, updates);
      loadProducts(refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _adminService.deleteProduct(productId);

      // Remove from local list
      final updatedProducts = state.products.where((p) => p.id != productId).toList();
      state = state.copyWith(products: updatedProducts);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

/// Admin products provider instance
final adminProductsProvider = StateNotifierProvider<AdminProductsNotifier, AdminProductsState>(
  (ref) {
    final adminService = ref.watch(adminServiceProvider);
    return AdminProductsNotifier(adminService);
  },
);
