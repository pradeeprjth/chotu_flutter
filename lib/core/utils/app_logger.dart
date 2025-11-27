import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging service for the app
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.trace : Level.warning,
  );

  /// Log a trace/verbose message
  static void trace(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal/critical error
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // Analytics events
  static void logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    if (kDebugMode) {
      _logger.i('Analytics Event: $eventName', error: parameters);
    }
    // TODO: Send to analytics service (Firebase, Mixpanel, etc.)
  }

  /// Log screen view
  static void logScreenView(String screenName, [String? screenClass]) {
    if (kDebugMode) {
      _logger.i('Screen View: $screenName${screenClass != null ? ' ($screenClass)' : ''}');
    }
    // TODO: Send to analytics service
  }

  /// Log user action
  static void logUserAction(String action, [Map<String, dynamic>? details]) {
    if (kDebugMode) {
      _logger.d('User Action: $action', error: details);
    }
    // TODO: Send to analytics service
  }

  /// Log API call
  static void logApiCall(String method, String endpoint, {int? statusCode, int? duration}) {
    final details = <String, dynamic>{
      'method': method,
      'endpoint': endpoint,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': '${duration}ms',
    };

    if (kDebugMode) {
      if (statusCode != null && statusCode >= 400) {
        _logger.w('API Error: $method $endpoint', error: details);
      } else {
        _logger.d('API Call: $method $endpoint', error: details);
      }
    }
  }

  /// Log cart action
  static void logCartAction(String action, String productId, {int? quantity}) {
    logEvent('cart_$action', {
      'product_id': productId,
      if (quantity != null) 'quantity': quantity,
    });
  }

  /// Log order action
  static void logOrderAction(String action, String orderId) {
    logEvent('order_$action', {
      'order_id': orderId,
    });
  }

  /// Log authentication event
  static void logAuthEvent(String event, {String? method}) {
    logEvent('auth_$event', {
      if (method != null) 'method': method,
    });
  }

  /// Log search query
  static void logSearch(String query, int resultCount) {
    logEvent('search', {
      'query': query,
      'result_count': resultCount,
    });
  }

  /// Log checkout step
  static void logCheckoutStep(int step, String stepName) {
    logEvent('checkout_step', {
      'step': step,
      'step_name': stepName,
    });
  }

  /// Log purchase
  static void logPurchase(String orderId, double amount, String currency, int itemCount) {
    logEvent('purchase', {
      'order_id': orderId,
      'amount': amount,
      'currency': currency,
      'item_count': itemCount,
    });
  }
}
