import 'package:uuid/uuid.dart';

/// User profile data model
class UserProfile {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Onboarding quiz answers
  final String? dressCode;
  final String? colorPalette;
  final String? styleGoals;
  final String? culturalBackground;
  final String? fashionAdventure;
  final String? shoppingBudget;
  final String? styleChallenge;
  final String? tipsFrequency;

  // App settings
  final bool completedOnboarding;
  final int analysesCount;
  final int wardrobeItemsCount;
  final String? subscriptionTier;
  final DateTime? subscriptionExpiresAt;

  UserProfile({
    String? id,
    this.email,
    this.displayName,
    this.photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.dressCode,
    this.colorPalette,
    this.styleGoals,
    this.culturalBackground,
    this.fashionAdventure,
    this.shoppingBudget,
    this.styleChallenge,
    this.tipsFrequency,
    this.completedOnboarding = false,
    this.analysesCount = 0,
    this.wardrobeItemsCount = 0,
    this.subscriptionTier,
    this.subscriptionExpiresAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Check if user is in free tier
  bool get isFreeTier => subscriptionTier == null || subscriptionTier == 'Free';

  /// Check if subscription is active
  bool get hasActiveSubscription =>
      subscriptionTier != null &&
      subscriptionExpiresAt != null &&
      subscriptionExpiresAt!.isAfter(DateTime.now());

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      dressCode: json['dress_code'] as String?,
      colorPalette: json['color_palette'] as String?,
      styleGoals: json['style_goals'] as String?,
      culturalBackground: json['cultural_background'] as String?,
      fashionAdventure: json['fashion_adventure'] as String?,
      shoppingBudget: json['shopping_budget'] as String?,
      styleChallenge: json['style_challenge'] as String?,
      tipsFrequency: json['tips_frequency'] as String?,
      completedOnboarding: json['completed_onboarding'] as bool? ?? false,
      analysesCount: json['analyses_count'] as int? ?? 0,
      wardrobeItemsCount: json['wardrobe_items_count'] as int? ?? 0,
      subscriptionTier: json['subscription_tier'] as String?,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'dress_code': dressCode,
      'color_palette': colorPalette,
      'style_goals': styleGoals,
      'cultural_background': culturalBackground,
      'fashion_adventure': fashionAdventure,
      'shopping_budget': shoppingBudget,
      'style_challenge': styleChallenge,
      'tips_frequency': tipsFrequency,
      'completed_onboarding': completedOnboarding,
      'analyses_count': analysesCount,
      'wardrobe_items_count': wardrobeItemsCount,
      'subscription_tier': subscriptionTier,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? dressCode,
    String? colorPalette,
    String? styleGoals,
    String? culturalBackground,
    String? fashionAdventure,
    String? shoppingBudget,
    String? styleChallenge,
    String? tipsFrequency,
    bool? completedOnboarding,
    int? analysesCount,
    int? wardrobeItemsCount,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dressCode: dressCode ?? this.dressCode,
      colorPalette: colorPalette ?? this.colorPalette,
      styleGoals: styleGoals ?? this.styleGoals,
      culturalBackground: culturalBackground ?? this.culturalBackground,
      fashionAdventure: fashionAdventure ?? this.fashionAdventure,
      shoppingBudget: shoppingBudget ?? this.shoppingBudget,
      styleChallenge: styleChallenge ?? this.styleChallenge,
      tipsFrequency: tipsFrequency ?? this.tipsFrequency,
      completedOnboarding: completedOnboarding ?? this.completedOnboarding,
      analysesCount: analysesCount ?? this.analysesCount,
      wardrobeItemsCount: wardrobeItemsCount ?? this.wardrobeItemsCount,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
    );
  }
}
