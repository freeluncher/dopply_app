import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dopply_app/shared/services/auth_token_service.dart';
import 'package:dopply_app/shared/services/connectivity_service.dart';
import 'package:dopply_app/shared/services/offline_queue_service.dart';
import 'package:dopply_app/shared/services/cache_service.dart';

/// Enhanced API client dengan auto-refresh token, retry logic, dan offline support
class EnhancedApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final AuthTokenService _tokenService;
  final ConnectivityService _connectivityService;
  final OfflineQueueService _offlineQueueService;
  final CacheService _cacheService;

  static const String _baseUrl = 'https://dopply.com.my/api';
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  EnhancedApiClient({
    Dio? dio,
    FlutterSecureStorage? storage,
    AuthTokenService? tokenService,
    ConnectivityService? connectivityService,
    OfflineQueueService? offlineQueueService,
    CacheService? cacheService,
  }) : _dio = dio ?? Dio(),
       _storage = storage ?? const FlutterSecureStorage(),
       _tokenService = tokenService ?? AuthTokenService(),
       _connectivityService = connectivityService ?? ConnectivityService(),
       _offlineQueueService = offlineQueueService ?? OfflineQueueService(),
       _cacheService = cacheService ?? CacheService() {
    _setupInterceptors();
    _listenToConnectivityChanges();
  }

  /// Setup interceptors untuk auto-refresh dan error handling
  void _setupInterceptors() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = _timeoutDuration;
    _dio.options.receiveTimeout = _timeoutDuration;
    _dio.options.sendTimeout = _timeoutDuration;

    // Request interceptor untuk menambahkan token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Auto-refresh logic untuk 401 responses
          if (error.response?.statusCode == 401) {
            print('[API_CLIENT] Token expired, attempting refresh...');

            final refreshed = await _refreshTokenAndRetry(error.requestOptions);
            if (refreshed != null) {
              return handler.resolve(refreshed);
            }
          }

          handler.next(error);
        },
      ),
    );

    // Retry interceptor untuk failed requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            final retryCount = error.requestOptions.extra['retryCount'] ?? 0;

            if (retryCount < _maxRetries) {
              print(
                '[API_CLIENT] Retrying request... Attempt ${retryCount + 1}',
              );

              error.requestOptions.extra['retryCount'] = retryCount + 1;

              // Wait before retry with exponential backoff
              await Future.delayed(
                Duration(milliseconds: (500 * (retryCount + 1)).round()),
              );

              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                // Continue with original error if retry fails
              }
            }
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Refresh token dan retry request
  Future<Response?> _refreshTokenAndRetry(RequestOptions requestOptions) async {
    try {
      final refreshSuccessful = await _tokenService.refreshToken();

      if (refreshSuccessful) {
        print('[API_CLIENT] Token refreshed successfully');

        // Update request dengan token baru
        final newToken = await _storage.read(key: 'access_token');
        requestOptions.headers['Authorization'] = 'Bearer $newToken';

        // Retry request dengan token baru
        final response = await _dio.fetch(requestOptions);
        return response;
      } else {
        print('[API_CLIENT] Token refresh failed');
        return null;
      }
    } catch (e) {
      print('[API_CLIENT] Error during token refresh: $e');
      return null;
    }
  }

  /// Cek apakah request perlu di-retry
  bool _shouldRetry(DioException error) {
    // Retry untuk network errors dan server errors (bukan client errors)
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry untuk server errors (5xx)
    if (error.response?.statusCode != null) {
      final statusCode = error.response!.statusCode!;
      return statusCode >= 500 && statusCode < 600;
    }

    return false;
  }

  /// Setup listener untuk connectivity changes
  void _listenToConnectivityChanges() {
    _connectivityService.connectionStream.listen((isConnected) {
      if (isConnected) {
        print('[API_CLIENT] Connection restored, processing offline queue...');
        _processOfflineQueue();
      } else {
        print('[API_CLIENT] Connection lost, will queue requests offline');
      }
    });
  }

  /// Process offline queue ketika koneksi kembali
  Future<void> _processOfflineQueue() async {
    try {
      final failedItems = await _offlineQueueService.processQueue();

      for (final item in failedItems) {
        try {
          // Execute failed requests
          await _executeQueuedRequest(item);
          print(
            '[API_CLIENT] Successfully processed queued request: ${item.method} ${item.endpoint}',
          );
        } catch (e) {
          print(
            '[API_CLIENT] Failed to process queued request: ${item.method} ${item.endpoint} - $e',
          );
        }
      }
    } catch (e) {
      print('[API_CLIENT] Error processing offline queue: $e');
    }
  }

  /// Execute a queued request
  Future<Response> _executeQueuedRequest(QueueItem item) async {
    final options = Options(method: item.method, headers: item.headers);

    switch (item.method.toUpperCase()) {
      case 'GET':
        return await _dio.get(item.endpoint, options: options);
      case 'POST':
        return await _dio.post(
          item.endpoint,
          data: item.data,
          options: options,
        );
      case 'PUT':
        return await _dio.put(item.endpoint, data: item.data, options: options);
      case 'DELETE':
        return await _dio.delete(item.endpoint, options: options);
      default:
        throw Exception('Unsupported HTTP method: ${item.method}');
    }
  }

  /// Check cache before making request
  Future<T?> _checkCache<T>(String cacheKey) async {
    try {
      return await _cacheService.get<T>(cacheKey);
    } catch (e) {
      print('[API_CLIENT] Error checking cache: $e');
      return null;
    }
  }

  /// Save response to cache
  Future<void> _saveToCache<T>(
    String cacheKey,
    T data, {
    Duration? duration,
  }) async {
    try {
      await _cacheService.set(
        cacheKey,
        data,
        duration: duration ?? const Duration(minutes: 15),
      );
    } catch (e) {
      print('[API_CLIENT] Error saving to cache: $e');
    }
  }

  /// Generate cache key for request
  String _generateCacheKey(
    String method,
    String path,
    Map<String, dynamic>? params,
  ) {
    final paramsString = params?.toString() ?? '';
    return 'api_${method}_${path}_${paramsString.hashCode}';
  }

  /// Check if request should be cached
  bool _shouldCache(String method, String path) {
    // Only cache GET requests and specific endpoints
    return method.toUpperCase() == 'GET' &&
        (path.contains('/users/') ||
            path.contains('/doctors/') ||
            path.contains('/patients/') ||
            path.contains('/records/'));
  }

  /// Add request to offline queue if not connected
  Future<void> _addToOfflineQueue(
    String method,
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    if (!_connectivityService.isConnected) {
      await _offlineQueueService.addToQueue(
        method: method,
        endpoint: path,
        data: data is Map<String, dynamic> ? data : null,
        headers: headers,
      );
    }
  }

  /// GET request dengan auto-refresh, retry, caching, dan offline support
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    // Check cache first for GET requests
    if (useCache && _shouldCache('GET', path)) {
      final cacheKey = _generateCacheKey('GET', path, queryParameters);
      final cachedData = await _checkCache<Response<T>>(cacheKey);
      if (cachedData != null) {
        print('[API_CLIENT] Cache hit for GET $path');
        return cachedData;
      }
    }

    // Check connectivity for non-cached requests
    if (!_connectivityService.isConnected) {
      print('[API_CLIENT] No connection, cannot perform GET request: $path');
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      // Save to cache if applicable
      if (useCache && _shouldCache('GET', path)) {
        final cacheKey = _generateCacheKey('GET', path, queryParameters);
        await _saveToCache(cacheKey, response, duration: cacheDuration);
      }

      return response;
    } catch (e) {
      print('[API_CLIENT] GET request failed: $path - $e');
      rethrow;
    }
  }

  /// POST request dengan auto-refresh, retry, dan offline queue
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    // Check connectivity first
    if (!_connectivityService.isConnected) {
      print(
        '[API_CLIENT] No connection, adding POST request to offline queue: $path',
      );
      await _addToOfflineQueue(
        'POST',
        path,
        data: data,
        headers: options?.headers?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection - request queued for later',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      print('[API_CLIENT] POST request failed: $path - $e');
      // Add to offline queue if it's a network error
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout)) {
        await _addToOfflineQueue(
          'POST',
          path,
          data: data,
          headers: options?.headers?.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
      rethrow;
    }
  }

  /// PUT request dengan auto-refresh, retry, dan offline queue
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    // Check connectivity first
    if (!_connectivityService.isConnected) {
      print(
        '[API_CLIENT] No connection, adding PUT request to offline queue: $path',
      );
      await _addToOfflineQueue(
        'PUT',
        path,
        data: data,
        headers: options?.headers?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection - request queued for later',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      print('[API_CLIENT] PUT request failed: $path - $e');
      // Add to offline queue if it's a network error
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout)) {
        await _addToOfflineQueue(
          'PUT',
          path,
          data: data,
          headers: options?.headers?.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
      rethrow;
    }
  }

  /// DELETE request dengan auto-refresh, retry, dan offline queue
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    // Check connectivity first
    if (!_connectivityService.isConnected) {
      print(
        '[API_CLIENT] No connection, adding DELETE request to offline queue: $path',
      );
      await _addToOfflineQueue(
        'DELETE',
        path,
        data: data,
        headers: options?.headers?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection - request queued for later',
        type: DioExceptionType.connectionError,
      );
    }

    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      print('[API_CLIENT] DELETE request failed: $path - $e');
      // Add to offline queue if it's a network error
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout)) {
        await _addToOfflineQueue(
          'DELETE',
          path,
          data: data,
          headers: options?.headers?.map(
            (key, value) => MapEntry(key, value.toString()),
          ),
        );
      }
      rethrow;
    }
  }

  /// Download dengan progress tracking
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Options? options,
  }) async {
    return await _dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      options: options,
    );
  }

  /// Close client dan cleanup resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }

  /// Cleanup resources
  void dispose() {
    _connectivityService.dispose();
  }
}
