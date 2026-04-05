import 'package:dio/dio.dart';
import 'package:styleiq/features/notifications/services/notification_service.dart';
import 'package:styleiq/models/notification.dart' as app_notification;
import 'package:styleiq/models/notification_settings.dart';
import 'package:styleiq/models/privacy_settings.dart';
import 'package:styleiq/models/subscription_plan.dart';

/// This service is a backend sync layer.
///
/// For now it uses placeholder API endpoints and falls back to local storage.
class StyleIQApiService {
  final Dio _dio;
  final NotificationService _notificationService;

  StyleIQApiService({Dio? dio, NotificationService? notificationService})
      : _dio = dio ?? Dio(),
        _notificationService = notificationService ?? NotificationService();

  String get _baseUrl => 'https://api.styleiq.app/v1';

  /// Backend sync, if available.
  Future<void> syncNotificationSettings(
    String userId,
    NotificationSettings settings,
  ) async {
    final url = '$_baseUrl/users/$userId/notification-settings';
    try {
      await _dio.put(
        url,
        data: settings.toJson(),
        options: Options(headers: {'content-type': 'application/json'}),
      );
    } catch (_) {
      // Fallback: local persistence only
    }
  }

  Future<void> syncPrivacySettings(
      String userId, PrivacySettings settings) async {
    final url = '$_baseUrl/users/$userId/privacy-settings';
    try {
      await _dio.put(url, data: settings.toJson());
    } catch (_) {
      // no-op fallback
    }
  }

  Future<void> syncSubscription(
      String userId, SubscriptionPlan subscription) async {
    final url = '$_baseUrl/users/$userId/subscription';
    try {
      await _dio.put(url, data: subscription.toJson());
    } catch (_) {
      // no-op fallback
    }
  }

  Future<List<app_notification.Notification>> fetchNotifications(
      String userId) async {
    final url = '$_baseUrl/users/$userId/notifications';
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => app_notification.Notification.fromJson(item))
            .toList();
        return list;
      }
      return await _notificationService.getNotifications(userId);
    } catch (_) {
      return await _notificationService.getNotifications(userId);
    }
  }

  Future<void> postNotification(
      String userId, app_notification.Notification notification) async {
    final url = '$_baseUrl/users/$userId/notifications';
    try {
      await _dio.post(url, data: notification.toJson());
    } catch (_) {
      await _notificationService.addNotification(userId, notification);
    }
  }
}
