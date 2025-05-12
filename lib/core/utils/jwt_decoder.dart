import 'dart:convert';

class JwtDecoder {
  static Map<String, dynamic> decode(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT');
    }
    final payload = base64Url.normalize(parts[1]);
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid JWT payload');
    }
    return payloadMap;
  }

  static bool isExpired(String token) {
    final payload = decode(token);
    if (!payload.containsKey('exp')) return false;
    final exp = payload['exp'];
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiry);
  }
}
