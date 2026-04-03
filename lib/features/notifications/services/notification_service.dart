import 'package:styleiq/models/notification.dart' as app_notification;
import 'package:styleiq/services/storage/local_storage_service.dart';

/// Simple notification inbox API backed by Hive via LocalStorageService.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final LocalStorageService _storage = LocalStorageService();

  NotificationService._internal();

  Future<List<app_notification.Notification>> getNotifications(String userId) {
    return _storage.getNotifications(userId);
  }

  Future<void> addNotification(String userId, app_notification.Notification notification) {
    return _storage.addNotification(userId, notification);
  }

  Future<void> markAsRead(String userId, String notificationId) {
    return _storage.markNotificationRead(userId, notificationId);
  }

  Future<void> markAllAsRead(String userId) {
    return _storage.markAllNotificationsRead(userId);
  }

  Future<int> unreadCount(String userId) {
    return _storage.unreadNotificationCount(userId);
  }

  Future<app_notification.Notification> createDemoNotification(String userId) async {
    final notification = app_notification.Notification(
      userId: userId,
      title: 'Welcome to StyleIQ',
      message: 'Your community feed is ready. Browse new posts and get inspired!',
      type: 'info',
      category: 'general',
    );
    await addNotification(userId, notification);
    return notification;
  }
}
