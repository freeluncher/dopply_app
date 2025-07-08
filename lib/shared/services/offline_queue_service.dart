import 'package:dopply_app/shared/services/cache_service.dart';

/// Queue item model untuk offline requests
class QueueItem {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, String>? headers;
  final DateTime timestamp;
  final int retryCount;

  QueueItem({
    required this.id,
    required this.method,
    required this.endpoint,
    this.data,
    this.headers,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'endpoint': endpoint,
    'data': data,
    'headers': headers,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      id: json['id'] as String,
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      data: json['data'] as Map<String, dynamic>?,
      headers: (json['headers'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  QueueItem copyWith({
    String? id,
    String? method,
    String? endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return QueueItem(
      id: id ?? this.id,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Offline queue untuk menyimpan request yang gagal
class OfflineQueueService {
  final CacheService _cacheService;
  static const String _queueKey = 'offline_queue';

  OfflineQueueService({CacheService? cacheService})
    : _cacheService = cacheService ?? CacheService();

  /// Tambah request ke queue
  Future<void> addToQueue({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final queue = await _getQueue();

      final item = QueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        method: method,
        endpoint: endpoint,
        data: data,
        headers: headers,
        timestamp: DateTime.now(),
      );

      queue.add(item);
      await _saveQueue(queue);

      print(
        '[OFFLINE_QUEUE] Added request to queue: ${item.method} ${item.endpoint}',
      );
    } catch (e) {
      print('[OFFLINE_QUEUE] Error adding to queue: $e');
    }
  }

  /// Ambil semua items dalam queue
  Future<List<QueueItem>> _getQueue() async {
    try {
      final queueData = await _cacheService.get<List<dynamic>>(_queueKey);
      if (queueData == null) return [];

      return queueData
          .map((item) => QueueItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[OFFLINE_QUEUE] Error getting queue: $e');
      return [];
    }
  }

  /// Simpan queue
  Future<void> _saveQueue(List<QueueItem> queue) async {
    try {
      final queueData = queue.map((item) => item.toJson()).toList();
      await _cacheService.set(
        _queueKey,
        queueData,
        duration: const Duration(days: 7),
      );
    } catch (e) {
      print('[OFFLINE_QUEUE] Error saving queue: $e');
    }
  }

  /// Process queue ketika koneksi kembali
  Future<List<QueueItem>> processQueue() async {
    try {
      final queue = await _getQueue();
      final failedItems = <QueueItem>[];

      print('[OFFLINE_QUEUE] Processing ${queue.length} queued requests');

      for (final item in queue) {
        try {
          // Simulate API call processing
          // Implementasi actual API call akan dilakukan di enhanced API client
          print('[OFFLINE_QUEUE] Processing: ${item.method} ${item.endpoint}');

          // Jika gagal, tambahkan ke failed items dengan retry count
          // Untuk sekarang, anggap berhasil semua untuk testing
        } catch (e) {
          print('[OFFLINE_QUEUE] Failed to process item ${item.id}: $e');

          // Increment retry count
          final updatedItem = item.copyWith(retryCount: item.retryCount + 1);

          // Hanya retry maksimal 3 kali
          if (updatedItem.retryCount <= 3) {
            failedItems.add(updatedItem);
          }
        }
      }

      // Simpan failed items kembali ke queue
      await _saveQueue(failedItems);

      print(
        '[OFFLINE_QUEUE] Processing complete. ${failedItems.length} items failed',
      );
      return failedItems;
    } catch (e) {
      print('[OFFLINE_QUEUE] Error processing queue: $e');
      return [];
    }
  }

  /// Clear queue
  Future<void> clearQueue() async {
    try {
      await _cacheService.remove(_queueKey);
      print('[OFFLINE_QUEUE] Queue cleared');
    } catch (e) {
      print('[OFFLINE_QUEUE] Error clearing queue: $e');
    }
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    try {
      final queue = await _getQueue();
      return queue.length;
    } catch (e) {
      print('[OFFLINE_QUEUE] Error getting queue size: $e');
      return 0;
    }
  }
}
