import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/user.dart';

/// Global user state provider
///
/// Manages the current authenticated user state across the application.
/// This is the central source of truth for user authentication status.
final userProvider = StateProvider<User?>((ref) => null);
