import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

// Auth state model
class AuthState {
  final User? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && accessToken != null;
  bool get isCustomer => user?.role == 'customer';
  bool get isAdmin => user?.role == 'admin';
  bool get isDelivery => user?.role == 'delivery';

  AuthState copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      accessToken: clearUser ? null : (accessToken ?? this.accessToken),
      refreshToken: clearUser ? null : (refreshToken ?? this.refreshToken),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  factory AuthState.initial() => AuthState();

  AuthState clearError() => copyWith(error: '');
}

// Auth provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial());

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      if (response != null) {
        final data = response.data;
        if (data is Map && data['message'] != null) {
          return data['message'];
        }
        switch (response.statusCode) {
          case 400:
            return 'Invalid input. Please check your details.';
          case 401:
            return 'Invalid email/phone or password';
          case 404:
            return 'Account not found';
          case 409:
            return data is Map ? (data['message'] ?? 'Account already exists') : 'Account already exists';
          case 500:
            return 'Server error. Please try again later.';
          default:
            return 'An error occurred. Please try again.';
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'No internet connection';
      }
    }
    return error.toString();
  }

  Future<bool> login(String emailOrPhone, String password) async {
    state = state.copyWith(isLoading: true, error: '');

    try {
      final response = await _authService.login(emailOrPhone, password);

      state = state.copyWith(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
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

  Future<bool> register({
    required String name,
    required String phone,
    String? email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: '');

    try {
      final response = await _authService.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );

      state = state.copyWith(
        user: response.user,
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
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

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.initial();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final hasToken = await _authService.hasStoredToken();
      if (!hasToken) {
        state = AuthState.initial();
        return;
      }

      final user = await _authService.getCurrentUser();
      if (user != null) {
        final token = await _authService.getStoredToken();
        state = state.copyWith(
          user: user,
          accessToken: token,
          isLoading: false,
        );
      } else {
        state = AuthState.initial();
      }
    } catch (e) {
      state = AuthState.initial();
    }
  }

  void clearError() {
    state = state.copyWith(error: '');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
