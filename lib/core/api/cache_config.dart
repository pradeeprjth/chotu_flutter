import 'dart:io';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';

/// Configuration for HTTP caching
class CacheConfig {
  static CacheStore? _cacheStore;

  /// Initialize cache store - call this during app startup
  static Future<void> initialize() async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/dio_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    _cacheStore = HiveCacheStore(cacheDir.path);
  }

  /// Get the cache store instance
  static CacheStore get cacheStore {
    if (_cacheStore == null) {
      throw StateError('CacheConfig not initialized. Call CacheConfig.initialize() first.');
    }
    return _cacheStore!;
  }

  /// Clear all cached data
  static Future<void> clearCache() async {
    await _cacheStore?.clean();
  }

  /// Default cache options for most GET requests
  static CacheOptions get defaultCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache, // Use cache first, then network if expired
        maxStale: const Duration(days: 7), // Keep stale cache for 7 days
        priority: CachePriority.high,
        hitCacheOnErrorExcept: [401, 403], // Use cache on network error except auth errors
      );

  /// Cache options for products (longer cache, frequently accessed)
  static CacheOptions get productsCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache,
        maxStale: const Duration(hours: 6), // Products can be cached for 6 hours
        priority: CachePriority.high,
        hitCacheOnErrorExcept: [401, 403],
      );

  /// Cache options for categories (very long cache, rarely changes)
  static CacheOptions get categoriesCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache,
        maxStale: const Duration(days: 7), // Categories rarely change
        priority: CachePriority.high,
        hitCacheOnErrorExcept: [401, 403],
      );

  /// Cache options for user-specific data (shorter cache)
  static CacheOptions get userDataCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache,
        maxStale: const Duration(minutes: 30), // User data needs fresher updates
        priority: CachePriority.normal,
        hitCacheOnErrorExcept: [401, 403],
      );

  /// Cache options for cart/wishlist (very short cache, real-time updates important)
  static CacheOptions get realTimeCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.forceCache,
        maxStale: const Duration(minutes: 5), // Very short cache for real-time data
        priority: CachePriority.low,
        hitCacheOnErrorExcept: [401, 403],
      );

  /// No cache policy for POST/PUT/DELETE requests
  static CacheOptions get noCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.noCache, // Never cache write operations
        priority: CachePriority.low,
      );

  /// Refresh policy - always fetch from network, update cache
  static CacheOptions get refreshCacheOptions => CacheOptions(
        store: cacheStore,
        policy: CachePolicy.refresh, // Always fetch from network but update cache
        priority: CachePriority.normal,
      );
}

/// Extension to determine cache policy based on request
extension CachePolicyExtension on String {
  CacheOptions get cacheOptions {
    // No cache for write operations
    if (contains('POST') || contains('PUT') || contains('DELETE') || contains('PATCH')) {
      return CacheConfig.noCacheOptions;
    }

    // Route-based cache policies for GET requests
    if (contains('/categories')) {
      return CacheConfig.categoriesCacheOptions;
    } else if (contains('/products')) {
      return CacheConfig.productsCacheOptions;
    } else if (contains('/cart') || contains('/wishlist')) {
      return CacheConfig.realTimeCacheOptions;
    } else if (contains('/me') || contains('/addresses') || contains('/profile')) {
      return CacheConfig.userDataCacheOptions;
    }

    // Default cache for everything else
    return CacheConfig.defaultCacheOptions;
  }
}
