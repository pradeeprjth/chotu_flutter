import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/wishlist_model.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/app_logger.dart';

class WishlistState {
  final Wishlist wishlist;
  final bool isLoading;
  final String? error;
  final Set<String> loadingProductIds;

  WishlistState({
    Wishlist? wishlist,
    this.isLoading = false,
    this.error,
    Set<String>? loadingProductIds,
  })  : wishlist = wishlist ?? Wishlist(),
        loadingProductIds = loadingProductIds ?? {};

  WishlistState copyWith({
    Wishlist? wishlist,
    bool? isLoading,
    String? error,
    Set<String>? loadingProductIds,
  }) {
    return WishlistState(
      wishlist: wishlist ?? this.wishlist,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loadingProductIds: loadingProductIds ?? this.loadingProductIds,
    );
  }

  int get itemCount => wishlist.itemCount;
  bool get isEmpty => wishlist.isEmpty;
  bool get isNotEmpty => wishlist.isNotEmpty;
  List<WishlistItem> get items => wishlist.items;

  bool isInWishlist(String productId) => wishlist.containsProduct(productId);
  bool isProductLoading(String productId) =>
      loadingProductIds.contains(productId);
}

class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistService _wishlistService;

  WishlistNotifier(this._wishlistService) : super(WishlistState());

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final wishlist = await _wishlistService.getWishlist();
      state = state.copyWith(wishlist: wishlist, isLoading: false);
      AppLogger.debug('Loaded ${wishlist.itemCount} wishlist items');
    } catch (e) {
      AppLogger.warning('Failed to load wishlist from API', e);
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  Future<void> addToWishlist(Product product) async {
    if (state.isInWishlist(product.id)) {
      AppLogger.debug('Product ${product.id} already in wishlist');
      return;
    }

    AppLogger.info('Adding product ${product.name} to wishlist');

    final loadingIds = Set<String>.from(state.loadingProductIds)
      ..add(product.id);
    state = state.copyWith(loadingProductIds: loadingIds, error: null);

    try {
      final wishlistItem = await _wishlistService.addToWishlist(product.id);
      final updatedItems = [...state.wishlist.items, wishlistItem];
      final doneIds = Set<String>.from(state.loadingProductIds)
        ..remove(product.id);
      state = state.copyWith(
        wishlist: state.wishlist.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
      AppLogger.debug('Added ${product.name} to wishlist');
    } catch (e) {
      AppLogger.warning('Failed to add to wishlist via API, adding locally', e);
      // For offline/demo mode, add locally
      final newItem = WishlistItem(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        product: product,
        addedAt: DateTime.now(),
      );
      final updatedItems = [...state.wishlist.items, newItem];
      final doneIds = Set<String>.from(state.loadingProductIds)
        ..remove(product.id);
      state = state.copyWith(
        wishlist: state.wishlist.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    AppLogger.info('Removing product $productId from wishlist');

    final loadingIds = Set<String>.from(state.loadingProductIds)
      ..add(productId);
    state = state.copyWith(loadingProductIds: loadingIds, error: null);

    try {
      await _wishlistService.removeFromWishlist(productId);
      final updatedItems = state.wishlist.items
          .where((item) => item.productId != productId)
          .toList();
      final doneIds = Set<String>.from(state.loadingProductIds)
        ..remove(productId);
      state = state.copyWith(
        wishlist: state.wishlist.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
      AppLogger.debug('Removed product $productId from wishlist');
    } catch (e) {
      AppLogger.warning(
          'Failed to remove from wishlist via API, removing locally', e);
      // For offline/demo mode, remove locally
      final updatedItems = state.wishlist.items
          .where((item) => item.productId != productId)
          .toList();
      final doneIds = Set<String>.from(state.loadingProductIds)
        ..remove(productId);
      state = state.copyWith(
        wishlist: state.wishlist.copyWith(items: updatedItems),
        loadingProductIds: doneIds,
      );
    }
  }

  Future<void> toggleWishlist(Product product) async {
    if (state.isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  Future<void> clearWishlist() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _wishlistService.clearWishlist();
      state = state.copyWith(wishlist: Wishlist(), isLoading: false);
      AppLogger.debug('Cleared wishlist');
    } catch (e) {
      // Clear locally for demo
      state = state.copyWith(wishlist: Wishlist(), isLoading: false);
    }
  }

  Future<void> moveToCart(String productId) async {
    // This will be called from UI which will also trigger cart add
    await removeFromWishlist(productId);
  }
}

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  final wishlistService = ref.watch(wishlistServiceProvider);
  return WishlistNotifier(wishlistService);
});
