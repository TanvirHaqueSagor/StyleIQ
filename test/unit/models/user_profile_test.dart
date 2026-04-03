import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/models/user_profile.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

UserProfile _profile({
  String? id,
  String? email,
  String? displayName,
  String? subscriptionTier,
  DateTime? subscriptionExpiresAt,
  bool completedOnboarding = false,
  int analysesCount = 0,
}) =>
    UserProfile(
      id: id,
      email: email ?? 'test@example.com',
      displayName: displayName ?? 'Test User',
      completedOnboarding: completedOnboarding,
      analysesCount: analysesCount,
      subscriptionTier: subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('UserProfile construction', () {
    test('auto-generates UUID when id is null', () {
      final a = _profile();
      final b = _profile();
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('preserves provided id', () {
      final p = _profile(id: 'fixed-id');
      expect(p.id, 'fixed-id');
    });

    test('createdAt defaults to approximately now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final p = _profile();
      expect(p.createdAt.isAfter(before), isTrue);
    });

    test('completedOnboarding defaults to false', () {
      expect(_profile().completedOnboarding, isFalse);
    });

    test('analysesCount defaults to 0', () {
      expect(_profile().analysesCount, 0);
    });

    test('subscriptionTier defaults to null', () {
      expect(_profile().subscriptionTier, isNull);
    });
  });

  group('UserProfile.isFreeTier', () {
    test('returns true when subscriptionTier is null', () {
      expect(_profile(subscriptionTier: null).isFreeTier, isTrue);
    });

    test('returns true when subscriptionTier is "Free"', () {
      expect(_profile(subscriptionTier: 'Free').isFreeTier, isTrue);
    });

    test('returns false for Style+ tier', () {
      expect(_profile(subscriptionTier: 'Style+').isFreeTier, isFalse);
    });

    test('returns false for Style Pro tier', () {
      expect(_profile(subscriptionTier: 'Style Pro').isFreeTier, isFalse);
    });
  });

  group('UserProfile.hasActiveSubscription', () {
    test('returns false when subscriptionTier is null', () {
      expect(_profile(subscriptionTier: null).hasActiveSubscription, isFalse);
    });

    test('returns false when subscriptionExpiresAt is null', () {
      expect(
        _profile(subscriptionTier: 'Style+', subscriptionExpiresAt: null)
            .hasActiveSubscription,
        isFalse,
      );
    });

    test('returns true when tier is set and expiry is in the future', () {
      expect(
        _profile(
          subscriptionTier: 'Style Pro',
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        ).hasActiveSubscription,
        isTrue,
      );
    });

    test('returns false when expiry is in the past', () {
      expect(
        _profile(
          subscriptionTier: 'Style+',
          subscriptionExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ).hasActiveSubscription,
        isFalse,
      );
    });
  });

  group('UserProfile.fromJson', () {
    test('parses all fields', () {
      final now = DateTime(2024, 6, 1, 12);
      final expiry = DateTime(2025, 6, 1);
      final json = {
        'id': 'user-1',
        'email': 'test@styleiq.app',
        'display_name': 'Jane Doe',
        'photo_url': 'https://example.com/photo.jpg',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'dress_code': 'casual',
        'color_palette': 'warm',
        'style_goals': 'look professional',
        'cultural_background': 'Bengali',
        'fashion_adventure': 'yes',
        'shopping_budget': 'medium',
        'style_challenge': 'occasion dressing',
        'tips_frequency': 'daily',
        'completed_onboarding': true,
        'analyses_count': 7,
        'wardrobe_items_count': 12,
        'subscription_tier': 'Style Pro',
        'subscription_expires_at': expiry.toIso8601String(),
      };
      final p = UserProfile.fromJson(json);
      expect(p.id, 'user-1');
      expect(p.email, 'test@styleiq.app');
      expect(p.displayName, 'Jane Doe');
      expect(p.photoUrl, 'https://example.com/photo.jpg');
      expect(p.dressCode, 'casual');
      expect(p.colorPalette, 'warm');
      expect(p.styleGoals, 'look professional');
      expect(p.culturalBackground, 'Bengali');
      expect(p.completedOnboarding, isTrue);
      expect(p.analysesCount, 7);
      expect(p.wardrobeItemsCount, 12);
      expect(p.subscriptionTier, 'Style Pro');
      expect(p.subscriptionExpiresAt!.year, 2025);
    });

    test('handles missing optional fields with defaults', () {
      final p = UserProfile.fromJson({});
      expect(p.email, isNull);
      expect(p.displayName, isNull);
      expect(p.photoUrl, isNull);
      expect(p.dressCode, isNull);
      expect(p.culturalBackground, isNull);
      expect(p.completedOnboarding, isFalse);
      expect(p.analysesCount, 0);
      expect(p.wardrobeItemsCount, 0);
      expect(p.subscriptionTier, isNull);
      expect(p.subscriptionExpiresAt, isNull);
    });

    test('handles null subscription_expires_at', () {
      final p = UserProfile.fromJson({'subscription_expires_at': null});
      expect(p.subscriptionExpiresAt, isNull);
    });
  });

  group('UserProfile.toJson', () {
    test('includes all fields', () {
      final expiry = DateTime(2025, 1, 1);
      final p = UserProfile(
        id: 'u-1',
        email: 'a@b.com',
        displayName: 'A B',
        completedOnboarding: true,
        analysesCount: 3,
        wardrobeItemsCount: 5,
        subscriptionTier: 'Style+',
        subscriptionExpiresAt: expiry,
        culturalBackground: 'Punjabi',
      );
      final json = p.toJson();
      expect(json['id'], 'u-1');
      expect(json['email'], 'a@b.com');
      expect(json['display_name'], 'A B');
      expect(json['completed_onboarding'], isTrue);
      expect(json['analyses_count'], 3);
      expect(json['wardrobe_items_count'], 5);
      expect(json['subscription_tier'], 'Style+');
      expect(json['subscription_expires_at'], isA<String>());
      expect(json['cultural_background'], 'Punjabi');
      expect(json['created_at'], isA<String>());
    });

    test('serialises null subscriptionExpiresAt as null', () {
      final p = _profile(subscriptionExpiresAt: null);
      expect(p.toJson()['subscription_expires_at'], isNull);
    });

    test('round-trips correctly', () {
      final original = UserProfile(
        id: 'rt-user',
        email: 'rt@test.com',
        displayName: 'RT User',
        completedOnboarding: true,
        analysesCount: 5,
        subscriptionTier: 'Style Pro',
        subscriptionExpiresAt: DateTime(2025, 12, 31),
        culturalBackground: 'Arab',
      );
      final copy = UserProfile.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.email, original.email);
      expect(copy.displayName, original.displayName);
      expect(copy.completedOnboarding, original.completedOnboarding);
      expect(copy.analysesCount, original.analysesCount);
      expect(copy.subscriptionTier, original.subscriptionTier);
      expect(copy.culturalBackground, original.culturalBackground);
    });
  });

  group('UserProfile.copyWith', () {
    test('overrides only specified fields', () {
      final original = _profile(
        email: 'old@test.com',
        analysesCount: 2,
        completedOnboarding: false,
      );
      final updated = original.copyWith(
        analysesCount: 5,
        completedOnboarding: true,
      );
      expect(updated.analysesCount, 5);
      expect(updated.completedOnboarding, isTrue);
      expect(updated.email, original.email); // unchanged
      expect(updated.id, original.id);       // unchanged
    });

    test('can update subscriptionTier', () {
      final original = _profile(subscriptionTier: null);
      final updated = original.copyWith(subscriptionTier: 'Style Pro');
      expect(updated.subscriptionTier, 'Style Pro');
      expect(original.subscriptionTier, isNull); // immutable
    });

    test('can update culturalBackground', () {
      final original = _profile();
      final updated = original.copyWith(culturalBackground: 'Bengali');
      expect(updated.culturalBackground, 'Bengali');
    });

    test('preserves id when not specified', () {
      final original = _profile(id: 'keep-me');
      final updated = original.copyWith(analysesCount: 10);
      expect(updated.id, 'keep-me');
    });
  });
}
