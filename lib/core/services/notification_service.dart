import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../utils/app_logger.dart';

/// Notification types that can be received
enum NotificationType {
  // Customer notifications
  orderPlaced,
  orderConfirmed,
  orderPreparing,
  orderOutForDelivery,
  orderDelivered,
  orderCancelled,
  deliveryPartnerAssigned,

  // Admin notifications
  newUserRegistered,
  newOrderReceived,
  orderCancelledByCustomer,
  deliveryPartnerOnline,

  // Delivery partner notifications
  newDeliveryAssigned,
  orderReadyForPickup,

  // Unknown
  unknown,
}

/// Represents a notification payload
class NotificationPayload {
  final NotificationType type;
  final String? orderId;
  final String? orderNumber;
  final String? userId;
  final String? userName;
  final String? status;
  final Map<String, dynamic> extras;

  NotificationPayload({
    required this.type,
    this.orderId,
    this.orderNumber,
    this.userId,
    this.userName,
    this.status,
    this.extras = const {},
  });

  factory NotificationPayload.fromData(Map<String, dynamic> data) {
    return NotificationPayload(
      type: _parseNotificationType(data['type'] as String?),
      orderId: data['orderId'] as String?,
      orderNumber: data['orderNumber'] as String?,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      status: data['status'] as String?,
      extras: data,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'ORDER_PLACED':
        return NotificationType.orderPlaced;
      case 'ORDER_CONFIRMED':
        return NotificationType.orderConfirmed;
      case 'ORDER_PREPARING':
        return NotificationType.orderPreparing;
      case 'ORDER_OUT_FOR_DELIVERY':
        return NotificationType.orderOutForDelivery;
      case 'ORDER_DELIVERED':
        return NotificationType.orderDelivered;
      case 'ORDER_CANCELLED':
        return NotificationType.orderCancelled;
      case 'DELIVERY_PARTNER_ASSIGNED':
        return NotificationType.deliveryPartnerAssigned;
      case 'NEW_USER_REGISTERED':
        return NotificationType.newUserRegistered;
      case 'NEW_ORDER_RECEIVED':
        return NotificationType.newOrderReceived;
      case 'ORDER_CANCELLED_BY_CUSTOMER':
        return NotificationType.orderCancelledByCustomer;
      case 'DELIVERY_PARTNER_ONLINE':
        return NotificationType.deliveryPartnerOnline;
      case 'NEW_DELIVERY_ASSIGNED':
        return NotificationType.newDeliveryAssigned;
      case 'ORDER_READY_FOR_PICKUP':
        return NotificationType.orderReadyForPickup;
      default:
        return NotificationType.unknown;
    }
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.info('Handling background message: ${message.messageId}');
}

/// Service to handle push notifications
class NotificationService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback for handling notification taps
  void Function(NotificationPayload)? onNotificationTap;

  // Storage keys
  static const String _fcmTokenKey = 'fcm_token';

  // Notification channel details
  static const String _channelId = 'chotu_notifications';
  static const String _channelName = 'Chotu Notifications';
  static const String _channelDesc = 'Notifications for order updates and more';

  NotificationService(this._apiClient);

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup message handlers
      _setupMessageHandlers();

      // Get and register FCM token
      await _getAndRegisterToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      AppLogger.info('NotificationService initialized successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize NotificationService', e, stack);
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    AppLogger.info('Notification permission: ${settings.authorizationStatus}');
    return granted;
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Setup FCM message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated message opened
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from terminated state via notification
    _checkInitialMessage();
  }

  /// Check if app was launched from a notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App launched from notification');
      _handleNotificationTap(initialMessage.data);
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Chotu',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle when user taps on notification (from background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('Notification opened app: ${message.messageId}');
    _handleNotificationTap(message.data);
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationTap(data);
      } catch (e) {
        AppLogger.error('Failed to parse notification payload', e);
      }
    }
  }

  /// Process notification tap and navigate accordingly
  void _handleNotificationTap(Map<String, dynamic> data) {
    final payload = NotificationPayload.fromData(data);
    onNotificationTap?.call(payload);
  }

  /// Show a local notification (for foreground)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Get FCM token and register with backend
  Future<String?> _getAndRegisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: ${token.substring(0, 20)}...');
        await _registerTokenWithBackend(token);
        await _storage.write(key: _fcmTokenKey, value: token);
      }
      return token;
    } catch (e, stack) {
      AppLogger.error('Failed to get FCM token', e, stack);
      return null;
    }
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    AppLogger.info('FCM Token refreshed');
    final oldToken = await _storage.read(key: _fcmTokenKey);
    if (oldToken != null && oldToken != newToken) {
      await _updateTokenOnBackend(oldToken, newToken);
    } else {
      await _registerTokenWithBackend(newToken);
    }
    await _storage.write(key: _fcmTokenKey, value: newToken);
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await _apiClient.post('/notifications/register-token', data: {
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
      AppLogger.info('FCM token registered with backend');
    } catch (e) {
      AppLogger.warning('Failed to register FCM token with backend: $e');
      // Don't throw - we can retry later
    }
  }

  /// Update FCM token on backend (when refreshed)
  Future<void> _updateTokenOnBackend(String oldToken, String newToken) async {
    try {
      await _apiClient.put('/notifications/update-token', data: {
        'oldToken': oldToken,
        'newToken': newToken,
      });
      AppLogger.info('FCM token updated on backend');
    } catch (e) {
      AppLogger.warning('Failed to update FCM token on backend: $e');
      // Try to register new token instead
      await _registerTokenWithBackend(newToken);
    }
  }

  /// Remove FCM token from backend (on logout)
  Future<void> removeToken() async {
    try {
      final token = await _storage.read(key: _fcmTokenKey);
      if (token != null) {
        await _apiClient.delete('/notifications/remove-token');
        await _storage.delete(key: _fcmTokenKey);
        AppLogger.info('FCM token removed');
      }
    } catch (e) {
      AppLogger.warning('Failed to remove FCM token: $e');
    }
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic (e.g., 'admin_notifications')
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', e);
    }
  }

  /// Show a test notification (for debugging)
  Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from Chotu',
      payload: jsonEncode({'type': 'TEST'}),
    );
  }
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationService(apiClient);
});
