import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../shared/models/user.dart';

/// JWT Token decoder utility (simple implementation)
class JwtDecoder {
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(payload)),
      );
      final Map<String, dynamic> data = jsonDecode(decoded);

      final exp = data['exp'] as int?;
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(payload)),
      );
      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }
}

/// Comprehensive persistent authentication service
///
/// Handles secure storage, automatic token refresh, and session management
class PersistentAuthService {
  static const PersistentAuthService _instance =
      PersistentAuthService._internal();
  factory PersistentAuthService() => _instance;
  const PersistentAuthService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Storage keys
  static const String _accessTokenKey = 'dopply_access_token';
  static const String _refreshTokenKey = 'dopply_refresh_token';
  static const String _userDataKey = 'dopply_user_data';
  static const String _loginTimeKey = 'dopply_login_time';
  static const String _rememberMeKey = 'dopply_remember_me';
  static const String _lastActiveKey = 'dopply_last_active';

  /// Save complete authentication session
  Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    required User user,
    bool rememberMe = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      if (refreshToken != null)
        _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _userDataKey, value: jsonEncode(user.toJson())),
      _storage.write(key: _loginTimeKey, value: now.toString()),
      _storage.write(key: _rememberMeKey, value: rememberMe.toString()),
      _storage.write(key: _lastActiveKey, value: now.toString()),
    ]);

    print('[PersistentAuth] Session saved for user: ${user.email}');
  }

  /// Get current access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get current refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Get stored user data
  Future<User?> getStoredUser() async {
    try {
      final userJson = await _storage.read(key: _userDataKey);
      if (userJson == null) return null;

      final userData = jsonDecode(userJson);
      return User.fromJson(userData);
    } catch (e) {
      print('[PersistentAuth] Error reading user data: $e');
      return null;
    }
  }

  /// Update access token (during refresh)
  Future<void> updateAccessToken(String newAccessToken) async {
    await _storage.write(key: _accessTokenKey, value: newAccessToken);
    await updateLastActive();
  }

  /// Update refresh token (during token rotation)
  Future<void> updateRefreshToken(String newRefreshToken) async {
    await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
    await updateLastActive();
  }

  /// Update user data
  Future<void> updateUserData(User user) async {
    await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _storage.write(key: _lastActiveKey, value: now.toString());
  }

  /// Check if user selected "Remember Me"
  Future<bool> isRememberMeEnabled() async {
    final rememberMe = await _storage.read(key: _rememberMeKey);
    return rememberMe == 'true';
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    try {
      final token = await getAccessToken();
      if (token == null) return true;

      return JwtDecoder.isExpired(token);
    } catch (e) {
      print('[PersistentAuth] Error checking token expiration: $e');
      return true;
    }
  }

  /// Check if session should auto-logout (based on inactivity)
  Future<bool> shouldAutoLogout() async {
    try {
      final rememberMe = await isRememberMeEnabled();
      if (rememberMe)
        return false; // Never auto-logout if remember me is enabled

      final lastActiveStr = await _storage.read(key: _lastActiveKey);
      if (lastActiveStr == null) return true;

      final lastActive = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastActiveStr),
      );
      final now = DateTime.now();
      final inactiveHours = now.difference(lastActive).inHours;

      // Auto-logout after 24 hours of inactivity (configurable)
      return inactiveHours >= 24;
    } catch (e) {
      print('[PersistentAuth] Error checking auto-logout: $e');
      return true;
    }
  }

  /// Get session info for debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final token = await getAccessToken();
      final user = await getStoredUser();
      final loginTime = await _storage.read(key: _loginTimeKey);
      final lastActive = await _storage.read(key: _lastActiveKey);
      final rememberMe = await isRememberMeEnabled();

      return {
        'hasToken': token != null,
        'tokenExpired': token != null ? JwtDecoder.isExpired(token) : true,
        'hasUser': user != null,
        'userEmail': user?.email,
        'userRole': user?.role,
        'loginTime':
            loginTime != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(loginTime),
                ).toIso8601String()
                : null,
        'lastActive':
            lastActive != null
                ? DateTime.fromMillisecondsSinceEpoch(
                  int.parse(lastActive),
                ).toIso8601String()
                : null,
        'rememberMe': rememberMe,
        'shouldAutoLogout': await shouldAutoLogout(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear specific session data
  Future<void> clearAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Clear entire authentication session
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userDataKey),
      _storage.delete(key: _loginTimeKey),
      _storage.delete(key: _rememberMeKey),
      _storage.delete(key: _lastActiveKey),
    ]);

    print('[PersistentAuth] Session cleared');
  }

  /// Validate stored session
  Future<bool> validateStoredSession() async {
    try {
      final token = await getAccessToken();
      final user = await getStoredUser();

      if (token == null || user == null) {
        return false;
      }

      // Check if should auto-logout due to inactivity
      if (await shouldAutoLogout()) {
        await clearSession();
        return false;
      }

      // Check token expiration
      if (JwtDecoder.isExpired(token)) {
        // Try to refresh token if available
        final refreshToken = await getRefreshToken();
        if (refreshToken != null) {
          // Return true to indicate session exists but needs refresh
          // The calling code should handle token refresh
          return true;
        } else {
          await clearSession();
          return false;
        }
      }

      return true;
    } catch (e) {
      print('[PersistentAuth] Session validation error: $e');
      await clearSession();
      return false;
    }
  }

  /// Check if this is first app launch (no previous session)
  Future<bool> isFirstLaunch() async {
    final loginTime = await _storage.read(key: _loginTimeKey);
    return loginTime == null;
  }
}
