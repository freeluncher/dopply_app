import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cache entry model
class CacheEntry {
  final String data;
  final DateTime timestamp;
  final Duration duration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.duration,
  });

  bool get isExpired => DateTime.now().isAfter(timestamp.add(duration));

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'duration': duration.inMilliseconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }
}

/// Cache keys untuk data spesifik
class CacheKeys {
  static const String userProfile = 'user_profile';
  static const String doctorList = 'doctor_list';
  static const String patientList = 'patient_list';
  static const String monitoringHistory = 'monitoring_history';
  static const String systemStats = 'system_stats';
  static const String sharedRecords = 'shared_records';

  /// Generate cache key dengan parameter
  static String withParams(String baseKey, Map<String, dynamic> params) {
    final sortedParams =
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final paramString = sortedParams
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${baseKey}_$paramString';
  }
}

/// Service untuk mengelola cache aplikasi
/// Menyediakan caching untuk response API dan data offline
class CacheService {
  final FlutterSecureStorage _storage;
  static const String _cachePrefix = 'cache_';
  static const Duration _defaultCacheDuration = Duration(minutes: 30);

  CacheService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Simpan data ke cache
  Future<void> set(String key, dynamic data, {Duration? duration}) async {
    try {
      final cacheEntry = CacheEntry(
        data: jsonEncode(data),
        timestamp: DateTime.now(),
        duration: duration ?? _defaultCacheDuration,
      );

      await _storage.write(
        key: '$_cachePrefix$key',
        value: jsonEncode(cacheEntry.toJson()),
      );

      print('[CACHE] Cached data for key: $key');
    } catch (e) {
      print('[CACHE] Error caching data for key $key: $e');
    }
  }

  /// Ambil data dari cache
  Future<T?> get<T>(String key) async {
    try {
      final cachedValue = await _storage.read(key: '$_cachePrefix$key');
      if (cachedValue == null) {
        print('[CACHE] No cached data for key: $key');
        return null;
      }

      final cacheEntry = CacheEntry.fromJson(
        jsonDecode(cachedValue) as Map<String, dynamic>,
      );

      if (cacheEntry.isExpired) {
        print('[CACHE] Cached data expired for key: $key');
        await remove(key);
        return null;
      }

      print('[CACHE] Retrieved cached data for key: $key');
      return jsonDecode(cacheEntry.data) as T;
    } catch (e) {
      print('[CACHE] Error retrieving cached data for key $key: $e');
      return null;
    }
  }

  /// Hapus data dari cache
  Future<void> remove(String key) async {
    try {
      await _storage.delete(key: '$_cachePrefix$key');
      print('[CACHE] Removed cached data for key: $key');
    } catch (e) {
      print('[CACHE] Error removing cached data for key $key: $e');
    }
  }

  /// Hapus semua data cache
  Future<void> clear() async {
    try {
      final allKeys = await _storage.readAll();
      final cacheKeys =
          allKeys.keys.where((key) => key.startsWith(_cachePrefix)).toList();

      for (final key in cacheKeys) {
        await _storage.delete(key: key);
      }

      print('[CACHE] Cleared all cached data');
    } catch (e) {
      print('[CACHE] Error clearing cache: $e');
    }
  }

  /// Cek apakah data ada di cache dan belum expired
  Future<bool> has(String key) async {
    try {
      final cachedValue = await _storage.read(key: '$_cachePrefix$key');
      if (cachedValue == null) return false;

      final cacheEntry = CacheEntry.fromJson(
        jsonDecode(cachedValue) as Map<String, dynamic>,
      );

      return !cacheEntry.isExpired;
    } catch (e) {
      print('[CACHE] Error checking cache for key $key: $e');
      return false;
    }
  }

  /// Ambil semua keys yang ada di cache
  Future<List<String>> getAllCacheKeys() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys
          .where((key) => key.startsWith(_cachePrefix))
          .map((key) => key.substring(_cachePrefix.length))
          .toList();
    } catch (e) {
      print('[CACHE] Error getting cache keys: $e');
      return [];
    }
  }

  /// Cleanup expired cache entries
  Future<void> cleanupExpired() async {
    try {
      final allKeys = await _storage.readAll();
      final cacheKeys =
          allKeys.keys.where((key) => key.startsWith(_cachePrefix)).toList();

      int cleanedCount = 0;

      for (final key in cacheKeys) {
        try {
          final cachedValue = allKeys[key];
          if (cachedValue == null) continue;

          final cacheEntry = CacheEntry.fromJson(
            jsonDecode(cachedValue) as Map<String, dynamic>,
          );

          if (cacheEntry.isExpired) {
            await _storage.delete(key: key);
            cleanedCount++;
          }
        } catch (e) {
          // Invalid cache entry, delete it
          await _storage.delete(key: key);
          cleanedCount++;
        }
      }

      print('[CACHE] Cleaned up $cleanedCount expired cache entries');
    } catch (e) {
      print('[CACHE] Error during cache cleanup: $e');
    }
  }

  /// Get cache size (number of entries)
  Future<int> getCacheSize() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys.where((key) => key.startsWith(_cachePrefix)).length;
    } catch (e) {
      print('[CACHE] Error getting cache size: $e');
      return 0;
    }
  }
}
