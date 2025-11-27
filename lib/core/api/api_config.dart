import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Get the appropriate base URL for the current platform
  /// - Android Emulator: 10.0.2.2 (localhost alias)
  /// - iOS Simulator: localhost
  /// - Web: localhost
  /// - Physical devices: Use your computer's local IP address
  static String get baseUrl {
    // For web
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    // For mobile platforms
    try {
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host localhost
        return 'http://10.0.2.2:3000/api/v1';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost directly
        return 'http://localhost:3000/api/v1';
      }
    } catch (e) {
      // Platform not available (web fallback)
    }

    // Default fallback
    return 'http://localhost:3000/api/v1';
  }

  // For production, use environment variables
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://api.chotu.com/api/v1',
  // );

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
