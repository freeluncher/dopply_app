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

      if (result['success'] == true && result['user'] != null) {
        // Parse user from API response
        final user = User.fromJson(result['user']);

        // Save complete session with remember me preference
        await _persistentAuth.saveAuthSession(
          accessToken: result['access_token'],
          refreshToken: result['refresh_token'],
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
      final refreshToken = await _persistentAuth.getRefreshToken();
      if (refreshToken == null) return false;

      final result = await _authApiService.refreshToken(
        refreshToken: refreshToken,
      );

      if (result['access_token'] != null) {
        await _persistentAuth.updateAccessToken(result['access_token']);
        return true;
      }
      return false;
    } catch (e) {
      print('[AUTH_REPO] Refresh token error: $e');
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
}
