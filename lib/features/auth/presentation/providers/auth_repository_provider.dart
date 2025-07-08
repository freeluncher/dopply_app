import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/persistent_auth_service.dart';
import '../../../../services/api/auth_api_service.dart';

/// Provider for AuthApiService
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

/// Provider for PersistentAuthService
final persistentAuthServiceProvider = Provider<PersistentAuthService>((ref) {
  return PersistentAuthService();
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authApiServiceProvider),
    ref.read(persistentAuthServiceProvider),
  );
});
