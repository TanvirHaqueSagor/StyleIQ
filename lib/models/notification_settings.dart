/// User notification preferences and settings
class NotificationSettings {
  final String userId;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool dailyStyleTips;
  final bool weeklyDigest;
  final bool newFeatures;
  final bool culturalReminders;
  final DateTime updatedAt;

  NotificationSettings({
    required this.userId,
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.dailyStyleTips = false,
    this.weeklyDigest = true,
    this.newFeatures = false,
    this.culturalReminders = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      userId: json['user_id'] as String,
      pushNotifications: json['push_notifications'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      dailyStyleTips: json['daily_style_tips'] as bool? ?? false,
      weeklyDigest: json['weekly_digest'] as bool? ?? true,
      newFeatures: json['new_features'] as bool? ?? false,
      culturalReminders: json['cultural_reminders'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'push_notifications': pushNotifications,
      'email_notifications': emailNotifications,
      'daily_style_tips': dailyStyleTips,
      'weekly_digest': weeklyDigest,
      'new_features': newFeatures,
      'cultural_reminders': culturalReminders,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Copy with method for immutability
  NotificationSettings copyWith({
    String? userId,
    bool? pushNotifications,
    bool? emailNotifications,
    bool? dailyStyleTips,
    bool? weeklyDigest,
    bool? newFeatures,
    bool? culturalReminders,
    DateTime? updatedAt,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      dailyStyleTips: dailyStyleTips ?? this.dailyStyleTips,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      newFeatures: newFeatures ?? this.newFeatures,
      culturalReminders: culturalReminders ?? this.culturalReminders,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}