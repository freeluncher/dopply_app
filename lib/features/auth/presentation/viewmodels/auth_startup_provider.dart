import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dopply_app/features/auth/data/datasources/auth_local_datasource.dart';
import '../../domain/entities/user.dart';
import 'user_provider.dart';
import 'login_view_model.dart';

final authStartupProvider = FutureProvider<User?>((ref) async {
  final user = await ref.read(authRepositoryProvider).getCurrentUserFromToken();
  ref.read(userProvider.notifier).state = user;
  return user;
});

final tokenVerifyProvider = FutureProvider<bool>((ref) async {
  final localDataSource = AuthLocalDataSource();
  final token = await localDataSource.getToken();
  if (token == null) return false;
  final response = await http.get(
    Uri.parse('https://dopply.my.id/v1/token/verify'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Asumsikan response: {"valid": true/false}
    if (data is Map && data['valid'] == true) {
      return true;
    }
  }
  return false;
});
