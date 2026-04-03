/// Model for a single hairstyle recommendation
class HairstyleItem {
  final String name;
  final String description;
  final String whyItWorks;
  final String maintenanceLevel; // low, medium, high
  final String length; // short, medium, long
  final String stylingTips;

  const HairstyleItem({
    required this.name,
    required this.description,
    required this.whyItWorks,
    required this.maintenanceLevel,
    required this.length,
    required this.stylingTips,
  });

  factory HairstyleItem.fromJson(Map<String, dynamic> json) {
    return HairstyleItem(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      whyItWorks: json['why_it_works'] as String? ?? '',
      maintenanceLevel: json['maintenance_level'] as String? ?? 'medium',
      length: json['length'] as String? ?? 'medium',
      stylingTips: json['styling_tips'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'why_it_works': whyItWorks,
        'maintenance_level': maintenanceLevel,
        'length': length,
        'styling_tips': stylingTips,
      };
}

/// Persisted hairstyle session — recommendation + image + timestamp
class HairstyleResult {
  final String id;
  final HairstyleRecommendation recommendation;
  final String? imageUrl; // data URL
  final DateTime analyzedAt;

  const HairstyleResult({
    required this.id,
    required this.recommendation,
    this.imageUrl,
    required this.analyzedAt,
  });

  factory HairstyleResult.fromJson(Map<String, dynamic> json) {
    return HairstyleResult(
      id: json['id'] as String? ?? '',
      recommendation: HairstyleRecommendation.fromJson(
          json['recommendation'] as Map<String, dynamic>? ?? {}),
      imageUrl: json['image_url'] as String?,
      analyzedAt: DateTime.parse(
          json['analyzed_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'recommendation': recommendation.toJson(),
        'image_url': imageUrl,
        'analyzed_at': analyzedAt.toIso8601String(),
      };
}

/// Top-level model for hairstyle recommendations from Claude
class HairstyleRecommendation {
  final String faceShape;
  final String hairTexture;
  final List<HairstyleItem> recommendations;
  final String styleNotes;

  const HairstyleRecommendation({
    required this.faceShape,
    required this.hairTexture,
    required this.recommendations,
    required this.styleNotes,
  });

  factory HairstyleRecommendation.fromJson(Map<String, dynamic> json) {
    final rawList = json['recommendations'] as List<dynamic>? ?? [];
    return HairstyleRecommendation(
      faceShape: json['face_shape'] as String? ?? 'Unknown',
      hairTexture: json['hair_texture'] as String? ?? 'Unknown',
      recommendations: rawList
          .map((e) => HairstyleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      styleNotes: json['style_notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'face_shape': faceShape,
        'hair_texture': hairTexture,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'style_notes': styleNotes,
      };
}
