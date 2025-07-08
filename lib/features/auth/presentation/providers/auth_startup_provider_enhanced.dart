import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/persistent_auth_service.dart';
import '../../../../services/api/auth_api_service.dart';
import '../../../../shared/models/user.dart';
import 'user_provider.dart';

/// Enhanced Auth Startup Provider with Persistent Authentication
///
/// Handles automatic login, session validation, and token refresh
final authStartupProvider = FutureProvider<AuthStartupResult>((ref) async {
  try {
    print('[AuthStartup] Starting authentication check...');

    // Initialize services
    final authApiService = AuthApiService();
    final persistentAuth = PersistentAuthService();
    final authRepo = AuthRepository(authApiService, persistentAuth);

    // Check if this is first launch
    final isFirstLaunch = await authRepo.isFirstLaunch();
    if (isFirstLaunch) {
      print('[AuthStartup] First launch detected');
      return AuthStartupResult.firstLaunch();
    }

    // Try to restore session from storage
    final storedUser = await authRepo.getCurrentUserFromToken();
    if (storedUser != null) {
      // Verify token with server
      final isValidToken = await authRepo.verifyCurrentToken();
      if (isValidToken) {
        // Set user in provider
        ref.read(userProvider.notifier).state = storedUser;

        print(
          '[AuthStartup] Session restored successfully for: ${storedUser.email}',
        );
        return AuthStartupResult.authenticated(storedUser);
      } else {
        // Token invalid, clear session
        await authRepo.logout();
        print('[AuthStartup] Token verification failed, session cleared');
        return AuthStartupResult.unauthenticated();
      }
    }

    print('[AuthStartup] No valid session found');
    return AuthStartupResult.unauthenticated();
  } catch (e) {
    print('[AuthStartup] Error during authentication check: $e');
    return AuthStartupResult.error(e.toString());
  }
});

/// Auth startup result model
class AuthStartupResult {
  final AuthStartupStatus status;
  final User? user;
  final String? error;

  const AuthStartupResult._({required this.status, this.user, this.error});

  factory AuthStartupResult.firstLaunch() =>
      const AuthStartupResult._(status: AuthStartupStatus.firstLaunch);

  factory AuthStartupResult.authenticated(User user) =>
      AuthStartupResult._(status: AuthStartupStatus.authenticated, user: user);

  factory AuthStartupResult.unauthenticated() =>
      const AuthStartupResult._(status: AuthStartupStatus.unauthenticated);

  factory AuthStartupResult.error(String error) =>
      AuthStartupResult._(status: AuthStartupStatus.error, error: error);
}

enum AuthStartupStatus { firstLaunch, authenticated, unauthenticated, error }

/// Provider for auth repository with persistent service
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authApiService = AuthApiService();
  final persistentAuth = PersistentAuthService();
  return AuthRepository(authApiService, persistentAuth);
});

/// Session info provider for debugging
final sessionInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.getSessionInfo();
});

/// Auto-refresh token provider (runs periodically)
final autoRefreshProvider = StreamProvider<bool>((ref) async* {
  final authRepo = ref.read(authRepositoryProvider);

  while (true) {
    await Future.delayed(const Duration(minutes: 15)); // Check every 15 minutes

    try {
      final user = ref.read(userProvider);
      if (user != null) {
        final persistentAuth = PersistentAuthService();

        // Check if token will expire soon (within 30 minutes)
        final token = await persistentAuth.getAccessToken();
        if (token != null) {
          final decoded = JwtDecoder.decode(token);
          if (decoded != null) {
            final exp = decoded['exp'] as int?;
            if (exp != null) {
              final expiryTime = DateTime.fromMillisecondsSinceEpoch(
                exp * 1000,
              );
              final now = DateTime.now();
              final minutesUntilExpiry = expiryTime.difference(now).inMinutes;

              // Refresh if expiring within 30 minutes
              if (minutesUntilExpiry <= 30 && minutesUntilExpiry > 0) {
                print(
                  '[AutoRefresh] Token expiring in $minutesUntilExpiry minutes, refreshing...',
                );
                final refreshed = await authRepo.refreshToken();
                yield refreshed;
              } else {
                yield true; // Token is still valid
              }
            }
          }
        }
      }
    } catch (e) {
      print('[AutoRefresh] Error: $e');
      yield false;
    }
  }
});

/// Simple JWT decoder for the auto-refresh provider
class JwtDecoder {
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
