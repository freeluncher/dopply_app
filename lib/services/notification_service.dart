import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dopply_app/models/monitoring_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/notification.dart';
import 'package:dopply_app/core/api_client.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final ApiClient _apiClient = ApiClient();

  // Get notifications for doctor
  Future<List<NotificationItem>> getNotifications() async {
    // TODO: Implement API call to https://dopply.my.id/api/v1/monitoring/notifications
    throw UnimplementedError('Notification service not implemented yet');
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    // TODO: Implement API call to https://dopply.my.id/api/v1/monitoring/notifications/read/{id}
    throw UnimplementedError('Mark as read not implemented yet');
  }

  static Future<List<MonitoringNotification>> fetchNotifications(
    String jwt, {
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://dopply.my.id/api/v1/monitoring/notifications?skip=$skip&limit=$limit',
      ),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );
    final jsonResponse = json.decode(response.body);
    final notifList = jsonResponse['notifications'] as List;
    return notifList.map((n) => MonitoringNotification.fromJson(n)).toList();
  }

  static Future<bool> markNotificationRead(
    String jwt,
    int notificationId,
  ) async {
    final response = await http.post(
      Uri.parse(
        'https://dopply.my.id/api/v1/monitoring/notifications/read/$notificationId',
      ),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }
}
