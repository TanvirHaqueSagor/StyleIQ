import 'package:uuid/uuid.dart';

/// Model for a single wardrobe item
class WardrobeItem {
  final String id;
  final String category; // e.g., "Top", "Bottom", "Dress", "Shoes", "Accessory"
  final String subcategory; // e.g., "T-Shirt", "Jeans", "Heels"
  final String color;
  final List<String> tags; // e.g., ["casual", "work", "summer"]
  final String? notes;
  final String imageUrl;
  final DateTime addedAt;
  final DateTime? lastWornAt;
  final int wearCount;
  final bool isFavorite;
  final String userId;

  WardrobeItem({
    String? id,
    required this.category,
    required this.subcategory,
    required this.color,
    this.tags = const [],
    this.notes,
    required this.imageUrl,
    DateTime? addedAt,
    this.lastWornAt,
    this.wearCount = 0,
    this.isFavorite = false,
    required this.userId,
  })  : id = id ?? const Uuid().v4(),
        addedAt = addedAt ?? DateTime.now();

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] as String?,
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      color: json['color'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      notes: json['notes'] as String?,
      imageUrl: json['image_url'] as String? ?? '',
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : null,
      lastWornAt: json['last_worn_at'] != null
          ? DateTime.parse(json['last_worn_at'] as String)
          : null,
      wearCount: json['wear_count'] as int? ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
      userId: json['user_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'subcategory': subcategory,
      'color': color,
      'tags': tags,
      'notes': notes,
      'image_url': imageUrl,
      'added_at': addedAt.toIso8601String(),
      'last_worn_at': lastWornAt?.toIso8601String(),
      'wear_count': wearCount,
      'is_favorite': isFavorite,
      'user_id': userId,
    };
  }

  /// Copy with method for immutability
  WardrobeItem copyWith({
    String? id,
    String? category,
    String? subcategory,
    String? color,
    List<String>? tags,
    String? notes,
    String? imageUrl,
    DateTime? addedAt,
    DateTime? lastWornAt,
    int? wearCount,
    bool? isFavorite,
    String? userId,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
      lastWornAt: lastWornAt ?? this.lastWornAt,
      wearCount: wearCount ?? this.wearCount,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
    );
  }

  /// Check if item was worn recently (within 7 days)
  bool get wasWornRecently {
    if (lastWornAt == null) return false;
    return DateTime.now().difference(lastWornAt!).inDays <= 7;
  }

  /// Get days since added
  int get daysSinceAdded {
    return DateTime.now().difference(addedAt).inDays;
  }

  /// Get display name combining category and subcategory
  String get displayName => '$subcategory ($category)';
}
