import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:styleiq/features/notifications/services/notification_service.dart';
import 'package:styleiq/models/notification.dart' as app_notification;
import 'package:styleiq/services/storage/local_storage_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('styleiq_test_');
    Hive.init(tempDir.path);

    await Hive.openBox<String>(LocalStorageService.notificationSettingsBox);
    await Hive.openBox<String>(LocalStorageService.privacySettingsBox);
    await Hive.openBox<String>(LocalStorageService.subscriptionBox);
    await Hive.openBox<String>(LocalStorageService.notificationsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('NotificationService', () {
    const userId = 'test-user';

    test('initial state has no notifications', () async {
      final service = NotificationService();
      final notifications = await service.getNotifications(userId);
      expect(notifications, isEmpty);
    });

    test('addNotification stores and counts unread correctly', () async {
      final service = NotificationService();
      final note = app_notification.Notification(
        userId: userId,
        title: 'New Test',
        message: 'Test message',
        type: 'test',
      );

      await service.addNotification(userId, note);
      final all = await service.getNotifications(userId);
      expect(all.length, 1);
      expect(all.first.title, 'New Test');
      expect(await service.unreadCount(userId), 1);
    });

    test('markAsRead toggles notification state', () async {
      final service = NotificationService();
      final all = await service.getNotifications(userId);
      if (all.isEmpty) {
        fail('Expected at least one notification after addNotification test');
      }
      final id = all.first.id;
      await service.markAsRead(userId, id);
      final updated = await service.getNotifications(userId);
      final first = updated.firstWhere((n) => n.id == id);
      expect(first.isRead, isTrue);
      expect(await service.unreadCount(userId), 0);
    });

    test('markAllAsRead sets all notifications read', () async {
      final service = NotificationService();
      await service.addNotification(
        userId,
        app_notification.Notification(
          userId: userId,
          title: 'Another',
          message: 'Message',
          type: 'test',
        ),
      );
      await service.markAllAsRead(userId);
      expect(await service.unreadCount(userId), 0);
    });
  });
}
