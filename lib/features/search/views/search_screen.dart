import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/colors.dart';
import '../../../app/typography.dart';
import '../../../app/design_tokens.dart';
import '../../../core/models/product_model.dart';
import '../providers/search_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../catalog/providers/catalog_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load categories for filter
      ref.read(categoriesProvider.notifier).loadCategories();

      // If there's an initial query, search
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        ref.read(searchProvider.notifier).search(widget.initialQuery!);
      } else {
        // Auto-focus search field if no initial query
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchProvider.notifier).search(query);
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _buildSearchField(),
        actions: [
          // Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                  color: searchState.filters.hasFilters
                      ? AppColors.primary
                      : null,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: 'Filters',
              ),
              if (searchState.filters.activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${searchState.filters.activeFilterCount}',
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
      body: Column(
        children: [
          // Filter panel
          if (_showFilters)
            _FilterPanel(
              searchState: searchState,
              categories: categoriesState.categories,
              onClose: () => setState(() => _showFilters = false),
            ),

          // Active filters chips
          if (searchState.filters.hasFilters && !_showFilters)
            _ActiveFiltersBar(searchState: searchState),

          // Main content
          Expanded(
            child: _buildBody(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: AppColors.grey500),
          prefixIcon: Icon(Icons.search, color: AppColors.grey500, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.grey500, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchProvider.notifier).clearSearch();
                    _searchFocusNode.requestFocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.grey800
              : AppColors.grey100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _performSearch(),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildBody(SearchState searchState) {
    // Show recent searches if no query
    if (searchState.query.isEmpty) {
      return _buildRecentSearches(searchState);
    }

    // Show loading
    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error
    if (searchState.error != null && searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(searchState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty results
    if (searchState.isEmpty) {
      return _buildEmptyResults(searchState.query);
    }

    // Show results
    return _buildSearchResults(searchState);
  }

  Widget _buildRecentSearches(SearchState searchState) {
    if (searchState.recentSearches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              'Search for products',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Find what you\'re looking for',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: AppTypography.headlineSmall,
            ),
            TextButton(
              onPressed: () {
                ref.read(searchProvider.notifier).clearRecentSearches();
              },
              child: const Text('Clear All'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...searchState.recentSearches.map((query) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  ref.read(searchProvider.notifier).removeFromRecentSearches(query);
                },
              ),
              onTap: () {
                _searchController.text = query;
                ref.read(searchProvider.notifier).useRecentSearch(query);
              },
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }

  Widget _buildEmptyResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or remove filters',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (ref.read(searchProvider).filters.hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ref.read(searchProvider.notifier).clearFilters();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    return Column(
      children: [
        // Results count and sort
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${searchState.results.length} results',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              _SortDropdown(
                currentSort: searchState.filters.sortOption,
                onChanged: (sort) {
                  ref.read(searchProvider.notifier).setSortOption(sort);
                },
              ),
            ],
          ),
        ),

        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: searchState.results.length + (searchState.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == searchState.results.length) {
                // Load more trigger
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(searchProvider.notifier).loadMore();
                });
                return const Center(child: CircularProgressIndicator());
              }
              return _SearchResultCard(product: searchState.results[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _FilterPanel extends ConsumerWidget {
  final SearchState searchState;
  final List categories;
  final VoidCallback onClose;

  const _FilterPanel({
    required this.searchState,
    required this.categories,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: AppColors.grey200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppTypography.headlineSmall),
              Row(
                children: [
                  if (searchState.filters.hasFilters)
                    TextButton(
                      onPressed: () {
                        ref.read(searchProvider.notifier).clearFilters();
                      },
                      child: const Text('Clear All'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Category filter
          Text('Category', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: searchState.filters.categoryId == null,
                onSelected: (_) {
                  ref.read(searchProvider.notifier).setCategory(null, null);
                },
              ),
              ...categories.map((cat) => FilterChip(
                    label: Text(cat.name),
                    selected: searchState.filters.categoryId == cat.id,
                    onSelected: (_) {
                      if (searchState.filters.categoryId == cat.id) {
                        ref.read(searchProvider.notifier).setCategory(null, null);
                      } else {
                        ref.read(searchProvider.notifier).setCategory(cat.id, cat.name);
                      }
                    },
                  )),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Price range filter
          Text('Price Range', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          _PriceRangeFilter(
            minPrice: searchState.filters.minPrice,
            maxPrice: searchState.filters.maxPrice,
            onChanged: (min, max) {
              ref.read(searchProvider.notifier).setPriceRange(min, max);
            },
          ),
        ],
      ),
    );
  }
}

class _PriceRangeFilter extends StatefulWidget {
  final double? minPrice;
  final double? maxPrice;
  final void Function(double?, double?) onChanged;

  const _PriceRangeFilter({
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
  });

  @override
  State<_PriceRangeFilter> createState() => _PriceRangeFilterState();
}

class _PriceRangeFilterState extends State<_PriceRangeFilter> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.minPrice?.toStringAsFixed(0) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.maxPrice?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void didUpdateWidget(_PriceRangeFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.minPrice != oldWidget.minPrice) {
      _minController.text = widget.minPrice?.toStringAsFixed(0) ?? '';
    }
    if (widget.maxPrice != oldWidget.maxPrice) {
      _maxController.text = widget.maxPrice?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _applyPriceRange() {
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);
    widget.onChanged(min, max);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min',
              prefixText: '\u20B9 ',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            onSubmitted: (_) => _applyPriceRange(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Text('to'),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _maxController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max',
              prefixText: '\u20B9 ',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            onSubmitted: (_) => _applyPriceRange(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ElevatedButton(
          onPressed: _applyPriceRange,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ActiveFiltersBar extends ConsumerWidget {
  final SearchState searchState;

  const _ActiveFiltersBar({required this.searchState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (searchState.filters.categoryName != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Chip(
                  label: Text(searchState.filters.categoryName!),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    ref.read(searchProvider.notifier).setCategory(null, null);
                  },
                ),
              ),
            if (searchState.filters.minPrice != null ||
                searchState.filters.maxPrice != null)
              Chip(
                label: Text(_getPriceRangeLabel(
                  searchState.filters.minPrice,
                  searchState.filters.maxPrice,
                )),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(searchProvider.notifier).setPriceRange(null, null);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getPriceRangeLabel(double? min, double? max) {
    if (min != null && max != null) {
      return '\u20B9${min.toStringAsFixed(0)} - \u20B9${max.toStringAsFixed(0)}';
    } else if (min != null) {
      return 'Above \u20B9${min.toStringAsFixed(0)}';
    } else if (max != null) {
      return 'Below \u20B9${max.toStringAsFixed(0)}';
    }
    return '';
  }
}

class _SortDropdown extends StatelessWidget {
  final SortOption currentSort;
  final void Function(SortOption) onChanged;

  const _SortDropdown({
    required this.currentSort,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: currentSort,
      onSelected: onChanged,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentSort.label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.primary),
        ],
      ),
      itemBuilder: (context) => SortOption.values
          .map((option) => PopupMenuItem(
                value: option,
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight:
                        option == currentSort ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SearchResultCard extends ConsumerWidget {
  final Product product;

  const _SearchResultCard({required this.product});

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
