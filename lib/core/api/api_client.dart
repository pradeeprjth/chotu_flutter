import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'api_config.dart';
import 'cache_config.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add cache interceptor FIRST (before auth interceptor)
    _dio.interceptors.add(
      DioCacheInterceptor(options: CacheConfig.defaultCacheOptions),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final token = await _storage.read(key: ApiConfig.accessTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors - attempt token refresh
        // Skip refresh for auth routes (login/register) as 401 means invalid credentials
        final path = error.requestOptions.path;
        final isAuthRoute = path.startsWith('/auth/');

        if (error.response?.statusCode == 401 && !isAuthRoute) {
          try {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the failed request
              final opts = error.requestOptions;
              final token = await _storage.read(key: ApiConfig.accessTokenKey);
              opts.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (e) {
            // Refresh failed, clear tokens
            await _clearTokens();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${ApiConfig.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        // Backend wraps response in { success, data }
        final data = response.data['data'] ?? response.data;
        await _storage.write(
          key: ApiConfig.accessTokenKey,
          value: data['accessToken'],
        );
        await _storage.write(
          key: ApiConfig.refreshTokenKey,
          value: data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userKey);
  }

  // HTTP methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CacheOptions? cacheOptions,
  }) {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: Options(
        extra: cacheOptions?.toExtra() ?? path.cacheOptions.toExtra(),
      ),
    );
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(
      path,
      data: data,
      options: Options(
        extra: CacheConfig.noCacheOptions.toExtra(),
      ),
    );
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(
      path,
      data: data,
      options: Options(
        extra: CacheConfig.noCacheOptions.toExtra(),
      ),
    );
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(
      path,
      data: data,
      options: Options(
        extra: CacheConfig.noCacheOptions.toExtra(),
      ),
    );
  }

  Future<Response> delete(String path) {
    return _dio.delete(
      path,
      options: Options(
        extra: CacheConfig.noCacheOptions.toExtra(),
      ),
    );
  }

  // Multipart upload for images
  Future<Response> uploadFile(String path, String filePath, {String fieldName = 'image'}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(path, data: formData);
  }
}

// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
