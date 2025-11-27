import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Production backend URL
  static const String productionUrl = 'https://chotu-backend-l6ek.onrender.com/api/v1';
  
  // Development/Local backend URL
  static const String developmentUrl = 'http://localhost:3000/api/v1';
  
  // Toggle this to switch between production and development
  static const bool useProduction = true;

  /// Get the appropriate base URL for the current platform
  static String get baseUrl {
    // If using production, return production URL
    if (useProduction) {
      return productionUrl;
    }

    // Development mode - use local backend
    // For web
    if (kIsWeb) {
      return developmentUrl;
    }

    // For mobile platforms
    try {
      if (Platform.isAndroid) {
        // Android emulator uses 10.0.2.2 to access host localhost
        return 'http://10.0.2.2:3000/api/v1';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost directly
        return developmentUrl;
      }
    } catch (e) {
      // Platform not available (web fallback)
    }

    // Default fallback
    return developmentUrl;
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
