import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/catalog_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/app_logger.dart';

/// Sort options for search results
enum SortOption {
  relevance('Relevance', null, null),
  priceLowToHigh('Price: Low to High', 'sellingPrice', 'asc'),
  priceHighToLow('Price: High to Low', 'sellingPrice', 'desc'),
  nameAZ('Name: A to Z', 'name', 'asc'),
  nameZA('Name: Z to A', 'name', 'desc'),
  newest('Newest First', 'createdAt', 'desc');

  final String label;
  final String? sortBy;
  final String? sortOrder;

  const SortOption(this.label, this.sortBy, this.sortOrder);
}

/// Search filters
class SearchFilters {
  final String? categoryId;
  final String? categoryName;
  final double? minPrice;
  final double? maxPrice;
  final SortOption sortOption;

  const SearchFilters({
    this.categoryId,
    this.categoryName,
    this.minPrice,
    this.maxPrice,
    this.sortOption = SortOption.relevance,
  });

  SearchFilters copyWith({
    String? categoryId,
    String? categoryName,
    double? minPrice,
    double? maxPrice,
    SortOption? sortOption,
    bool clearCategory = false,
    bool clearPriceRange = false,
  }) {
    return SearchFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      minPrice: clearPriceRange ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPriceRange ? null : (maxPrice ?? this.maxPrice),
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasFilters =>
      categoryId != null || minPrice != null || maxPrice != null;

  int get activeFilterCount {
    int count = 0;
    if (categoryId != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  SearchFilters clear() {
    return SearchFilters(sortOption: sortOption);
  }
}

/// Search state
class SearchState {
  final String query;
  final List<Product> results;
  final bool isLoading;
  final String? error;
  final SearchFilters filters;
  final List<String> recentSearches;
  final List<String> suggestions;
  final bool hasMore;
  final int currentPage;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.filters = const SearchFilters(),
    this.recentSearches = const [],
    this.suggestions = const [],
    this.hasMore = true,
    this.currentPage = 1,
  });

  SearchState copyWith({
    String? query,
    List<Product>? results,
    bool? isLoading,
    String? error,
    SearchFilters? filters,
    List<String>? recentSearches,
    List<String>? suggestions,
    bool? hasMore,
    int? currentPage,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filters: filters ?? this.filters,
      recentSearches: recentSearches ?? this.recentSearches,
      suggestions: suggestions ?? this.suggestions,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  bool get isEmpty => results.isEmpty && !isLoading && query.isNotEmpty;
  bool get hasResults => results.isNotEmpty;
  bool get showRecentSearches => query.isEmpty && recentSearches.isNotEmpty;
}

/// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final CatalogService _catalogService;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  SearchNotifier(this._catalogService) : super(const SearchState()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      state = state.copyWith(recentSearches: searches);
    } catch (e) {
      AppLogger.warning('Failed to load recent searches', e);
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, state.recentSearches);
    } catch (e) {
      AppLogger.warning('Failed to save recent searches', e);
    }
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    final updatedSearches = [
      trimmedQuery,
      ...state.recentSearches.where((s) => s != trimmedQuery),
    ].take(_maxRecentSearches).toList();

    state = state.copyWith(recentSearches: updatedSearches);
    _saveRecentSearches();
  }

  Future<void> search(String query, {bool addToRecent = true}) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      state = state.copyWith(
        query: '',
        results: [],
        isLoading: false,
        error: null,
        hasMore: true,
        currentPage: 1,
      );
      return;
    }

    if (trimmedQuery.length < 2) {
      state = state.copyWith(
        query: trimmedQuery,
        error: 'Search query must be at least 2 characters',
      );
      return;
    }

    state = state.copyWith(
      query: trimmedQuery,
      isLoading: true,
      error: null,
      results: [],
      currentPage: 1,
    );

    try {
      final results = await _catalogService.advancedSearch(
        query: trimmedQuery,
        categoryId: state.filters.categoryId,
        minPrice: state.filters.minPrice,
        maxPrice: state.filters.maxPrice,
        sortBy: state.filters.sortOption.sortBy,
        sortOrder: state.filters.sortOption.sortOrder,
        page: 1,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length >= 20,
        currentPage: 2,
      );

      AppLogger.logSearch(trimmedQuery, results.length);

      if (addToRecent && results.isNotEmpty) {
        _addToRecentSearches(trimmedQuery);
      }
    } catch (e) {
      AppLogger.error('Search failed', e);
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || state.query.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      final results = await _catalogService.advancedSearch(
        query: state.query,
        categoryId: state.filters.categoryId,
        minPrice: state.filters.minPrice,
        maxPrice: state.filters.maxPrice,
        sortBy: state.filters.sortOption.sortBy,
        sortOrder: state.filters.sortOption.sortOrder,
        page: state.currentPage,
      );

      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        hasMore: results.length >= 20,
        currentPage: state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
    if (state.query.isNotEmpty) {
      search(state.query, addToRecent: false);
    }
  }

  void setCategory(String? categoryId, String? categoryName) {
    final newFilters = state.filters.copyWith(
      categoryId: categoryId,
      categoryName: categoryName,
      clearCategory: categoryId == null,
    );
    updateFilters(newFilters);
  }

  void setPriceRange(double? minPrice, double? maxPrice) {
    final newFilters = state.filters.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      clearPriceRange: minPrice == null && maxPrice == null,
    );
    updateFilters(newFilters);
  }

  void setSortOption(SortOption sortOption) {
    final newFilters = state.filters.copyWith(sortOption: sortOption);
    updateFilters(newFilters);
  }

  void clearFilters() {
    final newFilters = state.filters.clear();
    updateFilters(newFilters);
  }

  void clearSearch() {
    state = state.copyWith(
      query: '',
      results: [],
      isLoading: false,
      error: null,
      hasMore: true,
      currentPage: 1,
    );
  }

  void removeFromRecentSearches(String query) {
    final updatedSearches =
        state.recentSearches.where((s) => s != query).toList();
    state = state.copyWith(recentSearches: updatedSearches);
    _saveRecentSearches();
  }

  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      AppLogger.warning('Failed to clear recent searches', e);
    }
  }

  void useRecentSearch(String query) {
    search(query, addToRecent: false);
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final catalogService = ref.watch(catalogServiceProvider);
  return SearchNotifier(catalogService);
});
