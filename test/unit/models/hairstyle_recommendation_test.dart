import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _hairstyleItemJson({
  String name = 'Bob Cut',
  String description = 'A chin-length classic',
  String whyItWorks = 'Frames oval faces perfectly',
  String maintenanceLevel = 'low',
  String length = 'short',
  String stylingTips = 'Air-dry for natural wave',
}) =>
    {
      'name': name,
      'description': description,
      'why_it_works': whyItWorks,
      'maintenance_level': maintenanceLevel,
      'length': length,
      'styling_tips': stylingTips,
    };

HairstyleItem _item({
  String name = 'Bob Cut',
  String maintenanceLevel = 'low',
  String length = 'short',
}) =>
    HairstyleItem(
      name: name,
      description: 'Classic cut',
      whyItWorks: 'Works for oval faces',
      maintenanceLevel: maintenanceLevel,
      length: length,
      stylingTips: 'Air-dry',
    );

HairstyleRecommendation _recommendation({
  String faceShape = 'oval',
  String hairTexture = '2B',
  List<HairstyleItem>? recommendations,
}) =>
    HairstyleRecommendation(
      faceShape: faceShape,
      hairTexture: hairTexture,
      recommendations: recommendations ?? [_item(), _item(name: 'Lob')],
      styleNotes: 'Your oval face suits most styles.',
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('HairstyleItem.fromJson', () {
    test('parses all fields', () {
      final item = HairstyleItem.fromJson(_hairstyleItemJson());
      expect(item.name, 'Bob Cut');
      expect(item.description, 'A chin-length classic');
      expect(item.whyItWorks, 'Frames oval faces perfectly');
      expect(item.maintenanceLevel, 'low');
      expect(item.length, 'short');
      expect(item.stylingTips, 'Air-dry for natural wave');
    });

    test('defaults when fields are missing', () {
      final item = HairstyleItem.fromJson({});
      expect(item.name, '');
      expect(item.description, '');
      expect(item.whyItWorks, '');
      expect(item.maintenanceLevel, 'medium');
      expect(item.length, 'medium');
      expect(item.stylingTips, '');
    });

    test('handles all maintenance levels', () {
      for (final level in ['low', 'medium', 'high']) {
        final item = HairstyleItem.fromJson(
            _hairstyleItemJson(maintenanceLevel: level));
        expect(item.maintenanceLevel, level);
      }
    });
  });

  group('HairstyleItem.toJson', () {
    test('serialises all fields', () {
      final item = _item(name: 'Pixie Cut', maintenanceLevel: 'high', length: 'short');
      final json = item.toJson();
      expect(json['name'], 'Pixie Cut');
      expect(json['maintenance_level'], 'high');
      expect(json['length'], 'short');
      expect(json['description'], isA<String>());
      expect(json['why_it_works'], isA<String>());
      expect(json['styling_tips'], isA<String>());
    });

    test('round-trips correctly', () {
      final original = HairstyleItem.fromJson(_hairstyleItemJson(
        name: 'Shag',
        description: 'Layered cut',
        maintenanceLevel: 'medium',
        length: 'long',
        stylingTips: 'Use curl cream',
      ));
      final copy = HairstyleItem.fromJson(original.toJson());
      expect(copy.name, original.name);
      expect(copy.description, original.description);
      expect(copy.maintenanceLevel, original.maintenanceLevel);
      expect(copy.length, original.length);
      expect(copy.stylingTips, original.stylingTips);
    });
  });

  group('HairstyleRecommendation.fromJson', () {
    test('parses face shape, texture, notes, and recommendations list', () {
      final json = {
        'face_shape': 'heart',
        'hair_texture': '3A',
        'style_notes': 'Soft layers suit heart faces.',
        'recommendations': [
          _hairstyleItemJson(name: 'Curtain Bangs'),
          _hairstyleItemJson(name: 'Long Layers'),
        ],
      };
      final rec = HairstyleRecommendation.fromJson(json);
      expect(rec.faceShape, 'heart');
      expect(rec.hairTexture, '3A');
      expect(rec.styleNotes, 'Soft layers suit heart faces.');
      expect(rec.recommendations.length, 2);
      expect(rec.recommendations[0].name, 'Curtain Bangs');
      expect(rec.recommendations[1].name, 'Long Layers');
    });

    test('defaults when all fields are missing', () {
      final rec = HairstyleRecommendation.fromJson({});
      expect(rec.faceShape, 'Unknown');
      expect(rec.hairTexture, 'Unknown');
      expect(rec.styleNotes, '');
      expect(rec.recommendations, isEmpty);
    });

    test('handles empty recommendations list', () {
      final rec = HairstyleRecommendation.fromJson({'recommendations': []});
      expect(rec.recommendations, isEmpty);
    });
  });

  group('HairstyleRecommendation.toJson', () {
    test('serialises all fields', () {
      final rec = _recommendation(faceShape: 'square', hairTexture: '1C');
      final json = rec.toJson();
      expect(json['face_shape'], 'square');
      expect(json['hair_texture'], '1C');
      expect(json['style_notes'], isA<String>());
      expect(json['recommendations'], isA<List>());
      expect((json['recommendations'] as List).length, 2);
    });

    test('round-trips correctly', () {
      final original = _recommendation(faceShape: 'round', hairTexture: '4B');
      final copy = HairstyleRecommendation.fromJson(original.toJson());
      expect(copy.faceShape, original.faceShape);
      expect(copy.hairTexture, original.hairTexture);
      expect(copy.styleNotes, original.styleNotes);
      expect(copy.recommendations.length, original.recommendations.length);
      expect(copy.recommendations[0].name, original.recommendations[0].name);
    });
  });

  group('HairstyleResult', () {
    test('fromJson parses all fields', () {
      final analyzedAt = DateTime(2024, 6, 1, 10, 30);
      final json = {
        'id': 'result-1',
        'recommendation': {
          'face_shape': 'diamond',
          'hair_texture': '2A',
          'recommendations': [],
          'style_notes': 'Note',
        },
        'image_url': 'data:image/jpeg;base64,abc',
        'analyzed_at': analyzedAt.toIso8601String(),
      };
      final result = HairstyleResult.fromJson(json);
      expect(result.id, 'result-1');
      expect(result.imageUrl, 'data:image/jpeg;base64,abc');
      expect(result.recommendation.faceShape, 'diamond');
      expect(result.analyzedAt.year, 2024);
      expect(result.analyzedAt.month, 6);
    });

    test('handles null image_url', () {
      final json = {
        'id': 'r-2',
        'recommendation': {
          'face_shape': 'oval',
          'hair_texture': '1A',
          'recommendations': [],
          'style_notes': '',
        },
        'image_url': null,
        'analyzed_at': DateTime.now().toIso8601String(),
      };
      final result = HairstyleResult.fromJson(json);
      expect(result.imageUrl, isNull);
    });

    test('toJson round-trips correctly', () {
      final original = HairstyleResult(
        id: 'rt-1',
        recommendation: _recommendation(),
        imageUrl: 'data:image/jpeg;base64,xyz',
        analyzedAt: DateTime(2024, 3, 15, 9, 0),
      );
      final copy = HairstyleResult.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.imageUrl, original.imageUrl);
      expect(copy.recommendation.faceShape, original.recommendation.faceShape);
      expect(copy.analyzedAt.year, original.analyzedAt.year);
      expect(copy.analyzedAt.month, original.analyzedAt.month);
    });

    test('toJson serialises null imageUrl as null', () {
      final result = HairstyleResult(
        id: 'r-3',
        recommendation: _recommendation(),
        imageUrl: null,
        analyzedAt: DateTime.now(),
      );
      expect(result.toJson()['image_url'], isNull);
    });
  });
}
