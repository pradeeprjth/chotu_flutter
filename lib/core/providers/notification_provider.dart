import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

/// State for notification initialization
class NotificationState {
  final bool isInitialized;
  final String? fcmToken;
  final NotificationPayload? lastPayload;

  const NotificationState({
    this.isInitialized = false,
    this.fcmToken,
    this.lastPayload,
  });

  NotificationState copyWith({
    bool? isInitialized,
    String? fcmToken,
    NotificationPayload? lastPayload,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      fcmToken: fcmToken ?? this.fcmToken,
      lastPayload: lastPayload ?? this.lastPayload,
    );
  }
}

/// Provider for notification state management
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  GoRouter? _router;

  NotificationNotifier(this._notificationService)
      : super(const NotificationState());

  /// Set the router for navigation
  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (state.isInitialized) return;

    try {
      // Set up the notification tap callback
      _notificationService.onNotificationTap = _handleNotificationTap;

      // Initialize the service
      await _notificationService.initialize();

      // Get the token
      final token = await _notificationService.getToken();

      state = state.copyWith(
        isInitialized: true,
        fcmToken: token,
      );

      AppLogger.info('Notification system initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize notifications', e, stack);
    }
  }

  /// Handle notification tap and navigate accordingly
  void _handleNotificationTap(NotificationPayload payload) {
    AppLogger.info('Notification tapped: ${payload.type}');

    state = state.copyWith(lastPayload: payload);

    if (_router == null) {
      AppLogger.warning('Router not set, cannot navigate');
      return;
    }

    final route = _getRouteForPayload(payload);
    if (route != null) {
      AppLogger.info('Navigating to: $route');
      _router!.go(route);
    }
  }

  /// Get the appropriate route for a notification payload
  String? _getRouteForPayload(NotificationPayload payload) {
    switch (payload.type) {
      // Customer order notifications - navigate to order detail
      case NotificationType.orderPlaced:
      case NotificationType.orderConfirmed:
      case NotificationType.orderPreparing:
      case NotificationType.orderOutForDelivery:
      case NotificationType.orderDelivered:
      case NotificationType.orderCancelled:
      case NotificationType.deliveryPartnerAssigned:
        if (payload.orderId != null) {
          return '/orders/${payload.orderId}';
        }
        return '/orders';

      // Admin notifications
      case NotificationType.newUserRegistered:
        return '/admin';
      case NotificationType.newOrderReceived:
        if (payload.orderId != null) {
          return '/admin/orders/${payload.orderId}';
        }
        return '/admin/orders';
      case NotificationType.orderCancelledByCustomer:
        if (payload.orderId != null) {
          return '/admin/orders/${payload.orderId}';
        }
        return '/admin/orders';
      case NotificationType.deliveryPartnerOnline:
        return '/admin/delivery-partners';

      // Delivery partner notifications
      case NotificationType.newDeliveryAssigned:
      case NotificationType.orderReadyForPickup:
        if (payload.orderId != null) {
          return '/delivery/orders/${payload.orderId}';
        }
        return '/delivery';

      case NotificationType.unknown:
        return null;
    }
  }

  /// Subscribe to role-based topics
  Future<void> subscribeToRoleTopics(String role) async {
    switch (role.toLowerCase()) {
      case 'admin':
        await _notificationService.subscribeToTopic('admin_notifications');
        await _notificationService.subscribeToTopic('new_orders');
        await _notificationService.subscribeToTopic('new_users');
        break;
      case 'delivery':
        await _notificationService.subscribeToTopic('delivery_notifications');
        break;
      case 'customer':
      default:
        // Customers get individual notifications via FCM token
        break;
    }
  }

  /// Unsubscribe from all topics (on logout)
  Future<void> unsubscribeFromAllTopics() async {
    await _notificationService.unsubscribeFromTopic('admin_notifications');
    await _notificationService.unsubscribeFromTopic('new_orders');
    await _notificationService.unsubscribeFromTopic('new_users');
    await _notificationService.unsubscribeFromTopic('delivery_notifications');
  }

  /// Remove FCM token on logout
  Future<void> onLogout() async {
    await unsubscribeFromAllTopics();
    await _notificationService.removeToken();
  }

  /// Show test notification (for debugging)
  Future<void> showTestNotification() async {
    await _notificationService.showTestNotification();
  }
}

/// Provider for NotificationNotifier
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service);
});
