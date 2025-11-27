import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/catalog_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    final cartState = ref.watch(cartProvider);
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          // Wishlist button
          productAsync.whenOrNull(
            data: (product) {
              if (product == null) return null;
              final isFavorite = wishlistState.isInWishlist(product.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(wishlistProvider.notifier).toggleWishlist(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite ? 'Removed from wishlist' : 'Added to wishlist',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ) ?? const SizedBox.shrink(),
          // Cart button
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '${cartState.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: productAsync.when(
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
                onPressed: () => ref.refresh(productProvider(productId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (product) {
          if (product == null) {
            return const Center(child: Text('Product not found'));
          }

          final quantityInCart = ref.watch(cartProvider.notifier).getQuantityInCart(product.id);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel
                      SizedBox(
                        height: 300,
                        child: product.images.isNotEmpty
                            ? PageView.builder(
                                itemCount: product.images.length,
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: product.images[index],
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) =>
                                        const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.image, size: 64, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.image, size: 64, color: Colors.grey),
                                ),
                              ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            // Unit
                            Text(
                              product.unit,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),

                            // Price
                            Row(
                              children: [
                                Text(
                                  '\u20B9${product.sellingPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\u20B9${product.mrp.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${product.discount.toStringAsFixed(0)}% OFF',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Tax note
                            if (product.taxPercent > 0)
                              Text(
                                'Inclusive of ${product.taxPercent}% tax',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),

                            const SizedBox(height: 24),

                            // Description
                            if (product.description != null && product.description!.isNotEmpty) ...[
                              const Text(
                                'Description',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.description!,
                                style: const TextStyle(fontSize: 14, height: 1.5),
                              ),
                            ],

                            // Stock indicator
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'In Stock',
                                  style: TextStyle(fontSize: 14, color: Colors.green.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom add to cart section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: quantityInCart > 0
                      ? Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.white),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(
                                          product.id,
                                          quantityInCart - 1,
                                        );
                                      },
                                    ),
                                    Text(
                                      '$quantityInCart',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.white),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(
                                          product.id,
                                          quantityInCart + 1,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () => context.push('/cart'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF4CAF50)),
                                  ),
                                  child: const Text('Go to Cart'),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: cartState.isLoading
                                ? null
                                : () {
                                    ref.read(cartProvider.notifier).addToCart(product);
                                  },
                            child: const Text('Add to Cart'),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
