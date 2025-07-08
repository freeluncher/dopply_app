// Core API Client untuk Dopply Medical System
// Base URL: https://dopply.my.id/api/v1

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';
import 'package:dopply_app/features/auth/data/services/persistent_auth_service.dart';
import 'package:dopply_app/features/auth/data/repositories/auth_repository.dart';
import 'package:dopply_app/services/api/auth_api_service.dart';

/// API Client terpusat untuk semua endpoint Dopply
/// Menangani authentication, headers, dan error handling
class ApiClient {
  static const String baseUrl = 'https://dopply.my.id/api/v1';

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _accessToken;

  /// Set access token untuk requests
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Get access token
  String? get accessToken => _accessToken;

  /// Headers dasar untuk semua requests
  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers dengan authorization
  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// GET request with automatic token refresh
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // Automatic token validation and refresh
    if (requireAuth) {
      await _ensureValidToken();
      _accessToken = await TokenStorageService().getToken();
      print(
        '[ApiClient] 🔐 Token for GET $endpoint: ${_accessToken != null ? "✅ Present (${_accessToken!.length} chars)" : "❌ Missing"}',
      );
    }

    final headers = requireAuth ? _authHeaders : _baseHeaders;

    print('[ApiClient] 📡 GET Request: $url');
    if (requireAuth && headers['Authorization'] != null) {
      print(
        '[ApiClient] 🔑 Authorization Header: ${headers['Authorization']!.substring(0, 20)}...',
      );
    }

    try {
      final response = await http.get(url, headers: headers);
      print(
        '[ApiClient] 📥 Response: ${response.statusCode} for GET $endpoint',
      );
      return _handleResponse(response);
    } catch (e) {
      print('[ApiClient] ❌ Network error for GET $endpoint: $e');
      throw ApiException('Network error: $e');
    }
  }

  /// POST request with automatic token refresh
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // Automatic token validation and refresh
    if (requireAuth) {
      await _ensureValidToken();
      _accessToken = await TokenStorageService().getToken();
      print(
        '[ApiClient] 🔐 Token for POST $endpoint: ${_accessToken != null ? "✅ Present (${_accessToken!.length} chars)" : "❌ Missing"}',
      );
    }

    final headers = requireAuth ? _authHeaders : _baseHeaders;

    print('[ApiClient] 📡 POST Request: $url');

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      print(
        '[ApiClient] 📥 Response: ${response.statusCode} for POST $endpoint',
      );
      return _handleResponse(response);
    } catch (e) {
      print('[ApiClient] ❌ Network error for POST $endpoint: $e');
      throw ApiException('Network error: $e');
    }
  }

  /// PUT request with automatic token refresh
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    // Automatic token validation and refresh
    if (requireAuth) {
      await _ensureValidToken();
      _accessToken = await TokenStorageService().getToken();
      print(
        '[ApiClient] 🔐 Token for PUT $endpoint: ${_accessToken != null ? "✅ Present (${_accessToken!.length} chars)" : "❌ Missing"}',
      );
    }

    final headers = requireAuth ? _authHeaders : _baseHeaders;

    print('[ApiClient] 📡 PUT Request: $url');

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      print(
        '[ApiClient] 📥 Response: ${response.statusCode} for PUT $endpoint',
      );
      return _handleResponse(response);
    } catch (e) {
      print('[ApiClient] ❌ Network error for PUT $endpoint: $e');
      throw ApiException('Network error: $e');
    }
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (requireAuth) {
      _accessToken = await TokenStorageService().getToken();
    }
    final headers = requireAuth ? _authHeaders : _baseHeaders;

    try {
      final response = await http.patch(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    if (requireAuth) {
      _accessToken = await TokenStorageService().getToken();
    }
    final headers = requireAuth ? _authHeaders : _baseHeaders;

    try {
      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Multipart request untuk file upload
  Future<http.StreamedResponse> multipart(
    String endpoint,
    List<http.MultipartFile> files, {
    Map<String, String>? fields,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', url);
    if (requireAuth) {
      _accessToken = await TokenStorageService().getToken();
    }
    // Add headers
    if (requireAuth && _accessToken != null) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    // Add files and fields
    request.files.addAll(files);
    if (fields != null) request.fields.addAll(fields);

    try {
      return await request.send();
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  /// Ensure token is valid, refresh if expired
  Future<void> _ensureValidToken() async {
    try {
      print('[ApiClient] 🔍 Checking token validity...');

      final tokenService = TokenStorageService();
      final currentToken = await tokenService.getToken();
      print(
        '[ApiClient] 🔑 Current token: ${currentToken != null ? "${currentToken.substring(0, 20)}..." : "null"}',
      );

      final isValid = await tokenService.isTokenValid();
      print('[ApiClient] ✅ Token valid: $isValid');

      if (!isValid) {
        print('[ApiClient] ⚠️ Token invalid/expired, attempting refresh...');

        // Try to refresh token using AuthRepository
        try {
          // Import needed for refresh
          final authApiService = AuthApiService();
          final persistentAuth = PersistentAuthService();
          final authRepo = AuthRepository(authApiService, persistentAuth);

          final refreshed = await authRepo.refreshToken();

          if (refreshed) {
            print('[ApiClient] ✅ Token refreshed successfully');

            // Verify the new token is different
            final newToken = await tokenService.getToken();
            print(
              '[ApiClient] 🔑 New token: ${newToken != null ? "${newToken.substring(0, 20)}..." : "null"}',
            );

            if (newToken != currentToken) {
              print('[ApiClient] ✅ Token was actually updated');
            } else {
              print('[ApiClient] ⚠️ Token appears unchanged after refresh');
            }
          } else {
            print('[ApiClient] ❌ Token refresh failed - clearing session');
            print(
              '[ApiClient] ℹ️ Refresh token may be expired or invalid - user needs to re-login',
            );

            // Clear the expired session since refresh failed
            await persistentAuth.clearSession();

            // Note: In a real app, you might want to trigger a navigation to login page here
            // or show a session expired dialog
          }
        } catch (e) {
          print('[ApiClient] ❌ Token refresh error: $e');
          // Token refresh failed, user might need to re-login
        }
      } else {
        print('[ApiClient] ✅ Token is valid');
      }
    } catch (e) {
      print('[ApiClient] ❌ Token validation error: $e');
    }
  }

  /// Handle response dan error codes
  http.Response _handleResponse(http.Response response) {
    print('[ApiClient] 📊 Response Status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
      case 201:
        print('[ApiClient] ✅ Success: ${response.statusCode}');
        return response;
      case 400:
        print('[ApiClient] ❌ Bad Request: ${response.body}');
        throw ApiException('Bad Request: ${response.body}');
      case 401:
        print('[ApiClient] 🔒 Unauthorized: ${response.body}');
        print(
          '[ApiClient] 🔍 Current token: ${_accessToken != null ? "Present" : "Missing"}',
        );
        throw UnauthorizedException('Unauthorized: ${response.body}');
      case 403:
        print('[ApiClient] 🚫 Forbidden: ${response.body}');
        throw ForbiddenException('Forbidden: ${response.body}');
      case 404:
        print('[ApiClient] 🔍 Not Found: ${response.body}');
        throw NotFoundException('Not Found: ${response.body}');
      case 500:
        print('[ApiClient] 💥 Server Error: ${response.body}');
        throw ServerException('Internal Server Error: ${response.body}');
      default:
        throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

/// Base exception untuk API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}

/// Unauthorized exception (401)
class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

/// Forbidden exception (403)
class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

/// Not found exception (404)
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

/// Server error exception (500)
class ServerException extends ApiException {
  ServerException(String message) : super(message);
}
