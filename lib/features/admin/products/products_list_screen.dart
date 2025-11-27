import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/admin_service.dart';
import 'providers/admin_products_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

/// State for selected products
final selectedProductsProvider = StateProvider<Set<String>>((ref) => {});

/// State for select mode
final isSelectModeProvider = StateProvider<bool>((ref) => false);

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      final state = ref.read(adminProductsProvider);
      if (!state.isLoading &&
          state.pagination != null &&
          state.pagination!.page < state.pagination!.totalPages) {
        ref.read(adminProductsProvider.notifier).loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(adminProductsProvider);
    final isSelectMode = ref.watch(isSelectModeProvider);
    final selectedProducts = ref.watch(selectedProductsProvider);

    return Scaffold(
      appBar: isSelectMode
          ? _buildSelectModeAppBar(context, ref, selectedProducts, productsState.products)
          : _buildNormalAppBar(context, ref, productsState),
      body: productsState.isLoading && productsState.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : productsState.error != null && productsState.products.isEmpty
              ? _buildError(productsState.error!)
              : Column(
                  children: [
                    // Active filters info
                    if (productsState.searchQuery.isNotEmpty ||
                        productsState.categoryFilter != null ||
                        productsState.activeFilter != null)
                      _buildFiltersInfo(productsState),

                    // Bulk actions bar
                    if (isSelectMode && selectedProducts.isNotEmpty)
                      _BulkActionsBar(
                        selectedCount: selectedProducts.length,
                        onDelete: () => _showBulkDeleteDialog(context, ref),
                        onToggleStatus: () => _toggleSelectedStatus(context, ref, productsState.products),
                      ),

                    // Products list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(adminProductsProvider.notifier).loadProducts(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: productsState.products.length + (productsState.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= productsState.products.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final product = productsState.products[index];
                            final isSelected = selectedProducts.contains(product.id);

                            return _ProductCard(
                              product: product,
                              isSelectMode: isSelectMode,
                              isSelected: isSelected,
                              onTap: () {
                                if (isSelectMode) {
                                  _toggleSelection(ref, product.id);
                                } else {
                                  context.push('/admin/products/${product.id}/edit');
                                }
                              },
                              onLongPress: () {
                                if (!isSelectMode) {
                                  ref.read(isSelectModeProvider.notifier).state = true;
                                  _toggleSelection(ref, product.id);
                                }
                              },
                              onEdit: () => context.push('/admin/products/${product.id}/edit'),
                              onToggleStatus: () => _toggleProductStatus(context, ref, product),
                              onDelete: () => _showDeleteDialog(context, ref, product),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: isSelectMode
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/admin/products/new'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.grey400),
          const SizedBox(height: AppSpacing.md),
          Text('Failed to load products', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.read(adminProductsProvider.notifier).loadProducts(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersInfo(AdminProductsState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (state.searchQuery.isNotEmpty)
                  _FilterChip(
                    label: 'Search: ${state.searchQuery}',
                    onDelete: () => ref.read(adminProductsProvider.notifier).search(''),
                  ),
                if (state.categoryFilter != null)
                  _FilterChip(
                    label: 'Category',
                    onDelete: () => ref.read(adminProductsProvider.notifier).filterByCategory(null),
                  ),
                if (state.activeFilter != null)
                  _FilterChip(
                    label: state.activeFilter! ? 'Active' : 'Inactive',
                    onDelete: () => ref.read(adminProductsProvider.notifier).filterByActive(null),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(adminProductsProvider.notifier).search('');
              ref.read(adminProductsProvider.notifier).filterByCategory(null);
              ref.read(adminProductsProvider.notifier).filterByActive(null);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  AppBar _buildNormalAppBar(BuildContext context, WidgetRef ref, AdminProductsState state) {
    return AppBar(
      title: const Text('Products'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () => _showSearchDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.select_all),
          tooltip: 'Select',
          onPressed: () {
            ref.read(isSelectModeProvider.notifier).state = true;
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'filter_active':
                ref.read(adminProductsProvider.notifier).filterByActive(true);
                break;
              case 'filter_inactive':
                ref.read(adminProductsProvider.notifier).filterByActive(false);
                break;
              case 'refresh':
                ref.read(adminProductsProvider.notifier).loadProducts(refresh: true);
                break;
              case 'export':
                _exportProducts(context, state.products);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'filter_active',
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 20, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Show Active Only'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'filter_inactive',
              child: Row(
                children: [
                  Icon(Icons.cancel, size: 20, color: AppColors.grey500),
                  SizedBox(width: 8),
                  Text('Show Inactive Only'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Export CSV'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  AppBar _buildSelectModeAppBar(
    BuildContext context,
    WidgetRef ref,
    Set<String> selected,
    List<AdminProduct> products,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          ref.read(isSelectModeProvider.notifier).state = false;
          ref.read(selectedProductsProvider.notifier).state = {};
        },
      ),
      title: Text('${selected.length} selected'),
      actions: [
        TextButton(
          onPressed: () {
            final allIds = products.map((p) => p.id).toSet();
            if (selected.length == products.length) {
              ref.read(selectedProductsProvider.notifier).state = {};
            } else {
              ref.read(selectedProductsProvider.notifier).state = allIds;
            }
          },
          child: Text(
            selected.length == products.length ? 'Deselect All' : 'Select All',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    _searchController.text = ref.read(adminProductsProvider).searchQuery;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Product name...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            ref.read(adminProductsProvider.notifier).search(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(adminProductsProvider.notifier).search(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(WidgetRef ref, String productId) {
    HapticFeedback.lightImpact();
    final current = ref.read(selectedProductsProvider);
    if (current.contains(productId)) {
      ref.read(selectedProductsProvider.notifier).state = {...current}..remove(productId);
    } else {
      ref.read(selectedProductsProvider.notifier).state = {...current, productId};
    }
  }

  void _showBulkDeleteDialog(BuildContext context, WidgetRef ref) {
    final selected = ref.read(selectedProductsProvider);
    final count = selected.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: Text('Are you sure you want to delete $count products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Delete each selected product
              for (final productId in selected) {
                await ref.read(adminProductsProvider.notifier).deleteProduct(productId);
              }

              ref.read(selectedProductsProvider.notifier).state = {};
              ref.read(isSelectModeProvider.notifier).state = false;

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count products deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _toggleSelectedStatus(BuildContext context, WidgetRef ref, List<AdminProduct> products) async {
    final selected = ref.read(selectedProductsProvider);
    final count = selected.length;

    // Toggle status for each selected product
    for (final productId in selected) {
      final product = products.firstWhere((p) => p.id == productId);
      await ref.read(adminProductsProvider.notifier).updateProduct(
        productId,
        {'isActive': !product.isActive},
      );
    }

    ref.read(selectedProductsProvider.notifier).state = {};
    ref.read(isSelectModeProvider.notifier).state = false;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toggled status for $count products')),
      );
    }
  }

  void _toggleProductStatus(BuildContext context, WidgetRef ref, AdminProduct product) async {
    final success = await ref.read(adminProductsProvider.notifier).updateProduct(
      product.id,
      {'isActive': !product.isActive},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Product ${product.isActive ? 'deactivated' : 'activated'}'
                : 'Failed to update product',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, AdminProduct product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(adminProductsProvider.notifier).deleteProduct(product.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Product deleted' : 'Failed to delete product'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _exportProducts(BuildContext context, List<AdminProduct> products) {
    // Generate CSV content
    final buffer = StringBuffer();
    buffer.writeln('Name,Category,Price,MRP,Unit,Active');

    for (final product in products) {
      final categoryName = product.category['name'] ?? 'Unknown';
      buffer.writeln(
        '"${product.name}",'
        '"$categoryName",'
        '${product.price},'
        '${product.mrp},'
        '"${product.unit}",'
        '${product.isActive}'
      );
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product data copied to clipboard (CSV format)'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const _FilterChip({
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Bulk actions bar
class _BulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _BulkActionsBar({
    required this.selectedCount,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _ActionChip(
            icon: Icons.toggle_on_outlined,
            label: 'Toggle Status',
            color: AppColors.warning,
            onTap: onToggleStatus,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ActionChip(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: AppColors.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Action chip for bulk actions
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product card with selection support
class _ProductCard extends StatelessWidget {
  final AdminProduct product;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = product.category['name'] ?? 'Unknown';
    final imageUrl = product.images.isNotEmpty ? product.images.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: isSelected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.primary, width: 2),
                )
              : null,
          child: Row(
            children: [
              // Selection checkbox or image
              if (isSelectMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppColors.primary,
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    image: imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl == null
                      ? Icon(Icons.image, color: AppColors.grey400)
                      : null,
                ),
              const SizedBox(width: AppSpacing.md),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$categoryName • ${product.unit}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Text(
                          '\u20B9${product.price.toStringAsFixed(0)}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.priceGreen,
                          ),
                        ),
                        if (product.price < product.mrp) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '\u20B9${product.mrp.toStringAsFixed(0)}',
                            style: AppTypography.bodySmall.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatusBadge(
                          label: product.isActive ? 'Active' : 'Inactive',
                          color: product.isActive ? AppColors.success : AppColors.grey500,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions menu
              if (!isSelectMode)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleStatus();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(product.isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                          const SizedBox(width: 8),
                          Text(product.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
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

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
