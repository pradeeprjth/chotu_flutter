import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

/// Admin inventory state
class AdminInventoryState {
  final bool isLoading;
  final String? error;
  final List<AdminInventoryItem> inventory;
  final Pagination? pagination;
  final bool lowStockOnly;

  AdminInventoryState({
    this.isLoading = false,
    this.error,
    this.inventory = const [],
    this.pagination,
    this.lowStockOnly = false,
  });

  AdminInventoryState copyWith({
    bool? isLoading,
    String? error,
    List<AdminInventoryItem>? inventory,
    Pagination? pagination,
    bool? lowStockOnly,
    bool clearError = false,
  }) {
    return AdminInventoryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      inventory: inventory ?? this.inventory,
      pagination: pagination ?? this.pagination,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }
}

/// Admin inventory notifier
class AdminInventoryNotifier extends StateNotifier<AdminInventoryState> {
  final AdminService _adminService;

  AdminInventoryNotifier(this._adminService) : super(AdminInventoryState()) {
    loadInventory();
  }

  Future<void> loadInventory({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _adminService.getInventory(
        lowStockOnly: state.lowStockOnly,
        page: 1,
        limit: 50,
      );

      state = state.copyWith(
        isLoading: false,
        inventory: result.inventory,
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading) return;
    if (state.pagination == null) return;
    if (state.pagination!.page >= state.pagination!.totalPages) return;

    state = state.copyWith(isLoading: true);

    try {
      final result = await _adminService.getInventory(
        lowStockOnly: state.lowStockOnly,
        page: state.pagination!.page + 1,
        limit: 50,
      );

      state = state.copyWith(
        isLoading: false,
        inventory: [...state.inventory, ...result.inventory],
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void toggleLowStockFilter() {
    state = state.copyWith(
      lowStockOnly: !state.lowStockOnly,
      inventory: [],
      pagination: null,
    );
    loadInventory();
  }

  Future<bool> updateStock(String productId, int quantity) async {
    try {
      await _adminService.updateInventory(productId, quantity: quantity);

      // Update locally
      final updatedInventory = state.inventory.map((item) {
        final itemProductId = item.product['_id']?.toString() ?? item.product['id']?.toString();
        if (itemProductId == productId) {
          return AdminInventoryItem(
            id: item.id,
            product: item.product,
            quantity: quantity,
            reserved: item.reserved,
            available: quantity - item.reserved,
            lastRestocked: DateTime.now(),
          );
        }
        return item;
      }).toList();

      state = state.copyWith(inventory: updatedInventory);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred';
  }
}

/// Admin inventory provider instance
final adminInventoryProvider = StateNotifierProvider<AdminInventoryNotifier, AdminInventoryState>(
  (ref) {
    final adminService = ref.watch(adminServiceProvider);
    return AdminInventoryNotifier(adminService);
  },
);
