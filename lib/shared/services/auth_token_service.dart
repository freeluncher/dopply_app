import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';

/// Universal Auth Token Service
///
/// Handles token refresh and automatic token management
/// as per API documentation
class AuthTokenService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Refresh access token using stored refresh token
  /// Endpoint: POST /refresh
  Future<bool> refreshToken([String? refreshToken]) async {
    // Use provided refresh token or get from storage
    final token = refreshToken ?? await TokenStorageService().getRefreshToken();
    if (token == null) {
      print('[AuthTokenService] No refresh token available');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': token}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Save new access token
        if (result['access_token'] != null) {
          await TokenStorageService().saveToken(result['access_token']);
        }

        // Save new refresh token if provided (reusable until expired)
        if (result['refresh_token'] != null) {
          await TokenStorageService().saveRefreshToken(result['refresh_token']);
        }

        print('[AuthTokenService] Token refreshed successfully');
        return true;
      } else {
        print(
          '[AuthTokenService] Token refresh failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('[AuthTokenService] refreshToken Exception: $e');
      return false;
    }
  }

  /// Auto-refresh token when receiving 401 error
  /// This is a helper method for API interceptors
  Future<bool> handleUnauthorized() async {
    print('[AuthTokenService] Handling 401 - attempting token refresh');
    final refreshSuccess = await refreshToken();

    if (!refreshSuccess) {
      // Clear all tokens if refresh fails
      await TokenStorageService().clearAll();
      print('[AuthTokenService] Refresh failed - cleared all tokens');
    }

    return refreshSuccess;
  }
}
