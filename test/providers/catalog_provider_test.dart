import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:chotu_app/features/catalog/providers/catalog_provider.dart';
import 'package:chotu_app/core/services/catalog_service.dart';
import 'package:chotu_app/core/models/category_model.dart';
import 'package:chotu_app/core/models/product_model.dart';

// Mock classes
class MockCatalogService extends Mock implements CatalogService {}

void main() {
  late MockCatalogService mockCatalogService;
  late ProviderContainer container;

  // Test data
  final testCategories = [
    Category(
      id: 'cat-1',
      name: 'Fruits',
      slug: 'fruits',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Category(
      id: 'cat-2',
      name: 'Vegetables',
      slug: 'vegetables',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final testProducts = [
    Product(
      id: 'prod-1',
      name: 'Apple',
      categoryId: 'cat-1',
      unit: '1 kg',
      mrp: 200,
      sellingPrice: 180,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Product(
      id: 'prod-2',
      name: 'Banana',
      categoryId: 'cat-1',
      unit: '1 dozen',
      mrp: 60,
      sellingPrice: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  setUp(() {
    mockCatalogService = MockCatalogService();
    container = ProviderContainer(
      overrides: [
        catalogServiceProvider.overrideWithValue(mockCatalogService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CategoriesState', () {
    test('initial state should have empty categories', () {
      final state = CategoriesState();
      expect(state.categories, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('copyWith should create new state with updated values', () {
      final state = CategoriesState();
      final newState = state.copyWith(
        categories: testCategories,
        isLoading: true,
        error: 'Test error',
      );

      expect(newState.categories, testCategories);
      expect(newState.isLoading, true);
      expect(newState.error, 'Test error');
    });
  });

  group('CategoriesNotifier - loadCategories', () {
    test('should load categories successfully', () async {
      when(() => mockCatalogService.getCategories())
          .thenAnswer((_) async => testCategories);

      final notifier = container.read(categoriesProvider.notifier);
      await notifier.loadCategories();

      final state = container.read(categoriesProvider);
      expect(state.categories.length, 2);
      expect(state.categories.first.name, 'Fruits');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should set loading state while fetching', () async {
      when(() => mockCatalogService.getCategories())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return testCategories;
      });

      final notifier = container.read(categoriesProvider.notifier);
      final future = notifier.loadCategories();

      // Check loading state immediately
      await Future.delayed(const Duration(milliseconds: 10));
      var state = container.read(categoriesProvider);
      expect(state.isLoading, true);

      await future;

      // Check state after completion
      state = container.read(categoriesProvider);
      expect(state.isLoading, false);
    });

    test('should handle network error with user-friendly message', () async {
      when(() => mockCatalogService.getCategories()).thenThrow(
        DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/categories'),
        ),
      );

      final notifier = container.read(categoriesProvider.notifier);
      await notifier.loadCategories();

      final state = container.read(categoriesProvider);
      expect(state.error, isNotNull);
      expect(state.error!.toLowerCase(), contains('connection'));
      expect(state.isLoading, false);
    });

    test('should handle server error', () async {
      when(() => mockCatalogService.getCategories()).thenThrow(
        DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/categories'),
          ),
          requestOptions: RequestOptions(path: '/categories'),
        ),
      );

      final notifier = container.read(categoriesProvider.notifier);
      await notifier.loadCategories();

      final state = container.read(categoriesProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });
  });

  group('ProductsState', () {
    test('initial state should have empty products', () {
      final state = ProductsState();
      expect(state.products, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.hasMore, true);
      expect(state.currentPage, 1);
    });

    test('copyWith should create new state with updated values', () {
      final state = ProductsState();
      final newState = state.copyWith(
        products: testProducts,
        isLoading: true,
        hasMore: false,
        currentPage: 3,
      );

      expect(newState.products, testProducts);
      expect(newState.isLoading, true);
      expect(newState.hasMore, false);
      expect(newState.currentPage, 3);
    });
  });

  group('ProductsNotifier - loadProducts', () {
    test('should load products successfully', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => testProducts);

      final notifier = container.read(productsProvider.notifier);
      await notifier.loadProducts();

      final state = container.read(productsProvider);
      expect(state.products.length, 2);
      expect(state.products.first.name, 'Apple');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should refresh products when refresh is true', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => testProducts);

      final notifier = container.read(productsProvider.notifier);

      // Load initial products
      await notifier.loadProducts();

      // Refresh
      await notifier.loadProducts(refresh: true);

      final state = container.read(productsProvider);
      expect(state.products.length, 2);
      expect(state.currentPage, 2); // Reset to 2 after refresh (next page)
    });

    test('should append products for pagination', () async {
      // Generate 20 products for first page to ensure hasMore is true
      final firstPageProducts = List.generate(
        20,
        (i) => Product(
          id: 'prod-$i',
          name: 'Product $i',
          categoryId: 'cat-1',
          unit: '1 kg',
          mrp: 100,
          sellingPrice: 80,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: 1,
          )).thenAnswer((_) async => firstPageProducts);

      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: 2,
          )).thenAnswer((_) async => [
            Product(
              id: 'prod-20',
              name: 'Orange',
              categoryId: 'cat-1',
              unit: '1 kg',
              mrp: 120,
              sellingPrice: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]);

      final notifier = container.read(productsProvider.notifier);

      // Load first page
      await notifier.loadProducts(refresh: true);
      expect(container.read(productsProvider).products.length, 20);
      expect(container.read(productsProvider).hasMore, true);

      // Load second page
      await notifier.loadProducts();
      expect(container.read(productsProvider).products.length, 21);
    });

    test('should set hasMore to false when less than 20 products returned', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => testProducts); // Only 2 products

      final notifier = container.read(productsProvider.notifier);
      await notifier.loadProducts();

      final state = container.read(productsProvider);
      expect(state.hasMore, false);
    });

    test('should not load when already loading', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return testProducts;
      });

      final notifier = container.read(productsProvider.notifier);

      // Start loading
      final future1 = notifier.loadProducts();

      // Try to load again while loading
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.loadProducts();

      await future1;

      // Should have only called service once
      verify(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).called(1);
    });

    test('should handle error with user-friendly message', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenThrow(
        DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/products'),
        ),
      );

      final notifier = container.read(productsProvider.notifier);
      await notifier.loadProducts();

      final state = container.read(productsProvider);
      expect(state.error, isNotNull);
      expect(state.error!.toLowerCase(), contains('timed out'));
    });
  });

  group('ProductsNotifier - searchProducts', () {
    test('should search products successfully', () async {
      when(() => mockCatalogService.searchProducts(any()))
          .thenAnswer((_) async => [testProducts.first]);

      final notifier = container.read(productsProvider.notifier);
      await notifier.searchProducts('Apple');

      final state = container.read(productsProvider);
      expect(state.products.length, 1);
      expect(state.products.first.name, 'Apple');
      expect(state.hasMore, false); // Search doesn't paginate
    });

    test('should clear products before search', () async {
      when(() => mockCatalogService.getProducts(
            categoryId: any(named: 'categoryId'),
            page: any(named: 'page'),
          )).thenAnswer((_) async => testProducts);

      when(() => mockCatalogService.searchProducts(any()))
          .thenAnswer((_) async => [testProducts.first]);

      final notifier = container.read(productsProvider.notifier);

      // Load products first
      await notifier.loadProducts();
      expect(container.read(productsProvider).products.length, 2);

      // Search should clear and set new results
      await notifier.searchProducts('Apple');
      expect(container.read(productsProvider).products.length, 1);
    });

    test('should return empty list when no results found', () async {
      when(() => mockCatalogService.searchProducts(any()))
          .thenAnswer((_) async => []);

      final notifier = container.read(productsProvider.notifier);
      await notifier.searchProducts('NonExistent');

      final state = container.read(productsProvider);
      expect(state.products, isEmpty);
      expect(state.error, isNull);
    });

    test('should handle search error', () async {
      when(() => mockCatalogService.searchProducts(any()))
          .thenThrow(Exception('Search failed'));

      final notifier = container.read(productsProvider.notifier);
      await notifier.searchProducts('Apple');

      final state = container.read(productsProvider);
      expect(state.error, isNotNull);
      expect(state.products, isEmpty);
    });
  });
}
