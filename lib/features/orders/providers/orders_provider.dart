import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/error_handler.dart';

// Orders state
class OrdersState {
  final List<Order> orders;
  final Order? selectedOrder;
  final bool isLoading;
  final String? error;

  OrdersState({
    this.orders = const [],
    this.selectedOrder,
    this.isLoading = false,
    this.error,
  });

  OrdersState copyWith({
    List<Order>? orders,
    Order? selectedOrder,
    bool? isLoading,
    String? error,
    bool clearSelectedOrder = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      selectedOrder: clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory OrdersState.initial() => OrdersState();

  // Helper getters
  List<Order> get activeOrders =>
      orders.where((o) => o.isActive).toList();

  List<Order> get completedOrders =>
      orders.where((o) => !o.isActive).toList();
}

// Orders notifier
class OrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  OrdersNotifier(this._orderService) : super(OrdersState.initial());

  String _getErrorMessage(dynamic error) {
    return ErrorHandler.getErrorMessage(error);
  }

  // Load customer's orders
  Future<void> loadMyOrders({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final orders = await _orderService.getMyOrders(status: status);
      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  // Load order by ID
  Future<void> loadOrderById(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderService.getOrderById(orderId);
      state = state.copyWith(
        selectedOrder: order,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  // Create order
  Future<Order?> createOrder({
    required int addressIndex,
    required String paymentMethod,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderService.createOrder(
        addressIndex: addressIndex,
        paymentMethod: paymentMethod,
      );

      // Add the new order to the list
      state = state.copyWith(
        orders: [order, ...state.orders],
        selectedOrder: order,
        isLoading: false,
      );

      return order;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedOrder = await _orderService.cancelOrder(orderId, reason: reason);

      // Update the order in the list
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return updatedOrder;
        }
        return order;
      }).toList();

      state = state.copyWith(
        orders: updatedOrders,
        selectedOrder: updatedOrder,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Clear selected order
  void clearSelectedOrder() {
    state = state.copyWith(clearSelectedOrder: true);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return OrdersNotifier(orderService);
});

// Admin orders provider (for admin panel)
class AdminOrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  AdminOrdersNotifier(this._orderService) : super(OrdersState.initial());

  String _getErrorMessage(dynamic error) {
    return ErrorHandler.getErrorMessage(error);
  }

  // Load all orders
  Future<void> loadAllOrders({String? status, int? limit}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final orders = await _orderService.getAllOrders(status: status, limit: limit);
      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedOrder = await _orderService.updateOrderStatus(orderId, status);

      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return updatedOrder;
        }
        return order;
      }).toList();

      state = state.copyWith(
        orders: updatedOrders,
        selectedOrder: updatedOrder,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Assign delivery partner
  Future<bool> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _orderService.assignDeliveryPartner(orderId, deliveryPartnerId);

      // Refresh orders to get updated data
      await loadAllOrders();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Load order by ID
  Future<void> loadOrderById(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderService.getOrderById(orderId);
      state = state.copyWith(
        selectedOrder: order,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final adminOrdersProvider = StateNotifierProvider<AdminOrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return AdminOrdersNotifier(orderService);
});

// Delivery partner orders provider
class DeliveryOrdersNotifier extends StateNotifier<OrdersState> {
  final OrderService _orderService;

  DeliveryOrdersNotifier(this._orderService) : super(OrdersState.initial());

  String _getErrorMessage(dynamic error) {
    return ErrorHandler.getErrorMessage(error);
  }

  // Load assigned deliveries
  Future<void> loadMyDeliveries({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final orders = await _orderService.getMyDeliveries(status: status);
      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  // Update delivery status
  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _orderService.updateDeliveryStatus(orderId, status);

      // Refresh deliveries
      await loadMyDeliveries();

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      return false;
    }
  }

  // Load order by ID
  Future<void> loadOrderById(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderService.getOrderById(orderId);
      state = state.copyWith(
        selectedOrder: order,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final deliveryOrdersProvider = StateNotifierProvider<DeliveryOrdersNotifier, OrdersState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return DeliveryOrdersNotifier(orderService);
});
