import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import 'user_provider.dart';
import 'login_view_model.dart';

final authStartupProvider = FutureProvider<User?>((ref) async {
  final user = await ref.read(authRepositoryProvider).getCurrentUserFromToken();
  ref.read(userProvider.notifier).state = user;
  return user;
});
