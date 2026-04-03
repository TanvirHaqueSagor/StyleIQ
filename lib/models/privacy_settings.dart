/// User privacy and data sharing preferences
class PrivacySettings {
  final String userId;
  final bool analyticsEnabled;
  final bool crashReporting;
  final bool personalizedAds;
  final bool dataSharing;
  final bool profileVisibility;
  final bool wardrobePublic;
  final DateTime updatedAt;

  PrivacySettings({
    required this.userId,
    this.analyticsEnabled = true,
    this.crashReporting = true,
    this.personalizedAds = false,
    this.dataSharing = false,
    this.profileVisibility = true,
    this.wardrobePublic = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      userId: json['user_id'] as String,
      analyticsEnabled: json['analytics_enabled'] as bool? ?? true,
      crashReporting: json['crash_reporting'] as bool? ?? true,
      personalizedAds: json['personalized_ads'] as bool? ?? false,
      dataSharing: json['data_sharing'] as bool? ?? false,
      profileVisibility: json['profile_visibility'] as bool? ?? true,
      wardrobePublic: json['wardrobe_public'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'analytics_enabled': analyticsEnabled,
      'crash_reporting': crashReporting,
      'personalized_ads': personalizedAds,
      'data_sharing': dataSharing,
      'profile_visibility': profileVisibility,
      'wardrobe_public': wardrobePublic,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  PrivacySettings copyWith({
    String? userId,
    bool? analyticsEnabled,
    bool? crashReporting,
    bool? personalizedAds,
    bool? dataSharing,
    bool? profileVisibility,
    bool? wardrobePublic,
    DateTime? updatedAt,
  }) {
    return PrivacySettings(
      userId: userId ?? this.userId,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReporting: crashReporting ?? this.crashReporting,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      dataSharing: dataSharing ?? this.dataSharing,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      wardrobePublic: wardrobePublic ?? this.wardrobePublic,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}