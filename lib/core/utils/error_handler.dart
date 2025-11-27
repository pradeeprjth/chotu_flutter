import 'package:dio/dio.dart';

/// Centralized error handler for consistent error messages across the app
class ErrorHandler {
  /// Converts any error to a user-friendly message
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is FormatException) {
      return 'Invalid data format received';
    }

    if (error is TypeError) {
      return 'Something went wrong. Please try again.';
    }

    // For other errors, return a generic message
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _handleDioError(DioException error) {
    // Check for response errors first
    if (error.response != null) {
      final response = error.response!;
      final data = response.data;

      // Try to get error message from response body
      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['error'] != null) {
          return data['error'].toString();
        }
      }

      // Map status codes to user-friendly messages
      switch (response.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Please login to continue.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'The requested resource was not found.';
        case 409:
          return 'This action conflicts with existing data.';
        case 422:
          return 'Invalid data provided. Please check your input.';
        case 429:
          return 'Too many requests. Please wait and try again.';
        case 500:
          return 'Server error. Please try again later.';
        case 502:
        case 503:
        case 504:
          return 'Server is temporarily unavailable. Please try again later.';
        default:
          return 'An error occurred. Please try again.';
      }
    }

    // Handle connection errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please contact support.';
      case DioExceptionType.badResponse:
        return 'Invalid response from server.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'Unable to connect. Please check your internet.';
        }
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Checks if the error is a network-related error
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout;
    }

    final message = error.toString();
    return message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable');
  }

  /// Checks if the error requires user to re-authenticate
  static bool isAuthError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }
}
