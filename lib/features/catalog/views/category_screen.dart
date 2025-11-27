import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/catalog_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/catalog_service.dart';

// Provider for category products
final categoryProductsProvider = FutureProvider.family<List<Product>, String>((ref, categoryId) async {
  final catalogService = ref.watch(catalogServiceProvider);
  return catalogService.getProducts(categoryId: categoryId);
});

class CategoryScreen extends ConsumerWidget {
  final String categoryId;

  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(categoryProductsProvider(categoryId));
    final cartState = ref.watch(cartProvider);

    // Find category name - handle missing category gracefully
    final categoryMatch = categoriesState.categories.where((c) => c.id == categoryId);
    if (categoryMatch.isEmpty && categoriesState.categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Category')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Category not found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    final category = categoryMatch.isNotEmpty
        ? categoryMatch.first
        : categoriesState.categories.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.push('/cart'),
              ),
              if (cartState.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(categoryProductsProvider(categoryId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No products in this category',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final wishlistState = ref.watch(wishlistProvider);
    final quantityInCart = ref.read(cartProvider.notifier).getQuantityInCart(product.id);
    final isFavorite = wishlistState.isInWishlist(product.id);

    return GestureDetector(
      onTap: () {
        context.push('/product/${product.id}');
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: product.primaryImageUrl != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: product.primaryImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Top row: Discount badge and Favorite button
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Discount badge
                        if (product.hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.discount.toStringAsFixed(0)}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        // Favorite button
                        Material(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(wishlistProvider.notifier).toggleWishlist(product);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isFavorite ? Colors.red : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.unit,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '\u20B9${product.sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '\u20B9${product.mrp.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Add to cart button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: quantityInCart > 0
                    ? _QuantitySelector(
                        key: const ValueKey('quantity_selector'),
                        quantity: quantityInCart,
                        isLoading: cartState.isProductLoading(product.id),
                        onIncrease: () {
                          ref.read(cartProvider.notifier).updateQuantity(
                            product.id,
                            quantityInCart + 1,
                          );
                        },
                        onDecrease: () {
                          ref.read(cartProvider.notifier).updateQuantity(
                            product.id,
                            quantityInCart - 1,
                          );
                        },
                      )
                    : SizedBox(
                        key: const ValueKey('add_button'),
                        width: double.infinity,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: cartState.isProductLoading(product.id)
                              ? null
                              : () {
                                  ref.read(cartProvider.notifier).addToCart(product);
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: cartState.isProductLoading(product.id)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'ADD',
                                  style: TextStyle(fontSize: 12),
                                ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isLoading;

  const _QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onDecrease,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  quantity == 1 ? Icons.delete_outline : Icons.remove,
                  size: 16,
                  color: isLoading ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    key: ValueKey(quantity),
                    '$quantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onIncrease,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: isLoading ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
