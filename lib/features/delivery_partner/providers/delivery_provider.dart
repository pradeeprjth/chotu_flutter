import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/delivery_partner_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/services/delivery_service.dart';
import '../../../core/utils/error_handler.dart';

/// Delivery partner state
class DeliveryState {
  final DeliveryPartnerProfile? profile;
  final List<Order> orders;
  final bool isLoadingProfile;
  final bool isLoadingOrders;
  final bool isUpdatingStatus;
  final String? profileError;
  final String? ordersError;

  DeliveryState({
    this.profile,
    this.orders = const [],
    this.isLoadingProfile = false,
    this.isLoadingOrders = false,
    this.isUpdatingStatus = false,
    this.profileError,
    this.ordersError,
  });

  DeliveryState copyWith({
    DeliveryPartnerProfile? profile,
    List<Order>? orders,
    bool? isLoadingProfile,
    bool? isLoadingOrders,
    bool? isUpdatingStatus,
    String? profileError,
    String? ordersError,
    bool clearProfile = false,
    bool clearProfileError = false,
    bool clearOrdersError = false,
  }) {
    return DeliveryState(
      profile: clearProfile ? null : (profile ?? this.profile),
      orders: orders ?? this.orders,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      isLoadingOrders: isLoadingOrders ?? this.isLoadingOrders,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      profileError: clearProfileError ? null : (profileError ?? this.profileError),
      ordersError: clearOrdersError ? null : (ordersError ?? this.ordersError),
    );
  }

  // Computed properties
  DeliveryStats get stats => profile?.stats ?? DeliveryStats.empty();

  List<Order> get assignedOrders =>
      orders.where((o) => o.status == 'PREPARING' || o.status == 'CONFIRMED').toList();

  List<Order> get enRouteOrders =>
      orders.where((o) => o.status == 'OUT_FOR_DELIVERY').toList();

  List<Order> get completedOrders =>
      orders.where((o) => o.status == 'DELIVERED').toList();

  int get assignedCount => assignedOrders.length;
  int get enRouteCount => enRouteOrders.length;
  int get completedCount => completedOrders.length;

  bool get isAvailable => profile?.isAvailable ?? false;
}

/// Delivery partner notifier
class DeliveryNotifier extends StateNotifier<DeliveryState> {
  final DeliveryService _deliveryService;

  DeliveryNotifier(this._deliveryService) : super(DeliveryState());

  /// Load delivery partner profile with stats
  Future<void> loadProfile() async {
    state = state.copyWith(isLoadingProfile: true, clearProfileError: true);

    try {
      final profile = await _deliveryService.getProfile();
      state = state.copyWith(profile: profile, isLoadingProfile: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        profileError: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  /// Load assigned deliveries
  Future<void> loadDeliveries({String? status}) async {
    state = state.copyWith(isLoadingOrders: true, clearOrdersError: true);

    try {
      final orders = await _deliveryService.getMyDeliveries(status: status);
      state = state.copyWith(orders: orders, isLoadingOrders: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingOrders: false,
        ordersError: ErrorHandler.getErrorMessage(e),
      );
    }
  }

  /// Load both profile and deliveries
  Future<void> loadAll() async {
    await Future.wait([
      loadProfile(),
      loadDeliveries(),
    ]);
  }

  /// Update delivery status
  Future<bool> updateDeliveryStatus(String orderId, String newStatus) async {
    state = state.copyWith(isUpdatingStatus: true);

    try {
      final updatedOrder = await _deliveryService.updateDeliveryStatus(orderId, newStatus);

      // Update the order in the list
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return updatedOrder;
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders, isUpdatingStatus: false);

      // Reload profile to get updated stats
      loadProfile();

      return true;
    } catch (e) {
      state = state.copyWith(isUpdatingStatus: false);
      return false;
    }
  }

  /// Toggle availability status
  Future<bool> toggleAvailability() async {
    if (state.profile == null) return false;

    final newAvailability = !state.profile!.isAvailable;
    state = state.copyWith(isLoadingProfile: true);

    try {
      final updatedProfile = await _deliveryService.toggleAvailability(newAvailability);
      state = state.copyWith(profile: updatedProfile, isLoadingProfile: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoadingProfile: false,
        profileError: ErrorHandler.getErrorMessage(e),
      );
      return false;
    }
  }

  /// Clear errors
  void clearErrors() {
    state = state.copyWith(clearProfileError: true, clearOrdersError: true);
  }

  /// Clear state (on logout)
  void clearState() {
    state = DeliveryState();
  }
}

/// Provider for delivery state
final deliveryProvider = StateNotifierProvider<DeliveryNotifier, DeliveryState>((ref) {
  final deliveryService = ref.watch(deliveryServiceProvider);
  return DeliveryNotifier(deliveryService);
});
