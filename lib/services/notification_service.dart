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
}
