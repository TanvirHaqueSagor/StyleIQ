import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/models/privacy_settings.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

PrivacySettings _settings({
  bool analyticsEnabled = true,
  bool crashReporting = true,
  bool personalizedAds = false,
  bool dataSharing = false,
  bool profileVisibility = true,
  bool wardrobePublic = false,
  String? userId,
}) =>
    PrivacySettings(
      userId: userId ?? 'test-user-id',
      analyticsEnabled: analyticsEnabled,
      crashReporting: crashReporting,
      personalizedAds: personalizedAds,
      dataSharing: dataSharing,
      profileVisibility: profileVisibility,
      wardrobePublic: wardrobePublic,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('PrivacySettings construction', () {
    test('creates with required fields', () {
      final settings = _settings();
      expect(settings.userId, 'test-user-id');
      expect(settings.analyticsEnabled, isTrue);
      expect(settings.crashReporting, isTrue);
    });

    test('defaults work correctly', () {
      final settings = PrivacySettings(userId: 'user-123');
      expect(settings.analyticsEnabled, isTrue);
      expect(settings.crashReporting, isTrue);
      expect(settings.personalizedAds, isFalse);
      expect(settings.dataSharing, isFalse);
      expect(settings.profileVisibility, isTrue);
      expect(settings.wardrobePublic, isFalse);
    });

    test('updatedAt defaults to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final settings = _settings();
      expect(settings.updatedAt.isAfter(before), isTrue);
    });
  });

  group('PrivacySettings JSON serialization', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'user_id': 'user-123',
        'analytics_enabled': false,
        'crash_reporting': true,
        'personalized_ads': true,
        'data_sharing': true,
        'profile_visibility': false,
        'wardrobe_public': true,
        'updated_at': '2024-01-15T10:30:00.000Z',
      };
      final settings = PrivacySettings.fromJson(json);
      expect(settings.userId, 'user-123');
      expect(settings.analyticsEnabled, isFalse);
      expect(settings.crashReporting, isTrue);
      expect(settings.personalizedAds, isTrue);
      expect(settings.dataSharing, isTrue);
      expect(settings.profileVisibility, isFalse);
      expect(settings.wardrobePublic, isTrue);
      expect(settings.updatedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {'user_id': 'user-123'};
      final settings = PrivacySettings.fromJson(json);
      expect(settings.userId, 'user-123');
      expect(settings.analyticsEnabled, isTrue);
      expect(settings.crashReporting, isTrue);
      expect(settings.personalizedAds, isFalse);
      expect(settings.dataSharing, isFalse);
      expect(settings.profileVisibility, isTrue);
      expect(settings.wardrobePublic, isFalse);
    });

    test('fromJson handles null updated_at', () {
      final json = {'user_id': 'user-123', 'updated_at': null};
      final settings = PrivacySettings.fromJson(json);
      expect(settings.updatedAt, isNotNull);
    });

    test('toJson includes all fields', () {
      final settings = _settings(
        userId: 'user-456',
        analyticsEnabled: false,
        personalizedAds: true,
      );
      final json = settings.toJson();
      expect(json['user_id'], 'user-456');
      expect(json['analytics_enabled'], isFalse);
      expect(json['personalized_ads'], isTrue);
      expect(json['updated_at'], isA<String>());
    });

    test('toJson round-trips', () {
      final original = _settings();
      final json = original.toJson();
      final restored = PrivacySettings.fromJson(json);
      expect(restored.userId, original.userId);
      expect(restored.analyticsEnabled, original.analyticsEnabled);
      expect(restored.crashReporting, original.crashReporting);
      expect(restored.personalizedAds, original.personalizedAds);
      expect(restored.dataSharing, original.dataSharing);
      expect(restored.profileVisibility, original.profileVisibility);
      expect(restored.wardrobePublic, original.wardrobePublic);
    });
  });

  group('PrivacySettings copyWith', () {
    test('overrides specified fields', () {
      final original = _settings(
        analyticsEnabled: true,
        dataSharing: false,
      );
      final updated = original.copyWith(
        analyticsEnabled: false,
        dataSharing: true,
        wardrobePublic: true,
      );
      expect(updated.analyticsEnabled, isFalse);
      expect(updated.dataSharing, isTrue);
      expect(updated.wardrobePublic, isTrue);
      expect(updated.crashReporting, original.crashReporting); // unchanged
      expect(updated.userId, original.userId); // unchanged
    });

    test('leaves fields unchanged when not specified', () {
      final original = _settings();
      final updated = original.copyWith();
      expect(updated.userId, original.userId);
      expect(updated.analyticsEnabled, original.analyticsEnabled);
      expect(updated.crashReporting, original.crashReporting);
    });
  });
}