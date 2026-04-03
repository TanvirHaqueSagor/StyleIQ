import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/models/notification_settings.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

NotificationSettings _settings({
  bool pushNotifications = true,
  bool emailNotifications = true,
  bool dailyStyleTips = false,
  bool weeklyDigest = true,
  bool newFeatures = false,
  bool culturalReminders = true,
  String? userId,
}) =>
    NotificationSettings(
      userId: userId ?? 'test-user-id',
      pushNotifications: pushNotifications,
      emailNotifications: emailNotifications,
      dailyStyleTips: dailyStyleTips,
      weeklyDigest: weeklyDigest,
      newFeatures: newFeatures,
      culturalReminders: culturalReminders,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationSettings construction', () {
    test('creates with required fields', () {
      final settings = _settings();
      expect(settings.userId, 'test-user-id');
      expect(settings.pushNotifications, isTrue);
      expect(settings.emailNotifications, isTrue);
    });

    test('defaults work correctly', () {
      final settings = NotificationSettings(userId: 'user-123');
      expect(settings.pushNotifications, isTrue);
      expect(settings.emailNotifications, isTrue);
      expect(settings.dailyStyleTips, isFalse);
      expect(settings.weeklyDigest, isTrue);
      expect(settings.newFeatures, isFalse);
      expect(settings.culturalReminders, isTrue);
    });

    test('updatedAt defaults to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final settings = _settings();
      expect(settings.updatedAt.isAfter(before), isTrue);
    });
  });

  group('NotificationSettings JSON serialization', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'user_id': 'user-123',
        'push_notifications': false,
        'email_notifications': true,
        'daily_style_tips': true,
        'weekly_digest': false,
        'new_features': true,
        'cultural_reminders': false,
        'updated_at': '2024-01-15T10:30:00.000Z',
      };
      final settings = NotificationSettings.fromJson(json);
      expect(settings.userId, 'user-123');
      expect(settings.pushNotifications, isFalse);
      expect(settings.emailNotifications, isTrue);
      expect(settings.dailyStyleTips, isTrue);
      expect(settings.weeklyDigest, isFalse);
      expect(settings.newFeatures, isTrue);
      expect(settings.culturalReminders, isFalse);
      expect(settings.updatedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {'user_id': 'user-123'};
      final settings = NotificationSettings.fromJson(json);
      expect(settings.userId, 'user-123');
      expect(settings.pushNotifications, isTrue);
      expect(settings.emailNotifications, isTrue);
      expect(settings.dailyStyleTips, isFalse);
      expect(settings.weeklyDigest, isTrue);
      expect(settings.newFeatures, isFalse);
      expect(settings.culturalReminders, isTrue);
    });

    test('fromJson handles null updated_at', () {
      final json = {'user_id': 'user-123', 'updated_at': null};
      final settings = NotificationSettings.fromJson(json);
      expect(settings.updatedAt, isNotNull);
    });

    test('toJson includes all fields', () {
      final settings = _settings(
        userId: 'user-456',
        pushNotifications: false,
        dailyStyleTips: true,
      );
      final json = settings.toJson();
      expect(json['user_id'], 'user-456');
      expect(json['push_notifications'], isFalse);
      expect(json['daily_style_tips'], isTrue);
      expect(json['updated_at'], isA<String>());
    });

    test('toJson round-trips', () {
      final original = _settings();
      final json = original.toJson();
      final restored = NotificationSettings.fromJson(json);
      expect(restored.userId, original.userId);
      expect(restored.pushNotifications, original.pushNotifications);
      expect(restored.emailNotifications, original.emailNotifications);
      expect(restored.dailyStyleTips, original.dailyStyleTips);
      expect(restored.weeklyDigest, original.weeklyDigest);
      expect(restored.newFeatures, original.newFeatures);
      expect(restored.culturalReminders, original.culturalReminders);
    });
  });

  group('NotificationSettings copyWith', () {
    test('overrides specified fields', () {
      final original = _settings(
        pushNotifications: true,
        dailyStyleTips: false,
      );
      final updated = original.copyWith(
        pushNotifications: false,
        dailyStyleTips: true,
        newFeatures: true,
      );
      expect(updated.pushNotifications, isFalse);
      expect(updated.dailyStyleTips, isTrue);
      expect(updated.newFeatures, isTrue);
      expect(updated.emailNotifications, original.emailNotifications); // unchanged
      expect(updated.userId, original.userId); // unchanged
    });

    test('leaves fields unchanged when not specified', () {
      final original = _settings();
      final updated = original.copyWith();
      expect(updated.userId, original.userId);
      expect(updated.pushNotifications, original.pushNotifications);
      expect(updated.emailNotifications, original.emailNotifications);
    });
  });
}