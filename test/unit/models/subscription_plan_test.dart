import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/models/subscription_plan.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

SubscriptionPlan _plan({
  String? id,
  String? name,
  String? description,
  double? price,
  String? currency,
  String? interval,
  List<String>? features,
  int? maxAnalyses,
  int? maxWardrobeItems,
  bool? hasAiEngine,
  bool? hasCulturalDb,
  bool? hasPrioritySupport,
}) =>
    SubscriptionPlan(
      id: id ?? 'basic-plan',
      name: name ?? 'Basic Plan',
      description: description ?? 'Basic style analysis features',
      price: price ?? 9.99,
      currency: currency ?? 'USD',
      interval: interval ?? 'month',
      features: features ?? ['Basic analysis', 'Wardrobe tracking'],
      maxAnalyses: maxAnalyses ?? 10,
      maxWardrobeItems: maxWardrobeItems ?? 50,
      hasAiEngine: hasAiEngine ?? true,
      hasCulturalDb: hasCulturalDb ?? false,
      hasPrioritySupport: hasPrioritySupport ?? false,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SubscriptionPlan construction', () {
    test('creates with required fields', () {
      final plan = _plan();
      expect(plan.id, 'basic-plan');
      expect(plan.name, 'Basic Plan');
      expect(plan.price, 9.99);
    });

    test('defaults work correctly', () {
      final plan = SubscriptionPlan(
        id: 'free-plan',
        name: 'Free Plan',
        price: 0.0,
      );
      expect(plan.currency, 'USD');
      expect(plan.interval, 'month');
      expect(plan.features, isEmpty);
      expect(plan.maxAnalyses, isNull);
      expect(plan.maxWardrobeItems, isNull);
      expect(plan.hasAiEngine, isFalse);
      expect(plan.hasCulturalDb, isFalse);
      expect(plan.hasPrioritySupport, isFalse);
    });

    test('createdAt defaults to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final plan = _plan();
      expect(plan.createdAt.isAfter(before), isTrue);
    });
  });

  group('SubscriptionPlan JSON serialization', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'id': 'pro-plan',
        'name': 'Pro Plan',
        'description': 'Advanced features for style enthusiasts',
        'price': 19.99,
        'currency': 'USD',
        'interval': 'month',
        'features': ['Unlimited analysis', 'Cultural database', 'Priority support'],
        'max_analyses': null,
        'max_wardrobe_items': 200,
        'has_ai_engine': true,
        'has_cultural_db': true,
        'has_priority_support': true,
        'is_active': true,
        'created_at': '2024-01-15T10:30:00.000Z',
        'updated_at': '2024-01-20T15:45:00.000Z',
      };
      final plan = SubscriptionPlan.fromJson(json);
      expect(plan.id, 'pro-plan');
      expect(plan.name, 'Pro Plan');
      expect(plan.description, 'Advanced features for style enthusiasts');
      expect(plan.price, 19.99);
      expect(plan.currency, 'USD');
      expect(plan.interval, 'month');
      expect(plan.features, ['Unlimited analysis', 'Cultural database', 'Priority support']);
      expect(plan.maxAnalyses, isNull);
      expect(plan.maxWardrobeItems, 200);
      expect(plan.hasAiEngine, isTrue);
      expect(plan.hasCulturalDb, isTrue);
      expect(plan.hasPrioritySupport, isTrue);
      expect(plan.isActive, isTrue);
      expect(plan.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(plan.updatedAt, DateTime.parse('2024-01-20T15:45:00.000Z'));
    });

    test('fromJson uses defaults for missing fields', () {
      final json = {
        'id': 'basic-plan',
        'name': 'Basic',
        'price': 9.99,
      };
      final plan = SubscriptionPlan.fromJson(json);
      expect(plan.id, 'basic-plan');
      expect(plan.name, 'Basic');
      expect(plan.price, 9.99);
      expect(plan.currency, 'USD');
      expect(plan.interval, 'month');
      expect(plan.features, isEmpty);
      expect(plan.maxAnalyses, isNull);
      expect(plan.hasAiEngine, isFalse);
    });

    test('fromJson handles null dates', () {
      final json = {
        'id': 'plan-123',
        'name': 'Test Plan',
        'price': 5.99,
        'created_at': null,
        'updated_at': null,
      };
      final plan = SubscriptionPlan.fromJson(json);
      expect(plan.createdAt, isNotNull);
      expect(plan.updatedAt, isNotNull);
    });

    test('toJson includes all fields', () {
      final plan = _plan(
        id: 'premium-plan',
        name: 'Premium Plan',
        price: 29.99,
        hasCulturalDb: true,
      );
      final json = plan.toJson();
      expect(json['id'], 'premium-plan');
      expect(json['name'], 'Premium Plan');
      expect(json['price'], 29.99);
      expect(json['has_cultural_db'], isTrue);
      expect(json['created_at'], isA<String>());
      expect(json['updated_at'], isA<String>());
    });

    test('toJson round-trips', () {
      final original = _plan();
      final json = original.toJson();
      final restored = SubscriptionPlan.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.price, original.price);
      expect(restored.currency, original.currency);
      expect(restored.interval, original.interval);
      expect(restored.features, original.features);
      expect(restored.maxAnalyses, original.maxAnalyses);
      expect(restored.maxWardrobeItems, original.maxWardrobeItems);
      expect(restored.hasAiEngine, original.hasAiEngine);
      expect(restored.hasCulturalDb, original.hasCulturalDb);
      expect(restored.hasPrioritySupport, original.hasPrioritySupport);
      expect(restored.isActive, original.isActive);
    });
  });

  group('SubscriptionPlan copyWith', () {
    test('overrides specified fields', () {
      final original = _plan(
        price: 9.99,
        hasAiEngine: true,
      );
      final updated = original.copyWith(
        price: 14.99,
        hasCulturalDb: true,
        isActive: false,
      );
      expect(updated.price, 14.99);
      expect(updated.hasCulturalDb, isTrue);
      expect(updated.isActive, isFalse);
      expect(updated.name, original.name); // unchanged
      expect(updated.hasAiEngine, original.hasAiEngine); // unchanged
    });

    test('leaves fields unchanged when not specified', () {
      final original = _plan();
      final updated = original.copyWith();
      expect(updated.id, original.id);
      expect(updated.name, original.name);
      expect(updated.price, original.price);
    });
  });

  group('SubscriptionPlan business logic', () {
    test('isFree returns true for zero price', () {
      final freePlan = _plan(price: 0.0);
      final paidPlan = _plan(price: 9.99);
      expect(freePlan.isFree, isTrue);
      expect(paidPlan.isFree, isFalse);
    });

    test('formattedPrice returns correct format', () {
      final plan = _plan(price: 19.99, currency: 'USD');
      expect(plan.formattedPrice, '\$19.99');
    });

    test('formattedPrice handles different currencies', () {
      final usdPlan = _plan(price: 15.00, currency: 'USD');
      final eurPlan = _plan(price: 12.50, currency: 'EUR');
      expect(usdPlan.formattedPrice, '\$15.00');
      expect(eurPlan.formattedPrice, '€12.50');
    });
  });
}