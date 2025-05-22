import 'dart:convert';

/// Utility class untuk mendecode JWT dan mengecek expiry token.
class JwtDecoder {
  /// Mendecode JWT dan mengembalikan payload sebagai Map.
  ///
  /// [token]: JWT string (format: header.payload.signature)
  /// Throws Exception jika format JWT tidak valid.
  static Map<String, dynamic> decode(String token) {
    // JWT harus terdiri dari 3 bagian yang dipisahkan titik
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT');
    }
    // Ambil bagian payload (bagian ke-2)
    final payload = base64Url.normalize(parts[1]);
    // Decode base64Url dan parse JSON ke Map
    final payloadMap = json.decode(utf8.decode(base64Url.decode(payload)));
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid JWT payload');
    }
    return payloadMap;
  }

  /// Mengecek apakah token JWT sudah expired.
  ///
  /// [token]: JWT string
  /// Return true jika token sudah expired, false jika belum.
  static bool isExpired(String token) {
    final payload = decode(token);
    // Jika tidak ada field 'exp', anggap token tidak expired
    if (!payload.containsKey('exp')) return false;
    final exp = payload['exp'];
    // Konversi exp (epoch detik) ke DateTime
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    // Bandingkan dengan waktu sekarang
    return DateTime.now().isAfter(expiry);
  }
}
