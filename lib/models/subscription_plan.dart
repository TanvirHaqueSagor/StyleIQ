/// Subscription plan details and features
class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String interval;
  final List<String> features;
  final int? maxAnalyses;
  final int? maxWardrobeItems;
  final bool hasAiEngine;
  final bool hasCulturalDb;
  final bool hasPrioritySupport;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.currency = 'USD',
    this.interval = 'month',
    this.features = const [],
    this.maxAnalyses,
    this.maxWardrobeItems,
    this.hasAiEngine = false,
    this.hasCulturalDb = false,
    this.hasPrioritySupport = false,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if this is a free plan
  bool get isFree => price == 0.0;

  /// Get formatted price string
  String get formattedPrice {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${price.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return '$currency ';
    }
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      interval: json['interval'] as String? ?? 'month',
      features: List<String>.from(json['features'] as List? ?? []),
      maxAnalyses: json['max_analyses'] as int?,
      maxWardrobeItems: json['max_wardrobe_items'] as int?,
      hasAiEngine: json['has_ai_engine'] as bool? ?? false,
      hasCulturalDb: json['has_cultural_db'] as bool? ?? false,
      hasPrioritySupport: json['has_priority_support'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'max_analyses': maxAnalyses,
      'max_wardrobe_items': maxWardrobeItems,
      'has_ai_engine': hasAiEngine,
      'has_cultural_db': hasCulturalDb,
      'has_priority_support': hasPrioritySupport,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  SubscriptionPlan copyWith({
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
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      interval: interval ?? this.interval,
      features: features ?? this.features,
      maxAnalyses: maxAnalyses ?? this.maxAnalyses,
      maxWardrobeItems: maxWardrobeItems ?? this.maxWardrobeItems,
      hasAiEngine: hasAiEngine ?? this.hasAiEngine,
      hasCulturalDb: hasCulturalDb ?? this.hasCulturalDb,
      hasPrioritySupport: hasPrioritySupport ?? this.hasPrioritySupport,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}