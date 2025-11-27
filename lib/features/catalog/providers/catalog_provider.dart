import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/catalog_service.dart';
import '../../../core/utils/error_handler.dart';

// Categories state
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CatalogService _catalogService;

  CategoriesNotifier(this._catalogService) : super(CategoriesState());

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _catalogService.getCategories();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  final catalogService = ref.watch(catalogServiceProvider);
  return CategoriesNotifier(catalogService);
});

// Products state
class ProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class ProductsNotifier extends StateNotifier<ProductsState> {
  final CatalogService _catalogService;

  ProductsNotifier(this._catalogService) : super(ProductsState());

  Future<void> loadProducts({String? categoryId, bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(products: [], currentPage: 1, hasMore: true);
    }

    if (state.isLoading || (!state.hasMore && !refresh)) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _catalogService.getProducts(
        categoryId: categoryId,
        page: refresh ? 1 : state.currentPage,
      );

      state = state.copyWith(
        products: refresh ? products : [...state.products, ...products],
        isLoading: false,
        hasMore: products.length >= 20,
        currentPage: refresh ? 2 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  Future<void> searchProducts(String query) async {
    state = state.copyWith(isLoading: true, error: null, products: []);

    try {
      final products = await _catalogService.searchProducts(query);
      state = state.copyWith(
        products: products,
        isLoading: false,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  final catalogService = ref.watch(catalogServiceProvider);
  return ProductsNotifier(catalogService);
});

// Single product provider
final productProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final catalogService = ref.watch(catalogServiceProvider);
  try {
    return await catalogService.getProductById(id);
  } catch (e) {
    return null;
  }
});
