import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import '../../../core/widgets/loading/loading.dart';
import '../providers/catalog_provider.dart';

/// Screen showing all categories in a grid layout
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(context, ref, categoriesState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, CategoriesState categoriesState) {
    if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: 9,
        itemBuilder: (context, index) => const CategoryCardSkeleton(),
      );
    }

    if (categoriesState.error != null && categoriesState.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load categories',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              categoriesState.error!,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(categoriesProvider.notifier).loadCategories();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (categoriesState.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No categories found',
              style: AppTypography.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(categoriesProvider.notifier).loadCategories();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: categoriesState.categories.length,
        itemBuilder: (context, index) {
          final category = categoriesState.categories[index];
          return _CategoryGridItem(
            name: category.name,
            imageUrl: category.imageUrl,
            onTap: () {
              context.push('/category/${category.id}');
            },
          );
        },
      ),
    );
  }
}

/// Grid item for category display
class _CategoryGridItem extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback onTap;

  const _CategoryGridItem({
    required this.name,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category image
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const ShimmerWidget.rectangular(
                          height: 56,
                          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.category,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: AppColors.primary,
                      size: 28,
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Category name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                name,
                style: AppTypography.categoryName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
