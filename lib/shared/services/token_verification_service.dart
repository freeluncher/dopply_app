import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/shared/services/token_storage_service.dart';

/// Universal Token Verification Service
///
/// Handles token verification and refresh using the correct endpoints
/// as per API documentation
class TokenVerificationService {
  final String _baseUrl = 'https://dopply.my.id/api/v1';

  /// Verify current token validity
  /// Endpoint: GET /token/verify
  Future<Map<String, dynamic>?> verifyToken() async {
    final token = await TokenStorageService().getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/token/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print(
          '[TokenVerificationService] Token verification failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('[TokenVerificationService] verifyToken Exception: $e');
      return null;
    }
  }

  /// Check if current token is valid (simple boolean check)
  Future<bool> isTokenValid() async {
    final result = await verifyToken();
    return result != null && result['valid'] == true;
  }
}
