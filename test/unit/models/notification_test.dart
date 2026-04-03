import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/models/notification.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Notification _notification({
  String? id,
  String? userId,
  String? title,
  String? message,
  String? type,
  String? category,
  bool? isRead,
  Map<String, dynamic>? data,
  DateTime? createdAt,
  DateTime? readAt,
}) =>
    Notification(
      id: id,
      userId: userId ?? 'test-user-id',
      title: title ?? 'Style Tip of the Day',
      message: message ?? 'Try pairing navy with white for a classic look',
      type: type ?? 'tip',
      category: category ?? 'style_advice',
      isRead: isRead ?? false,
      data: data ?? {'tip_id': 'navy-white-combo'},
      createdAt: createdAt,
      readAt: readAt,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('Notification construction', () {
    test('auto-generates UUID when id is null', () {
      final a = _notification();
      final b = _notification();
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('preserves provided id', () {
      final notification = _notification(id: 'fixed-id');
      expect(notification.id, 'fixed-id');
    });

    test('creates with required fields', () {
      final notification = _notification();
      expect(notification.userId, 'test-user-id');
      expect(notification.title, 'Style Tip of the Day');
      expect(notification.message, 'Try pairing navy with white for a classic look');
      expect(notification.type, 'tip');
    });

    test('defaults work correctly', () {
      final notification = Notification(
        userId: 'user-123',
        title: 'Welcome!',
        message: 'Welcome to StyleIQ',
        type: 'welcome',
      );
      expect(notification.category, isNull);
      expect(notification.isRead, isFalse);
      expect(notification.data, isNull);
    });

    test('createdAt defaults to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final notification = _notification();
      expect(notification.createdAt.isAfter(before), isTrue);
    });
  });

  group('Notification JSON serialization', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'id': 'notif-123',
        'user_id': 'user-456',
        'title': 'Analysis Complete',
        'message': 'Your outfit scored 85/100!',
        'type': 'analysis_result',
        'category': 'feedback',
        'is_read': true,
        'data': {'analysis_id': 'abc-123', 'score': 85},
        'created_at': '2024-01-15T10:30:00.000Z',
        'read_at': '2024-01-15T10:35:00.000Z',
      };
      final notification = Notification.fromJson(json);
      expect(notification.id, 'notif-123');
      expect(notification.userId, 'user-456');
      expect(notification.title, 'Analysis Complete');
      expect(notification.message, 'Your outfit scored 85/100!');
      expect(notification.type, 'analysis_result');
      expect(notification.category, 'feedback');
      expect(notification.isRead, isTrue);
      expect(notification.data, {'analysis_id': 'abc-123', 'score': 85});
      expect(notification.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(notification.readAt, DateTime.parse('2024-01-15T10:35:00.000Z'));
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {
        'id': 'notif-123',
        'user_id': 'user-456',
        'title': 'Test',
        'message': 'Test message',
        'type': 'test',
      };
      final notification = Notification.fromJson(json);
      expect(notification.id, 'notif-123');
      expect(notification.category, isNull);
      expect(notification.isRead, isFalse);
      expect(notification.data, isNull);
      expect(notification.readAt, isNull);
    });

    test('fromJson handles null dates', () {
      final json = {
        'id': 'notif-123',
        'user_id': 'user-456',
        'title': 'Test',
        'message': 'Test message',
        'type': 'test',
        'created_at': null,
        'read_at': null,
      };
      final notification = Notification.fromJson(json);
      expect(notification.createdAt, isNotNull);
      expect(notification.readAt, isNull);
    });

    test('toJson includes all fields', () {
      final notification = _notification(
        id: 'custom-id',
        title: 'Custom Title',
        isRead: true,
        data: {'key': 'value'},
      );
      final json = notification.toJson();
      expect(json['id'], 'custom-id');
      expect(json['title'], 'Custom Title');
      expect(json['is_read'], isTrue);
      expect(json['data'], {'key': 'value'});
      expect(json['created_at'], isA<String>());
    });

    test('toJson round-trips', () {
      final original = _notification();
      final json = original.toJson();
      final restored = Notification.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.type, original.type);
      expect(restored.category, original.category);
      expect(restored.isRead, original.isRead);
      expect(restored.data, original.data);
      expect(restored.readAt, original.readAt);
    });
  });

  group('Notification copyWith', () {
    test('overrides specified fields', () {
      final original = _notification(
        isRead: false,
        title: 'Original Title',
      );
      final updated = original.copyWith(
        isRead: true,
        title: 'Updated Title',
        category: 'updated_category',
      );
      expect(updated.isRead, isTrue);
      expect(updated.title, 'Updated Title');
      expect(updated.category, 'updated_category');
      expect(updated.message, original.message); // unchanged
      expect(updated.userId, original.userId); // unchanged
    });

    test('leaves fields unchanged when not specified', () {
      final original = _notification();
      final updated = original.copyWith();
      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.isRead, original.isRead);
    });
  });

  group('Notification business logic', () {
    test('markAsRead sets isRead to true and readAt to now', () {
      final notification = _notification(isRead: false);
      final marked = notification.markAsRead();
      expect(marked.isRead, isTrue);
      expect(marked.readAt, isNotNull);
      expect(marked.id, notification.id); // other fields unchanged
    });

    test('markAsRead does nothing if already read', () {
      final originalReadAt = DateTime.now().subtract(const Duration(hours: 1));
      final notification = _notification(
        isRead: true,
        readAt: originalReadAt,
      );
      final marked = notification.markAsRead();
      expect(marked.readAt, originalReadAt); // preserves original read time
    });

    test('isUnread returns opposite of isRead', () {
      final readNotification = _notification(isRead: true);
      final unreadNotification = _notification(isRead: false);
      expect(readNotification.isUnread, isFalse);
      expect(unreadNotification.isUnread, isTrue);
    });

    test('formattedCreatedAt returns readable date', () {
      final notification = _notification();
      expect(notification.formattedCreatedAt, isNotEmpty);
      // Should contain some date-like formatting
      expect(notification.formattedCreatedAt.contains('/') ||
             notification.formattedCreatedAt.contains('-') ||
             notification.formattedCreatedAt.contains('AM') ||
             notification.formattedCreatedAt.contains('PM'), isTrue);
    });
  });
}