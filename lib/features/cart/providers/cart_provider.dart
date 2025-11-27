import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/cart_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/app_logger.dart';

class CartState {
  final Cart cart;
  final bool isLoading;
  final String? error;
  final Set<String> loadingProductIds; // Per-item loading state

  CartState({
    Cart? cart,
    this.isLoading = false,
    this.error,
    Set<String>? loadingProductIds,
  }) : cart = cart ?? Cart(),
       loadingProductIds = loadingProductIds ?? {};

  CartState copyWith({
    Cart? cart,
    bool? isLoading,
    String? error,
    Set<String>? loadingProductIds,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loadingProductIds: loadingProductIds ?? this.loadingProductIds,
    );
  }

  int get itemCount => cart.itemCount;
  double get subtotal => cart.subtotal;
  bool get isEmpty => cart.isEmpty;
  List<CartItem> get items => cart.items;
  double get deliveryCharges => cart.deliveryCharges;
  double get total => cart.total;

  bool isProductLoading(String productId) => loadingProductIds.contains(productId);
}

class CartNotifier extends StateNotifier<CartState> {
  final CartService _cartService;

  CartNotifier(this._cartService) : super(CartState());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final cart = await _cartService.getCart();
      state = state.copyWith(cart: cart, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> addToCart(Product product, {int quantity = 1}) async {
    AppLogger.logCartAction('add', product.id, quantity: quantity);

    // Set per-item loading state
    final loadingIds = Set<String>.from(state.loadingProductIds)..add(product.id);
    state = state.copyWith(loadingProductIds: loadingIds, error: null);

    try {
      final cart = await _cartService.addToCart(product.id, quantity);
      final doneIds = Set<String>.from(state.loadingProductIds)..remove(product.id);
      state = state.copyWith(cart: cart, loadingProductIds: doneIds);
      AppLogger.debug('Added ${product.name} to cart');
    } catch (e) {
      AppLogger.warning('Failed to add to cart via API, adding locally', e);
      // For offline/demo mode, add locally
      final existingIndex = state.cart.items.indexWhere(
        (item) => item.productId == product.id,
      );

      List<CartItem> updatedItems;
      if (existingIndex >= 0) {
        updatedItems = List.from(state.cart.items);
        final existingItem = updatedItems[existingIndex];
        updatedItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
      } else {
        updatedItems = [
          ...state.cart.items,
          CartItem(
            productId: product.id,
            product: product,
            quantity: quantity,
            priceAtAdd: product.sellingPrice,
          ),
        ];
      }

      final doneIds = Set<String>.from(state.loadingProductIds)..remove(product.id);
      state = state.copyWith(
        cart: state.cart.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
    }
  }

  static const int maxQuantityPerItem = 99;

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    // Validate quantity bounds
    if (quantity > maxQuantityPerItem) {
      AppLogger.warning('Quantity exceeds maximum: $quantity > $maxQuantityPerItem');
      state = state.copyWith(error: 'Maximum quantity is $maxQuantityPerItem');
      return;
    }

    AppLogger.logCartAction('update_quantity', productId, quantity: quantity);

    // Prevent rapid consecutive updates - if already loading, update optimistically
    if (state.isProductLoading(productId)) {
      // Update locally immediately for responsive UI
      final updatedItems = state.cart.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      state = state.copyWith(cart: state.cart.copyWith(items: updatedItems));
      return;
    }

    // Set per-item loading state
    final loadingIds = Set<String>.from(state.loadingProductIds)..add(productId);
    state = state.copyWith(loadingProductIds: loadingIds, error: null);

    try {
      final cart = await _cartService.updateCartItem(productId, quantity);
      final doneIds = Set<String>.from(state.loadingProductIds)..remove(productId);
      state = state.copyWith(cart: cart, loadingProductIds: doneIds);
    } catch (e) {
      // Update locally for demo
      final updatedItems = state.cart.items.map((item) {
        if (item.productId == productId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      final doneIds = Set<String>.from(state.loadingProductIds)..remove(productId);
      state = state.copyWith(
        cart: state.cart.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
    }
  }

  Future<void> removeFromCart(String productId) async {
    AppLogger.logCartAction('remove', productId);

    // Set per-item loading state
    final loadingIds = Set<String>.from(state.loadingProductIds)..add(productId);
    state = state.copyWith(loadingProductIds: loadingIds, error: null);

    try {
      final cart = await _cartService.removeFromCart(productId);
      final doneIds = Set<String>.from(state.loadingProductIds)..remove(productId);
      state = state.copyWith(cart: cart, loadingProductIds: doneIds);
    } catch (e) {
      // Remove locally for demo
      final updatedItems = state.cart.items
          .where((item) => item.productId != productId)
          .toList();

      final doneIds = Set<String>.from(state.loadingProductIds)..remove(productId);
      state = state.copyWith(
        cart: state.cart.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
    }
  }

  Future<void> clearCart() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _cartService.clearCart();
      state = state.copyWith(cart: Cart(), isLoading: false);
    } catch (e) {
      state = state.copyWith(cart: Cart(), isLoading: false);
    }
  }

  int getQuantityInCart(String productId) {
    final item = state.cart.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        product: Product(
          id: '',
          name: '',
          categoryId: '',
          unit: '',
          mrp: 0,
          sellingPrice: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: 0,
        priceAtAdd: 0,
      ),
    );
    return item.quantity;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return CartNotifier(cartService);
});
