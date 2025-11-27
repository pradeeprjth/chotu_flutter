import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chotu_app/features/cart/providers/cart_provider.dart';
import 'package:chotu_app/core/services/cart_service.dart';
import 'package:chotu_app/core/models/cart_model.dart';
import 'package:chotu_app/core/models/product_model.dart';

// Mock classes
class MockCartService extends Mock implements CartService {}

void main() {
  late MockCartService mockCartService;
  late ProviderContainer container;

  // Test product
  final testProduct = Product(
    id: 'prod-1',
    name: 'Test Product',
    categoryId: 'cat-1',
    unit: '1 kg',
    mrp: 100,
    sellingPrice: 80,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Test cart item
  final testCartItem = CartItem(
    productId: 'prod-1',
    product: testProduct,
    quantity: 2,
    priceAtAdd: 80,
  );

  // Test cart
  final testCart = Cart(items: [testCartItem]);

  setUp(() {
    mockCartService = MockCartService();
    container = ProviderContainer(
      overrides: [
        cartServiceProvider.overrideWithValue(mockCartService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CartState', () {
    test('initial state should have empty cart', () {
      final state = CartState();
      expect(state.cart.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.loadingProductIds, isEmpty);
      expect(state.itemCount, 0);
      expect(state.isEmpty, true);
    });

    test('copyWith should create new state with updated values', () {
      final state = CartState();
      final newState = state.copyWith(
        cart: testCart,
        isLoading: true,
        error: 'Test error',
        loadingProductIds: {'prod-1'},
      );

      expect(newState.cart, testCart);
      expect(newState.isLoading, true);
      expect(newState.error, 'Test error');
      expect(newState.loadingProductIds.contains('prod-1'), true);
    });

    test('isProductLoading should return correct loading state', () {
      final state = CartState(loadingProductIds: {'prod-1'});
      expect(state.isProductLoading('prod-1'), true);
      expect(state.isProductLoading('prod-2'), false);
    });

    test('itemCount should return correct count', () {
      final state = CartState(cart: testCart);
      expect(state.itemCount, 2); // quantity is 2
    });

    test('subtotal should calculate correctly', () {
      final state = CartState(cart: testCart);
      expect(state.subtotal, 160); // 80 * 2
    });
  });

  group('CartNotifier - loadCart', () {
    test('should load cart successfully', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();

      final state = container.read(cartProvider);
      expect(state.cart.items.length, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('should handle error when loading cart fails', () async {
      when(() => mockCartService.getCart()).thenThrow(Exception('Network error'));

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();

      final state = container.read(cartProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });
  });

  group('CartNotifier - addToCart', () {
    test('should add product to cart successfully', () async {
      when(() => mockCartService.addToCart(any(), any()))
          .thenAnswer((_) async => testCart);

      final notifier = container.read(cartProvider.notifier);
      await notifier.addToCart(testProduct);

      final state = container.read(cartProvider);
      expect(state.cart.items.length, 1);
      expect(state.loadingProductIds.contains('prod-1'), false);
    });

    test('should set loading state for specific product while adding', () async {
      when(() => mockCartService.addToCart(any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return testCart;
      });

      final notifier = container.read(cartProvider.notifier);
      final future = notifier.addToCart(testProduct);

      // Check loading state immediately
      await Future.delayed(const Duration(milliseconds: 10));
      var state = container.read(cartProvider);
      expect(state.loadingProductIds.contains('prod-1'), true);

      await future;

      // Check loading state after completion
      state = container.read(cartProvider);
      expect(state.loadingProductIds.contains('prod-1'), false);
    });

    test('should add locally when service fails (offline mode)', () async {
      when(() => mockCartService.addToCart(any(), any()))
          .thenThrow(Exception('Network error'));

      final notifier = container.read(cartProvider.notifier);
      await notifier.addToCart(testProduct);

      final state = container.read(cartProvider);
      expect(state.cart.items.length, 1);
      expect(state.cart.items.first.productId, 'prod-1');
      expect(state.loadingProductIds.contains('prod-1'), false);
    });

    test('should increment quantity when product already in cart', () async {
      // Set initial state with product already in cart
      when(() => mockCartService.addToCart(any(), any()))
          .thenThrow(Exception('Network error'));

      final notifier = container.read(cartProvider.notifier);

      // Add first time
      await notifier.addToCart(testProduct);
      var state = container.read(cartProvider);
      expect(state.cart.items.first.quantity, 1);

      // Add second time
      await notifier.addToCart(testProduct);
      state = container.read(cartProvider);
      expect(state.cart.items.first.quantity, 2);
    });
  });

  group('CartNotifier - updateQuantity', () {
    setUp(() {
      // Set up initial cart state
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);
    });

    test('should update quantity successfully', () async {
      final newCart = Cart(items: [
        testCartItem.copyWith(quantity: 5),
      ]);
      when(() => mockCartService.updateCartItem(any(), any()))
          .thenAnswer((_) async => newCart);

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      await notifier.updateQuantity('prod-1', 5);

      final state = container.read(cartProvider);
      expect(state.cart.items.first.quantity, 5);
    });

    test('should remove item when quantity is 0 or less', () async {
      when(() => mockCartService.removeFromCart(any()))
          .thenAnswer((_) async => Cart());

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      await notifier.updateQuantity('prod-1', 0);

      final state = container.read(cartProvider);
      expect(state.cart.items, isEmpty);
    });

    test('should reject quantity above maximum', () async {
      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      await notifier.updateQuantity('prod-1', 100);

      final state = container.read(cartProvider);
      expect(state.error, contains('Maximum quantity'));
    });

    test('should handle optimistic update when already loading', () async {
      when(() => mockCartService.updateCartItem(any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return testCart;
      });

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();

      // Start first update
      final future1 = notifier.updateQuantity('prod-1', 3);

      // Wait a bit then trigger second update (while first is still loading)
      await Future.delayed(const Duration(milliseconds: 50));
      await notifier.updateQuantity('prod-1', 5);

      // Second update should be applied optimistically
      var state = container.read(cartProvider);
      expect(state.cart.items.first.quantity, 5);

      await future1;
    });
  });

  group('CartNotifier - removeFromCart', () {
    test('should remove item from cart successfully', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);
      when(() => mockCartService.removeFromCart(any()))
          .thenAnswer((_) async => Cart());

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      await notifier.removeFromCart('prod-1');

      final state = container.read(cartProvider);
      expect(state.cart.items, isEmpty);
    });

    test('should set loading state for specific product while removing', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);
      when(() => mockCartService.removeFromCart(any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Cart();
      });

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      final future = notifier.removeFromCart('prod-1');

      // Check loading state immediately
      await Future.delayed(const Duration(milliseconds: 10));
      var state = container.read(cartProvider);
      expect(state.loadingProductIds.contains('prod-1'), true);

      await future;

      // Check loading state after completion
      state = container.read(cartProvider);
      expect(state.loadingProductIds.contains('prod-1'), false);
    });
  });

  group('CartNotifier - clearCart', () {
    test('should clear all items from cart', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);
      when(() => mockCartService.clearCart()).thenAnswer((_) async {});

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();
      await notifier.clearCart();

      final state = container.read(cartProvider);
      expect(state.cart.items, isEmpty);
      expect(state.isLoading, false);
    });
  });

  group('CartNotifier - getQuantityInCart', () {
    test('should return correct quantity for product in cart', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();

      final quantity = notifier.getQuantityInCart('prod-1');
      expect(quantity, 2);
    });

    test('should return 0 for product not in cart', () async {
      when(() => mockCartService.getCart()).thenAnswer((_) async => testCart);

      final notifier = container.read(cartProvider.notifier);
      await notifier.loadCart();

      final quantity = notifier.getQuantityInCart('prod-999');
      expect(quantity, 0);
    });
  });
}
