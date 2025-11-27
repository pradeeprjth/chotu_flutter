import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/admin_service.dart';
import 'providers/admin_inventory_provider.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) {
      final state = ref.read(adminInventoryProvider);
      if (!state.isLoading &&
          state.pagination != null &&
          state.pagination!.page < state.pagination!.totalPages) {
        ref.read(adminInventoryProvider.notifier).loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(adminInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          // Low stock filter toggle
          IconButton(
            icon: Icon(
              inventoryState.lowStockOnly ? Icons.warning : Icons.warning_outlined,
              color: inventoryState.lowStockOnly ? AppColors.warning : null,
            ),
            tooltip: inventoryState.lowStockOnly ? 'Show All' : 'Show Low Stock Only',
            onPressed: () {
              ref.read(adminInventoryProvider.notifier).toggleLowStockFilter();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(adminInventoryProvider.notifier).loadInventory(refresh: true);
            },
          ),
        ],
      ),
      body: inventoryState.isLoading && inventoryState.inventory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : inventoryState.error != null && inventoryState.inventory.isEmpty
              ? _buildError(inventoryState.error!)
              : Column(
                  children: [
                    // Summary bar
                    _buildSummaryBar(inventoryState),
                    // Inventory list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref.read(adminInventoryProvider.notifier).loadInventory(refresh: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: inventoryState.inventory.length + (inventoryState.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= inventoryState.inventory.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = inventoryState.inventory[index];
                            return _InventoryItemCard(
                              item: item,
                              onUpdateStock: () => _showUpdateStockDialog(context, item),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
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
          Text('Failed to load inventory', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(error, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.read(adminInventoryProvider.notifier).loadInventory(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(AdminInventoryState state) {
    final totalItems = state.inventory.length;
    final lowStockCount = state.inventory.where((item) => item.available <= 10).length;
    final outOfStockCount = state.inventory.where((item) => item.available <= 0).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Total Items',
            value: '$totalItems',
            color: AppColors.primary,
          ),
          _SummaryItem(
            label: 'Low Stock',
            value: '$lowStockCount',
            color: AppColors.warning,
          ),
          _SummaryItem(
            label: 'Out of Stock',
            value: '$outOfStockCount',
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  void _showUpdateStockDialog(BuildContext context, AdminInventoryItem item) {
    final controller = TextEditingController(text: item.quantity.toString());
    final productName = item.product['name']?.toString() ?? 'Unknown Product';
    final productId = item.product['_id']?.toString() ?? item.product['id']?.toString();

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update: Product ID not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName, style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                hintText: 'Enter new quantity',
                suffixText: 'units',
                border: const OutlineInputBorder(),
                helperText: 'Current: ${item.quantity}, Reserved: ${item.reserved}',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(controller.text);
              if (newQuantity != null && newQuantity >= 0) {
                Navigator.pop(context);

                final success = await ref.read(adminInventoryProvider.notifier).updateStock(productId, newQuantity);

                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Stock updated successfully' : 'Failed to update stock'),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final AdminInventoryItem item;
  final VoidCallback onUpdateStock;

  const _InventoryItemCard({
    required this.item,
    required this.onUpdateStock,
  });

  @override
  Widget build(BuildContext context) {
    final productName = item.product['name']?.toString() ?? 'Unknown Product';

    // Handle category which can be Map, String, or null
    String categoryName = 'Unknown';
    final categoryData = item.product['category'];
    if (categoryData is Map<String, dynamic>) {
      categoryName = categoryData['name']?.toString() ?? 'Unknown';
    } else if (categoryData is String) {
      categoryName = categoryData;
    }

    // Handle images which can be List or null
    String? imageUrl;
    final imagesData = item.product['images'];
    if (imagesData is List && imagesData.isNotEmpty) {
      imageUrl = imagesData[0]?.toString();
    }

    final isLowStock = item.available <= 10 && item.available > 0;
    final isOutOfStock = item.available <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Product image
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
                  ? Icon(Icons.inventory_2, color: AppColors.grey400)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    categoryName,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _StockBadge(
                        label: isOutOfStock
                            ? 'Out of Stock'
                            : isLowStock
                                ? 'Low Stock'
                                : 'In Stock',
                        color: isOutOfStock
                            ? AppColors.error
                            : isLowStock
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                      if (item.lastRestocked != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Restocked ${DateFormat('MMM d').format(item.lastRestocked!)}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Stock info and action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.available}',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock
                        ? AppColors.error
                        : isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ),
                Text(
                  'available',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (item.reserved > 0)
                  Text(
                    '${item.reserved} reserved',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.info,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),

            // Update button
            IconButton(
              onPressed: onUpdateStock,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Update Stock',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StockBadge({
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
        color: color.withValues(alpha: 0.1),
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
