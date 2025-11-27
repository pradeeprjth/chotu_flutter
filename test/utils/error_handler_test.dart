import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:chotu_app/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler.getErrorMessage', () {
    group('DioException handling', () {
      test('should return user-friendly message for connection timeout', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('timed out'));
        expect(message.toLowerCase(), contains('internet'));
      });

      test('should return user-friendly message for connection error', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('connection'));
      });

      test('should return user-friendly message for receive timeout', () {
        final error = DioException(
          type: DioExceptionType.receiveTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('took too long'));
      });

      test('should return user-friendly message for send timeout', () {
        final error = DioException(
          type: DioExceptionType.sendTimeout,
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('timed out'));
      });

      test('should extract message from response body', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            data: {'message': 'Custom error message'},
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message, 'Custom error message');
      });

      test('should handle 400 status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('invalid'));
      });

      test('should handle 401 status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('login'));
      });

      test('should handle 403 status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('permission'));
      });

      test('should handle 404 status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('not found'));
      });

      test('should handle 500 status code', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('server error'));
      });

      test('should handle 502/503/504 status codes', () {
        for (final statusCode in [502, 503, 504]) {
          final error = DioException(
            type: DioExceptionType.badResponse,
            response: Response(
              statusCode: statusCode,
              requestOptions: RequestOptions(path: '/test'),
            ),
            requestOptions: RequestOptions(path: '/test'),
          );

          final message = ErrorHandler.getErrorMessage(error);
          expect(message.toLowerCase(), contains('unavailable'));
        }
      });

      test('should handle cancelled request', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('cancelled'));
      });

      test('should handle unknown error with SocketException', () {
        final error = DioException(
          type: DioExceptionType.unknown,
          message: 'SocketException: Connection refused',
          requestOptions: RequestOptions(path: '/test'),
        );

        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('connect'));
      });
    });

    group('Non-DioException handling', () {
      test('should handle FormatException', () {
        final error = const FormatException('Invalid format');
        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('format'));
      });

      test('should handle TypeError', () {
        // Create a type error by forcing wrong type
        try {
          // ignore: unnecessary_cast
          final dynamic value = 'string';
          // ignore: unused_local_variable
          final int number = value as int;
        } on TypeError catch (error) {
          final message = ErrorHandler.getErrorMessage(error);
          expect(message.toLowerCase(), contains('wrong'));
        }
      });

      test('should handle generic Exception', () {
        final error = Exception('Generic error');
        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('unexpected'));
      });

      test('should handle SocketException string', () {
        final error = Exception('SocketException: No route to host');
        final message = ErrorHandler.getErrorMessage(error);
        expect(message.toLowerCase(), contains('connect'));
      });
    });
  });

  group('ErrorHandler.isNetworkError', () {
    test('should return true for connection timeout', () {
      final error = DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('should return true for connection error', () {
      final error = DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('should return true for send timeout', () {
      final error = DioException(
        type: DioExceptionType.sendTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('should return true for receive timeout', () {
      final error = DioException(
        type: DioExceptionType.receiveTimeout,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('should return false for bad response', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isNetworkError(error), false);
    });

    test('should return true for SocketException string', () {
      final error = Exception('SocketException: Connection refused');
      expect(ErrorHandler.isNetworkError(error), true);
    });

    test('should return false for generic exception', () {
      final error = Exception('Generic error');
      expect(ErrorHandler.isNetworkError(error), false);
    });
  });

  group('ErrorHandler.isAuthError', () {
    test('should return true for 401 status code', () {
      final error = DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 401,
          requestOptions: RequestOptions(path: '/test'),
        ),
        requestOptions: RequestOptions(path: '/test'),
      );

      expect(ErrorHandler.isAuthError(error), true);
    });

    test('should return false for other status codes', () {
      for (final statusCode in [400, 403, 404, 500]) {
        final error = DioException(
          type: DioExceptionType.badResponse,
          response: Response(
            statusCode: statusCode,
            requestOptions: RequestOptions(path: '/test'),
          ),
          requestOptions: RequestOptions(path: '/test'),
        );

        expect(ErrorHandler.isAuthError(error), false);
      }
    });

    test('should return false for non-DioException', () {
      final error = Exception('Auth error');
      expect(ErrorHandler.isAuthError(error), false);
    });
  });
}
