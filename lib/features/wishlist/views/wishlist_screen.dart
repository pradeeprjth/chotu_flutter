import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import '../../../core/models/wishlist_model.dart';
import '../../../core/widgets/loading/shimmer_widget.dart';
import '../providers/wishlist_provider.dart';
import '../../cart/providers/cart_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistProvider.notifier).loadWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (wishlistState.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearConfirmation(context),
              tooltip: 'Clear wishlist',
            ),
        ],
      ),
      body: _buildBody(wishlistState),
    );
  }

  Widget _buildBody(WishlistState wishlistState) {
    if (wishlistState.isLoading && wishlistState.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (wishlistState.error != null && wishlistState.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 8),
            Text(wishlistState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(wishlistProvider.notifier).loadWishlist(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (wishlistState.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(wishlistProvider.notifier).loadWishlist(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: wishlistState.items.length,
        itemBuilder: (context, index) {
          final item = wishlistState.items[index];
          return _WishlistItemCard(
            item: item,
            isLoading: wishlistState.isProductLoading(item.productId),
            onRemove: () => _removeFromWishlist(item.productId),
            onMoveToCart: () => _moveToCart(item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Save items you love to your wishlist',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  void _removeFromWishlist(String productId) {
    HapticFeedback.lightImpact();
    ref.read(wishlistProvider.notifier).removeFromWishlist(productId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from wishlist'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _moveToCart(WishlistItem item) {
    HapticFeedback.mediumImpact();
    if (item.product != null) {
      ref.read(cartProvider.notifier).addToCart(item.product!);
      ref.read(wishlistProvider.notifier).removeFromWishlist(item.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Moved to cart'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content:
            const Text('Are you sure you want to remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(wishlistProvider.notifier).clearWishlist();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wishlist cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _WishlistItemCard extends StatelessWidget {
  final WishlistItem item;
  final bool isLoading;
  final VoidCallback onRemove;
  final VoidCallback onMoveToCart;

  const _WishlistItemCard({
    required this.item,
    required this.isLoading,
    required this.onRemove,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    final product = item.product;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          if (product != null) {
            context.push('/product/${product.id}');
          }
        },
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: product?.primaryImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product!.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const ShimmerWidget.rectangular(
                            height: 80,
                            borderRadius: BorderRadius.zero,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grey100,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.grey400,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.grey100,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.grey400,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.productName,
                    ),
                    if (product != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        product.unit,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            '\u20B9${product.sellingPrice.toStringAsFixed(0)}',
                            style: AppTypography.productPrice,
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              '\u20B9${product.mrp.toStringAsFixed(0)}',
                              style: AppTypography.productOldPrice,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: Text(
                                '${product.discount.toStringAsFixed(0)}% OFF',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions column
              Column(
                children: [
                  // Remove button
                  IconButton(
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.grey400,
                            ),
                          )
                        : Icon(
                            Icons.close,
                            size: 20,
                            color: AppColors.grey500,
                          ),
                    onPressed: isLoading ? null : onRemove,
                    tooltip: 'Remove from wishlist',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Move to cart button
                  if (product != null)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : onMoveToCart,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
