import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/user.dart';
import 'user_provider.dart';
import 'auth_repository_provider.dart';

/// Auth startup provider for checking authentication status on app launch
///
/// Verifies stored token and loads user data if valid.
/// This provider runs once when the app starts to restore authentication state.
final authStartupProvider = FutureProvider<User?>((ref) async {
  try {
    // Use the new auth repository to get current user
    final authRepository = ref.read(authRepositoryProvider);
    final user = await authRepository.getCurrentUserFromToken();

    if (user != null) {
      ref.read(userProvider.notifier).state = user;
      return user;
    }

    return null;
  } catch (e) {
    print('[AUTH] Error during startup check: $e');
    return null;
  }
});

/// Token verification provider using new repository
final tokenVerifyProvider = FutureProvider<bool>((ref) async {
  try {
    final authRepository = ref.read(authRepositoryProvider);
    return await authRepository.verifyCurrentToken();
  } catch (e) {
    print('[AUTH] Token verification failed: $e');
    return false;
  }
});
