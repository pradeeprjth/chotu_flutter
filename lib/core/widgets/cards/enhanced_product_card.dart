import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import '../../../core/models/product_model.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../loading/shimmer_widget.dart';

/// Enhanced product card with rich interactions and visual polish
class EnhancedProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onQuickView;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onQuickView,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantityInCart = ref.watch(cartProvider.notifier).getQuantityInCart(product.id);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/product/${product.id}');
      },
      onLongPress: onQuickView != null ? () {
        HapticFeedback.mediumImpact();
        onQuickView!();
      } : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section
            Expanded(
              flex: 3,
              child: _buildImageSection(context),
            ),

            // Product details section
            Expanded(
              flex: 2,
              child: _buildDetailsSection(context),
            ),

            // Add to cart section
            _buildCartSection(context, ref, cartState, quantityInCart),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Stack(
      children: [
        // Product image with gradient overlay
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                product.primaryImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.primaryImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerWidget.rectangular(
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: AppColors.grey400,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                      ),

                // Subtle gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Top badges row
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Discount badge
              if (product.hasDiscount)
                _buildDiscountBadge()
              else
                const SizedBox.shrink(),

              // Favorite button
              if (onFavorite != null)
                _buildFavoriteButton(),
            ],
          ),
        ),

        // Stock status badge (bottom left)
        // This can be enabled when stock data is available
        // Positioned(
        //   bottom: AppSpacing.sm,
        //   left: AppSpacing.sm,
        //   child: _buildStockBadge(),
        // ),
      ],
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.error, AppColors.errorDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        boxShadow: AppShadows.sm,
      ),
      child: Text(
        '${product.discount.toStringAsFixed(0)}% OFF',
        style: AppTypography.discountBadge,
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onFavorite?.call();
        },
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: AppIconSize.sm,
            color: isFavorite ? AppColors.error : AppColors.grey600,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.productName,
          ),
          const SizedBox(height: AppSpacing.xxs),

          // Unit/Size
          Text(
            product.unit,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),

          const Spacer(),

          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Selling price
              Text(
                '\u20B9${product.sellingPrice.toStringAsFixed(0)}',
                style: AppTypography.productPrice,
              ),
              if (product.hasDiscount) ...[
                const SizedBox(width: AppSpacing.xs),
                // Original price
                Text(
                  '\u20B9${product.mrp.toStringAsFixed(0)}',
                  style: AppTypography.productOldPrice,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
    int quantityInCart,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: AnimatedSwitcher(
        duration: AppDuration.fast,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: quantityInCart > 0
            ? QuantitySelector(
                key: ValueKey('quantity_${product.id}'),
                quantity: quantityInCart,
                isLoading: cartState.isProductLoading(product.id),
                onIncrease: () {
                  HapticFeedback.lightImpact();
                  ref.read(cartProvider.notifier).updateQuantity(
                    product.id,
                    quantityInCart + 1,
                  );
                },
                onDecrease: () {
                  HapticFeedback.lightImpact();
                  ref.read(cartProvider.notifier).updateQuantity(
                    product.id,
                    quantityInCart - 1,
                  );
                },
              )
            : AddToCartButton(
                key: ValueKey('add_${product.id}'),
                isLoading: cartState.isProductLoading(product.id),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(cartProvider.notifier).addToCart(product);
                },
              ),
      ),
    );
  }
}

/// Add to cart button with loading state
class AddToCartButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const AddToCartButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: AppDuration.fast,
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
              : const Row(
                  key: ValueKey('add'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'ADD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Quantity selector for cart items
class QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool isLoading;
  final double height;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    this.isLoading = false,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrease button
          _buildButton(
            icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
            onTap: isLoading ? null : onDecrease,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.button),
            ),
          ),

          // Quantity display
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: AppDuration.fast,
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
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ),

          // Increase button
          _buildButton(
            icon: Icons.add,
            onTap: isLoading ? null : onIncrease,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(AppRadius.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    required BorderRadius borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Product label badge (New, Bestseller, Organic)
class ProductLabel extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const ProductLabel({
    super.key,
    required this.label,
    this.backgroundColor = AppColors.secondary,
    this.textColor = AppColors.textOnSecondary,
  });

  factory ProductLabel.newLabel() {
    return const ProductLabel(
      label: 'NEW',
      backgroundColor: AppColors.info,
      textColor: Colors.white,
    );
  }

  factory ProductLabel.bestseller() {
    return const ProductLabel(
      label: 'BESTSELLER',
      backgroundColor: AppColors.secondary,
      textColor: Colors.black,
    );
  }

  factory ProductLabel.organic() {
    return const ProductLabel(
      label: 'ORGANIC',
      backgroundColor: AppColors.success,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Stock status badge
class StockStatusBadge extends StatelessWidget {
  final int stockQuantity;

  const StockStatusBadge({
    super.key,
    required this.stockQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getStockStatus();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _getStockStatus() {
    if (stockQuantity <= 0) {
      return ('Out of Stock', AppColors.outOfStock);
    } else if (stockQuantity <= 5) {
      return ('Low Stock', AppColors.lowStock);
    } else {
      return ('In Stock', AppColors.inStock);
    }
  }
}
