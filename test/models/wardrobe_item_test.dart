import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

WardrobeItem _item({
  String? id,
  String category = 'Top',
  String subcategory = 'T-Shirt',
  String color = 'white',
  List<String> tags = const ['casual'],
  String? notes,
  String imageUrl = 'data:image/jpeg;base64,abc',
  DateTime? addedAt,
  DateTime? lastWornAt,
  int wearCount = 0,
  bool isFavorite = false,
  String userId = 'guest',
}) =>
    WardrobeItem(
      id: id,
      category: category,
      subcategory: subcategory,
      color: color,
      tags: tags,
      notes: notes,
      imageUrl: imageUrl,
      addedAt: addedAt,
      lastWornAt: lastWornAt,
      wearCount: wearCount,
      isFavorite: isFavorite,
      userId: userId,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('WardrobeItem construction', () {
    test('auto-generates UUID when id is null', () {
      final a = _item();
      final b = _item();
      expect(a.id, isNotEmpty);
      expect(a.id, isNot(equals(b.id)));
    });

    test('preserves provided id', () {
      final item = _item(id: 'fixed-id');
      expect(item.id, 'fixed-id');
    });

    test('addedAt defaults to approximately now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final item = _item();
      expect(item.addedAt.isAfter(before), isTrue);
    });

    test('tags default to empty list', () {
      final item = WardrobeItem(
        category: 'Top',
        subcategory: 'Shirt',
        color: 'blue',
        imageUrl: '',
        userId: 'guest',
      );
      expect(item.tags, isEmpty);
    });

    test('wearCount defaults to 0', () {
      final item = _item();
      expect(item.wearCount, 0);
    });

    test('isFavorite defaults to false', () {
      final item = _item();
      expect(item.isFavorite, isFalse);
    });
  });

  group('WardrobeItem.fromJson', () {
    test('parses all fields', () {
      final now = DateTime(2024, 6, 1, 12);
      final lastWorn = DateTime(2024, 5, 25);
      final json = {
        'id': 'test-id',
        'category': 'Shoes',
        'subcategory': 'Sneakers',
        'color': 'black',
        'tags': ['casual', 'sport'],
        'notes': 'My favourites',
        'image_url': 'data:image/jpeg;base64,xyz',
        'added_at': now.toIso8601String(),
        'last_worn_at': lastWorn.toIso8601String(),
        'wear_count': 5,
        'is_favorite': true,
        'user_id': 'user_abc',
      };
      final item = WardrobeItem.fromJson(json);
      expect(item.id, 'test-id');
      expect(item.category, 'Shoes');
      expect(item.subcategory, 'Sneakers');
      expect(item.color, 'black');
      expect(item.tags, ['casual', 'sport']);
      expect(item.notes, 'My favourites');
      expect(item.imageUrl, 'data:image/jpeg;base64,xyz');
      expect(item.wearCount, 5);
      expect(item.isFavorite, isTrue);
      expect(item.userId, 'user_abc');
      expect(item.lastWornAt!.year, 2024);
      expect(item.lastWornAt!.month, 5);
      expect(item.lastWornAt!.day, 25);
    });

    test('handles null last_worn_at', () {
      final json = {
        'id': 'x',
        'category': 'Top',
        'subcategory': 'Shirt',
        'color': 'white',
        'image_url': '',
        'added_at': DateTime.now().toIso8601String(),
        'last_worn_at': null,
        'user_id': 'guest',
      };
      final item = WardrobeItem.fromJson(json);
      expect(item.lastWornAt, isNull);
    });

    test('handles null notes', () {
      final item = WardrobeItem.fromJson({
        'id': 'x',
        'category': 'Bottom',
        'subcategory': 'Jeans',
        'color': 'blue',
        'image_url': '',
        'user_id': 'guest',
      });
      expect(item.notes, isNull);
    });

    test('defaults for all missing fields', () {
      final item = WardrobeItem.fromJson({});
      expect(item.category, '');
      expect(item.subcategory, '');
      expect(item.color, '');
      expect(item.tags, isEmpty);
      expect(item.imageUrl, '');
      expect(item.wearCount, 0);
      expect(item.isFavorite, isFalse);
      expect(item.userId, '');
      expect(item.lastWornAt, isNull);
      expect(item.notes, isNull);
    });
  });

  group('WardrobeItem.toJson', () {
    test('serialises all fields', () {
      final addedAt = DateTime(2024, 6, 1, 12);
      final lastWorn = DateTime(2024, 5, 28);
      final item = WardrobeItem(
        id: 'item-1',
        category: 'Bottom',
        subcategory: 'Jeans',
        color: 'indigo',
        tags: ['casual', 'everyday'],
        notes: 'Favourite pair',
        imageUrl: 'data:image/jpeg;base64,abc',
        addedAt: addedAt,
        lastWornAt: lastWorn,
        wearCount: 12,
        isFavorite: true,
        userId: 'user_1',
      );
      final json = item.toJson();
      expect(json['id'], 'item-1');
      expect(json['category'], 'Bottom');
      expect(json['subcategory'], 'Jeans');
      expect(json['color'], 'indigo');
      expect(json['tags'], ['casual', 'everyday']);
      expect(json['notes'], 'Favourite pair');
      expect(json['image_url'], 'data:image/jpeg;base64,abc');
      expect(json['wear_count'], 12);
      expect(json['is_favorite'], isTrue);
      expect(json['user_id'], 'user_1');
      expect(json['added_at'], isA<String>());
      expect(json['last_worn_at'], isA<String>());
    });

    test('serialises null last_worn_at as null', () {
      final item = _item(lastWornAt: null);
      expect(item.toJson()['last_worn_at'], isNull);
    });

    test('serialises null notes as null', () {
      final item = _item(notes: null);
      expect(item.toJson()['notes'], isNull);
    });

    test('toJson / fromJson round-trip preserves all fields', () {
      final original = _item(
        id: 'rt-id',
        category: 'Shoes',
        subcategory: 'Boots',
        color: 'brown',
        tags: ['winter', 'formal'],
        notes: 'Chelsea boots',
        wearCount: 7,
        isFavorite: true,
        userId: 'user_rt',
      );
      final copy = WardrobeItem.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.category, original.category);
      expect(copy.subcategory, original.subcategory);
      expect(copy.color, original.color);
      expect(copy.tags, original.tags);
      expect(copy.notes, original.notes);
      expect(copy.imageUrl, original.imageUrl);
      expect(copy.wearCount, original.wearCount);
      expect(copy.isFavorite, original.isFavorite);
      expect(copy.userId, original.userId);
    });
  });

  group('WardrobeItem.copyWith', () {
    test('overrides only specified fields', () {
      final original = _item(wearCount: 3, isFavorite: false);
      final updated = original.copyWith(wearCount: 4, isFavorite: true);
      expect(updated.wearCount, 4);
      expect(updated.isFavorite, isTrue);
      // Unchanged fields
      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.color, original.color);
      expect(updated.userId, original.userId);
    });

    test('preserves id when not specified', () {
      final original = _item(id: 'keep-id');
      final updated = original.copyWith(color: 'red');
      expect(updated.id, 'keep-id');
    });

    test('can update tags list', () {
      final original = _item(tags: ['casual']);
      final updated = original.copyWith(tags: ['casual', 'summer']);
      expect(updated.tags, ['casual', 'summer']);
      expect(original.tags, ['casual']); // original unchanged
    });

    test('can set lastWornAt', () {
      final worn = DateTime(2024, 6, 10);
      final original = _item(lastWornAt: null);
      final updated = original.copyWith(lastWornAt: worn);
      expect(updated.lastWornAt, worn);
    });

    test('preserves addedAt when not specified', () {
      final addedAt = DateTime(2024, 1, 15);
      final original = _item(addedAt: addedAt);
      final updated = original.copyWith(color: 'navy');
      expect(updated.addedAt, addedAt);
    });
  });

  group('WardrobeItem computed properties', () {
    test('displayName combines subcategory and category', () {
      final item = _item(category: 'Top', subcategory: 'Blazer');
      expect(item.displayName, 'Blazer (Top)');
    });

    test('wasWornRecently returns false when never worn', () {
      expect(_item(lastWornAt: null).wasWornRecently, isFalse);
    });

    test('wasWornRecently returns true when worn within 7 days', () {
      final item = _item(
        lastWornAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(item.wasWornRecently, isTrue);
    });

    test('wasWornRecently returns false when worn exactly 8 days ago', () {
      final item = _item(
        lastWornAt: DateTime.now().subtract(const Duration(days: 8)),
      );
      expect(item.wasWornRecently, isFalse);
    });

    test('daysSinceAdded is 0 for an item added right now', () {
      final item = _item();
      expect(item.daysSinceAdded, 0);
    });

    test('daysSinceAdded is correct for an item added in the past', () {
      final item = _item(
        addedAt: DateTime.now().subtract(const Duration(days: 5)),
      );
      expect(item.daysSinceAdded, 5);
    });
  });
}
