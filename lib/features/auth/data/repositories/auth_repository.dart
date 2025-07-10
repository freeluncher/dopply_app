import '../../../../shared/models/user.dart';
import '../../../../services/api/auth_api_service.dart';
import '../services/persistent_auth_service.dart';

/// Auth Repository Implementation using new API service architecture
///
/// Handles authentication business logic and token management with persistence
class AuthRepository {
  final AuthApiService _authApiService;
  final PersistentAuthService _persistentAuth;

  AuthRepository(this._authApiService, this._persistentAuth);

  /// Login user with email and password
  Future<User?> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final result = await _authApiService.login(
        email: email,
        password: password,
      );

      if (result['access_token'] != null) {
        // Parse user from API response - data user ada di root response
        final user = User.fromJson(result);

        // Save complete session with remember me preference
        await _persistentAuth.saveAuthSession(
          accessToken: result['access_token'],
          refreshToken: result['refresh_token'], // Could be null
          user: user,
          rememberMe: rememberMe,
        );

        return user;
      }
      return null;
    } catch (e) {
      print('[AUTH_REPO] Login error: $e');
      return null;
    }
  }

  /// Register new user
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? birthDate,
    String? address,
    String? medicalNote,
  }) async {
    try {
      final result = await _authApiService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        birthDate: birthDate,
        address: address,
        medicalNote: medicalNote,
      );

      if (result['success'] == true || result['user'] != null) {
        return role; // Return role as success indicator
      }
      return null;
    } catch (e) {
      print('[AUTH_REPO] Register error: $e');
      return null;
    }
  }

  /// Get current user from stored session
  Future<User?> getCurrentUserFromToken() async {
    try {
      // Check if stored session is valid
      final isValidSession = await _persistentAuth.validateStoredSession();
      if (!isValidSession) return null;

      // Get user from storage
      final user = await _persistentAuth.getStoredUser();
      if (user == null) return null;

      // Check if token needs refresh
      final isExpired = await _persistentAuth.isTokenExpired();
      if (isExpired) {
        final refreshed = await refreshToken();
        if (!refreshed) {
          await _persistentAuth.clearSession();
          return null;
        }
      }

      // Update last active timestamp
      await _persistentAuth.updateLastActive();
      return user;
    } catch (e) {
      print('[AUTH_REPO] Get current user error: $e');
      await _persistentAuth.clearSession();
      return null;
    }
  }

  /// Logout user and clear stored data
  Future<void> logout() async {
    try {
      await _persistentAuth.clearSession();
    } catch (e) {
      print('[AUTH_REPO] Logout error: $e');
    }
  }

  /// Refresh access token
  Future<bool> refreshToken() async {
    try {
      print('[AUTH_REPO] 🔄 Starting token refresh...');

      final refreshToken = await _persistentAuth.getRefreshToken();
      if (refreshToken == null) {
        print('[AUTH_REPO] ❌ No refresh token available');
        print(
          '[AUTH_REPO] ℹ️ User may have logged in with old app version - needs to re-login',
        );
        return false;
      }

      print(
        '[AUTH_REPO] 🔑 Using refresh token: ${refreshToken.substring(0, 20)}...',
      );

      final result = await _authApiService.refreshToken(
        refreshToken: refreshToken,
      );

      print('[AUTH_REPO] 📦 Refresh response: $result');

      if (result['access_token'] != null) {
        final newAccessToken = result['access_token'];
        print(
          '[AUTH_REPO] ✅ New access token received: ${newAccessToken.substring(0, 20)}...',
        );

        // Update access token
        await _persistentAuth.updateAccessToken(newAccessToken);
        print('[AUTH_REPO] 💾 New access token saved to storage');

        // Update refresh token if provided (token rotation)
        if (result['refresh_token'] != null) {
          final newRefreshToken = result['refresh_token'];
          print(
            '[AUTH_REPO] 🔄 New refresh token received: ${newRefreshToken.substring(0, 20)}...',
          );
          await _persistentAuth.updateRefreshToken(newRefreshToken);
          print('[AUTH_REPO] 💾 New refresh token saved to storage');
        }

        // Verify the access token was saved correctly
        final savedToken = await _persistentAuth.getAccessToken();
        if (savedToken == newAccessToken) {
          print('[AUTH_REPO] ✅ Token refresh completed successfully');
          return true;
        } else {
          print('[AUTH_REPO] ❌ Token save verification failed');
          return false;
        }
      } else {
        print('[AUTH_REPO] ❌ No access_token in refresh response');
        return false;
      }
    } catch (e) {
      print('[AUTH_REPO] ❌ Refresh token error: $e');
      return false;
    }
  }

  /// Verify if current token is valid
  Future<bool> verifyCurrentToken() async {
    try {
      return await _authApiService.verifyToken();
    } catch (e) {
      print('[AUTH_REPO] Verify token error: $e');
      return false;
    }
  }

  /// Get session information for debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    return await _persistentAuth.getSessionInfo();
  }

  /// Check if this is first app launch
  Future<bool> isFirstLaunch() async {
    return await _persistentAuth.isFirstLaunch();
  }

  /// Update user data in persistent storage
  Future<void> updateUserData(User user) async {
    await _persistentAuth.updateUserData(user);
  }

  /// Update stored user data in persistent storage
  Future<void> updateStoredUserData(User user) async {
    try {
      await _persistentAuth.updateUserData(user);
      print('[AUTH_REPO] 💾 User data updated in persistent storage');
    } catch (e) {
      print('[AUTH_REPO] ❌ Error updating stored user data: $e');
    }
  }

  /// Check if refresh tokens are supported by the backend
  /// NOTE: Backend now supports refresh tokens as of REFRESH_TOKEN_IMPLEMENTATION_COMPLETE
  Future<bool> isRefreshTokenSupported() async {
    final refreshToken = await _persistentAuth.getRefreshToken();
    return refreshToken != null;
  }

  /// Check if user session is expired and cannot be refreshed
  Future<bool> isSessionExpiredAndUnrefreshable() async {
    final isExpired = await _persistentAuth.isTokenExpired();
    final hasRefreshToken = await isRefreshTokenSupported();
    return isExpired && !hasRefreshToken;
  }
}
