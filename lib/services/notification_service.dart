import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dopply_app/models/notification.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  // Get notifications for doctor
  Future<List<NotificationItem>> getNotifications() async {
    // TODO: Implement API call to /monitoring/notifications
    throw UnimplementedError('Notification service not implemented yet');
  }

  // Mark notification as read
  Future<bool> markAsRead(int notificationId) async {
    // TODO: Implement API call to /monitoring/notifications/read/{id}
    throw UnimplementedError('Mark as read not implemented yet');
  }
}
