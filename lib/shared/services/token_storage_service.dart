import '../../features/auth/data/services/persistent_auth_service.dart';

/// Shared token storage service for secure token management
///
/// Now delegates to PersistentAuthService for consistency
/// Provides centralized, secure storage for authentication tokens
/// across the entire application
class TokenStorageService {
  static final TokenStorageService _instance = TokenStorageService._internal();
  factory TokenStorageService() => _instance;
  TokenStorageService._internal() {
    print(
      '[TokenStorage] 🔧 TokenStorageService instance created - Delegating to PersistentAuthService',
    );
  }

  final PersistentAuthService _persistentAuth = PersistentAuthService();

  /// Get authentication token
  Future<String?> getToken() async {
    try {
      final token = await _persistentAuth.getAccessToken();
      if (token != null) {
        print(
          '[TokenStorage] ✅ Token retrieved successfully (length: ${token.length})',
        );
      } else {
        print('[TokenStorage] ⚠️ No token found in storage');
      }
      return token;
    } catch (e) {
      print('[TokenStorage] ❌ Error getting token: $e');
      return null;
    }
  }

  /// Save authentication token securely (delegates to PersistentAuthService)
  Future<void> saveToken(String token) async {
    try {
      print('[TokenStorage] 💾 Saving token (length: ${token.length})...');
      // Note: This should be done through AuthRepository.login() instead
      // for proper session management
      await _persistentAuth.updateAccessToken(token);
      print('[TokenStorage] ✅ Token saved successfully');
    } catch (e) {
      print('[TokenStorage] ❌ Error saving token: $e');
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _persistentAuth.getRefreshToken();
      if (refreshToken != null) {
        print(
          '[TokenStorage] ✅ Refresh token retrieved (length: ${refreshToken.length})',
        );
      } else {
        print('[TokenStorage] ⚠️ No refresh token found in storage');
      }
      return refreshToken;
    } catch (e) {
      print('[TokenStorage] ❌ Error getting refresh token: $e');
      return null;
    }
  }

  /// Save refresh token securely
  Future<void> saveRefreshToken(String refreshToken) async {
    // Note: This should be done through AuthRepository.login() instead
    print('[TokenStorage] Warning: Direct refresh token save not recommended');
  }

  /// Save user ID (legacy method)
  Future<void> saveUserId(String userId) async {
    // Note: User data should be managed through PersistentAuthService
    print('[TokenStorage] Warning: Direct user ID save not recommended');
  }

  /// Get user ID (legacy method)
  Future<String?> getUserId() async {
    try {
      final user = await _persistentAuth.getStoredUser();
      if (user != null) {
        print('[TokenStorage] ✅ User ID retrieved: ${user.id} (${user.email})');
        return user.id.toString();
      } else {
        print('[TokenStorage] ⚠️ No user found in storage');
        return null;
      }
    } catch (e) {
      print('[TokenStorage] ❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    try {
      print('[TokenStorage] 🗑️ Clearing access token...');
      await _persistentAuth.clearAccessToken();
      print('[TokenStorage] ✅ Access token cleared successfully');
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing access token: $e');
      rethrow;
    }
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    try {
      print('[TokenStorage] 🗑️ Clearing refresh token...');
      await _persistentAuth.clearRefreshToken();
      print('[TokenStorage] ✅ Refresh token cleared successfully');
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing refresh token: $e');
      rethrow;
    }
  }

  /// Clear user ID (legacy method)
  Future<void> clearUserId() async {
    // User data cleared through PersistentAuthService
    print('[TokenStorage] Warning: User data managed by PersistentAuthService');
  }

  /// Clear all authentication data
  Future<void> clearAll() async {
    try {
      print('[TokenStorage] 🗑️ Clearing entire session...');
      await _persistentAuth.clearSession();
      print('[TokenStorage] ✅ Entire session cleared successfully');
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing session: $e');
      rethrow;
    }
  }

  /// Check if token is valid
  Future<bool> isTokenValid() async {
    try {
      print('[TokenStorage] 🔍 Checking token validity...');
      final token = await getToken();
      if (token == null) {
        print('[TokenStorage] ❌ Token validation failed: No token found');
        return false;
      }

      final isExpired = await _persistentAuth.isTokenExpired();
      final isValid = !isExpired;

      if (isValid) {
        print('[TokenStorage] ✅ Token is valid and not expired');
      } else {
        print('[TokenStorage] ⚠️ Token is expired');
      }

      return isValid;
    } catch (e) {
      print('[TokenStorage] ❌ Error checking token validity: $e');
      return false;
    }
  }

  /// Debug: Print comprehensive session information
  Future<void> debugSessionInfo() async {
    try {
      print('[TokenStorage] 🔍 === SESSION DEBUG INFO ===');

      // Token info
      final token = await _persistentAuth.getAccessToken();
      final refreshToken = await _persistentAuth.getRefreshToken();

      print(
        '[TokenStorage] 📄 Access Token: ${token != null ? "✅ Present (${token.length} chars)" : "❌ Missing"}',
      );
      print(
        '[TokenStorage] 🔄 Refresh Token: ${refreshToken != null ? "✅ Present (${refreshToken.length} chars)" : "❌ Missing"}',
      );

      // User info
      final user = await _persistentAuth.getStoredUser();
      if (user != null) {
        print(
          '[TokenStorage] 👤 User: ✅ ${user.name} (${user.email}) - Role: ${user.role}',
        );
      } else {
        print('[TokenStorage] 👤 User: ❌ No user data found');
      }

      // Session status
      final sessionInfo = await _persistentAuth.getSessionInfo();
      print('[TokenStorage] 📊 Session Info:');
      sessionInfo.forEach((key, value) {
        print('[TokenStorage]    $key: $value');
      });

      // Validation checks
      final isExpired =
          token != null ? await _persistentAuth.isTokenExpired() : true;
      final shouldAutoLogout = await _persistentAuth.shouldAutoLogout();
      final rememberMe = await _persistentAuth.isRememberMeEnabled();

      print('[TokenStorage] 🕐 Token Expired: ${isExpired ? "❌ Yes" : "✅ No"}');
      print(
        '[TokenStorage] ⏰ Should Auto Logout: ${shouldAutoLogout ? "⚠️ Yes" : "✅ No"}',
      );
      print(
        '[TokenStorage] 💭 Remember Me: ${rememberMe ? "✅ Enabled" : "❌ Disabled"}',
      );

      print('[TokenStorage] 🔍 === END SESSION DEBUG ===');
    } catch (e) {
      print('[TokenStorage] ❌ Error getting debug info: $e');
    }
  }
}
