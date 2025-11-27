import 'package:flutter/material.dart';
import '../../../app/design_tokens.dart';
import 'shimmer_widget.dart';

/// Skeleton loader for product cards
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.card),
              ),
              child: const ShimmerWidget.rectangular(height: double.infinity),
            ),
          ),
          // Content placeholder
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  const ShimmerWidget.rectangular(
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Unit
                  ShimmerWidget.rectangular(
                    height: 10,
                    width: MediaQuery.of(context).size.width * 0.2,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  const Spacer(),
                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerWidget.rectangular(
                        height: 16,
                        width: MediaQuery.of(context).size.width * 0.15,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                      ShimmerWidget.rectangular(
                        height: 28,
                        width: MediaQuery.of(context).size.width * 0.15,
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for category cards
class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.sm,
          ),
          child: const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
            child: ShimmerWidget.rectangular(height: 60),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const ShimmerWidget.rectangular(
          height: 10,
          width: 50,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ],
    );
  }
}

/// Skeleton loader for cart items
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          // Product image
          const ShimmerWidget.rectangular(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
          ),
          const SizedBox(width: AppSpacing.md),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget.rectangular(
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerWidget.rectangular(
                  height: 10,
                  width: 80,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerWidget.rectangular(
                      height: 16,
                      width: 60,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    ShimmerWidget.rectangular(
                      height: 32,
                      width: MediaQuery.of(context).size.width * 0.25,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for order cards
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerWidget.rectangular(
                height: 14,
                width: 120,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              ShimmerWidget.rectangular(
                height: 24,
                width: MediaQuery.of(context).size.width * 0.2,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Order items preview
          Row(
            children: [
              const ShimmerWidget.rectangular(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const ShimmerWidget.rectangular(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
              const SizedBox(width: AppSpacing.sm),
              const ShimmerWidget.rectangular(
                width: 50,
                height: 50,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Order footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ShimmerWidget.rectangular(
                height: 12,
                width: 100,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const ShimmerWidget.rectangular(
                height: 16,
                width: 80,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for list items
class ListItemSkeleton extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;

  const ListItemSkeleton({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (hasLeading) ...[
            const ShimmerWidget.circular(size: 40),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget.rectangular(
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerWidget.rectangular(
                  height: 10,
                  width: 150,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppSpacing.md),
            const ShimmerWidget.rectangular(
              height: 20,
              width: 60,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton loader for product detail screen
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel placeholder
          const ShimmerWidget.rectangular(
            height: 300,
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name
                const ShimmerWidget.rectangular(
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Unit/Size
                const ShimmerWidget.rectangular(
                  height: 14,
                  width: 100,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Price section
                Row(
                  children: [
                    const ShimmerWidget.rectangular(
                      height: 32,
                      width: 80,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const ShimmerWidget.rectangular(
                      height: 16,
                      width: 60,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const ShimmerWidget.rectangular(
                      height: 24,
                      width: 60,
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Description section
                const ShimmerWidget.rectangular(
                  height: 16,
                  width: 120,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.md),
                const ShimmerWidget.rectangular(
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerWidget.rectangular(
                  height: 12,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: AppSpacing.sm),
                const ShimmerWidget.rectangular(
                  height: 12,
                  width: 200,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid skeleton loader for product grids
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// Horizontal list skeleton loader for categories
class CategoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryListSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => const CategoryCardSkeleton(),
      ),
    );
  }
}

/// Cart list skeleton
class CartListSkeleton extends StatelessWidget {
  final int itemCount;

  const CartListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const CartItemSkeleton(),
    );
  }
}

/// Orders list skeleton
class OrderListSkeleton extends StatelessWidget {
  final int itemCount;

  const OrderListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => const OrderCardSkeleton(),
    );
  }
}
