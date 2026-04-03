import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';

WardrobeItem _item({
  String category = 'Top',
  String subcategory = 'T-Shirt',
  String color = 'white',
  String imageUrl = 'data:image/jpeg;base64,abc',
  String userId = 'guest',
}) =>
    WardrobeItem(
      category: category,
      subcategory: subcategory,
      color: color,
      imageUrl: imageUrl,
      userId: userId,
    );

void main() {
  group('WardrobeItem', () {
    test('auto-generates UUID id when not provided', () {
      final a = _item();
      final b = _item();
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id))); // UUIDs must be unique
    });

    test('uses provided id when given', () {
      final item = WardrobeItem(
        id: 'my-fixed-id',
        category: 'Top',
        subcategory: 'Shirt',
        color: 'blue',
        imageUrl: '',
        userId: 'guest',
      );
      expect(item.id, 'my-fixed-id');
    });

    test('addedAt defaults to now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final item = _item();
      expect(item.addedAt.isAfter(before), isTrue);
    });

    test('fromJson parses all fields', () {
      final now = DateTime.now();
      final json = {
        'id': 'test-id',
        'category': 'Shoes',
        'subcategory': 'Sneakers',
        'color': 'black',
        'tags': ['casual', 'sport'],
        'notes': 'My favourites',
        'image_url': 'data:image/jpeg;base64,xyz',
        'added_at': now.toIso8601String(),
        'last_worn_at': null,
        'wear_count': 5,
        'is_favorite': true,
        'user_id': 'guest',
      };
      final item = WardrobeItem.fromJson(json);
      expect(item.id, 'test-id');
      expect(item.category, 'Shoes');
      expect(item.subcategory, 'Sneakers');
      expect(item.tags, ['casual', 'sport']);
      expect(item.notes, 'My favourites');
      expect(item.wearCount, 5);
      expect(item.isFavorite, isTrue);
      expect(item.lastWornAt, isNull);
    });

    test('fromJson defaults for missing fields', () {
      final item = WardrobeItem.fromJson({});
      expect(item.category, '');
      expect(item.tags, isEmpty);
      expect(item.wearCount, 0);
      expect(item.isFavorite, isFalse);
    });

    test('toJson round-trips', () {
      final item = _item(category: 'Bottom', subcategory: 'Jeans', color: 'blue');
      final item2 = WardrobeItem.fromJson(item.toJson());
      expect(item2.id, item.id);
      expect(item2.category, item.category);
      expect(item2.subcategory, item.subcategory);
      expect(item2.color, item.color);
      expect(item2.userId, item.userId);
    });

    test('copyWith overrides only specified fields', () {
      final item = _item();
      final updated = item.copyWith(isFavorite: true, wearCount: 3);
      expect(updated.isFavorite, isTrue);
      expect(updated.wearCount, 3);
      expect(updated.category, item.category); // unchanged
      expect(updated.id, item.id); // id preserved
    });

    test('displayName combines subcategory and category', () {
      final item = _item(category: 'Top', subcategory: 'Blazer');
      expect(item.displayName, 'Blazer (Top)');
    });

    test('wasWornRecently returns false when never worn', () {
      expect(_item().wasWornRecently, isFalse);
    });

    test('wasWornRecently returns true when worn within 7 days', () {
      final item = WardrobeItem(
        category: 'Top',
        subcategory: 'Shirt',
        color: 'white',
        imageUrl: '',
        userId: 'guest',
        lastWornAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(item.wasWornRecently, isTrue);
    });

    test('wasWornRecently returns false when worn over 7 days ago', () {
      final item = WardrobeItem(
        category: 'Top',
        subcategory: 'Shirt',
        color: 'white',
        imageUrl: '',
        userId: 'guest',
        lastWornAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(item.wasWornRecently, isFalse);
    });

    test('daysSinceAdded is zero for item added now', () {
      final item = _item();
      expect(item.daysSinceAdded, 0);
    });
  });
}
