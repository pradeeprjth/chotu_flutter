import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/admin_service.dart';

/// Admin orders state
class AdminOrdersState {
  final bool isLoading;
  final String? error;
  final List<AdminOrder> orders;
  final Pagination? pagination;
  final String? statusFilter;
  final String searchQuery;

  AdminOrdersState({
    this.isLoading = false,
    this.error,
    this.orders = const [],
    this.pagination,
    this.statusFilter,
    this.searchQuery = '',
  });

  AdminOrdersState copyWith({
    bool? isLoading,
    String? error,
    List<AdminOrder>? orders,
    Pagination? pagination,
    String? statusFilter,
    String? searchQuery,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return AdminOrdersState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      orders: orders ?? this.orders,
      pagination: pagination ?? this.pagination,
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Admin orders notifier
class AdminOrdersNotifier extends StateNotifier<AdminOrdersState> {
  final AdminService _adminService;

  AdminOrdersNotifier(this._adminService) : super(AdminOrdersState()) {
    loadOrders();
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _adminService.getOrders(
        status: state.statusFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        orders: result.orders,
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
      final result = await _adminService.getOrders(
        status: state.statusFilter,
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        page: state.pagination!.page + 1,
        limit: 20,
      );

      state = state.copyWith(
        isLoading: false,
        orders: [...state.orders, ...result.orders],
        pagination: result.pagination,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void filterByStatus(String? status) {
    if (status == state.statusFilter) return;

    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      orders: [],
      pagination: null,
    );
    loadOrders();
  }

  void search(String query) {
    if (query == state.searchQuery) return;

    state = state.copyWith(
      searchQuery: query,
      orders: [],
      pagination: null,
    );
    loadOrders();
  }

  Future<bool> updateOrderStatus(String orderId, String status, {String? note}) async {
    try {
      await _adminService.updateOrderStatus(orderId, status, note: note);

      // Update the order in the list
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          // Create a new order with updated status
          return AdminOrder(
            id: order.id,
            orderNumber: order.orderNumber,
            user: order.user,
            items: order.items,
            totalAmount: order.totalAmount,
            deliveryAddress: order.deliveryAddress,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            orderStatus: status,
            deliveryPartner: order.deliveryPartner,
            deliveryAssignedAt: order.deliveryAssignedAt,
            deliveredAt: status == 'DELIVERED' ? DateTime.now() : order.deliveredAt,
            createdAt: order.createdAt,
          );
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> assignDeliveryPartner(String orderId, String partnerId) async {
    try {
      await _adminService.assignDeliveryPartner(orderId, partnerId);
      loadOrders(refresh: true);
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

/// Admin orders provider instance
final adminOrdersProvider = StateNotifierProvider<AdminOrdersNotifier, AdminOrdersState>(
  (ref) {
    final adminService = ref.watch(adminServiceProvider);
    return AdminOrdersNotifier(adminService);
  },
);

/// Single order detail provider
final adminOrderDetailProvider = FutureProvider.family<AdminOrder, String>((ref, orderId) async {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getOrderById(orderId);
});
