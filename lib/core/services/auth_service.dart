import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../models/user_model.dart';

class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}

class AuthService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService(this._apiClient);

  Future<AuthResponse> login(String emailOrPhone, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'emailOrPhone': emailOrPhone,
        'password': password,
      });

      // Backend wraps response in { success, message, data }
      final data = response.data['data'] ?? response.data;
      final authResponse = AuthResponse.fromJson(data);

      // Store tokens
      await _storage.write(
        key: ApiConfig.accessTokenKey,
        value: authResponse.accessToken,
      );
      await _storage.write(
        key: ApiConfig.refreshTokenKey,
        value: authResponse.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'password': password,
      };
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }

      final response = await _apiClient.post('/auth/register', data: data);

      // Backend wraps response in { success, message, data }
      final responseData = response.data['data'] ?? response.data;
      final authResponse = AuthResponse.fromJson(responseData);

      // Store tokens
      await _storage.write(
        key: ApiConfig.accessTokenKey,
        value: authResponse.accessToken,
      );
      await _storage.write(
        key: ApiConfig.refreshTokenKey,
        value: authResponse.refreshToken,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/me');
      // Backend wraps response in { success, data }
      final data = response.data['data'] ?? response.data;
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await _storage.delete(key: ApiConfig.accessTokenKey);
      await _storage.delete(key: ApiConfig.refreshTokenKey);
      await _storage.delete(key: ApiConfig.userKey);
    }
  }

  Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: ApiConfig.accessTokenKey);
    return token != null;
  }

  Future<String?> getStoredToken() async {
    return await _storage.read(key: ApiConfig.accessTokenKey);
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});
