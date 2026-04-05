class EngagementState {
  final String userId;
  final int currentStreak;
  final int totalPoints;
  final int level;
  final DateTime? lastCheckIn;
  final List<String> badges;

  EngagementState({
    required this.userId,
    this.currentStreak = 0,
    this.totalPoints = 0,
    this.level = 1,
    this.lastCheckIn,
    this.badges = const [],
  });

  EngagementState copyWith({
    int? currentStreak,
    int? totalPoints,
    int? level,
    DateTime? lastCheckIn,
    List<String>? badges,
  }) {
    return EngagementState(
      userId: userId,
      currentStreak: currentStreak ?? this.currentStreak,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      badges: badges ?? this.badges,
    );
  }

  factory EngagementState.fromJson(Map<String, dynamic> json) {
    return EngagementState(
      userId: json['userId'] as String,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastCheckIn: json['lastCheckIn'] != null
          ? DateTime.parse(json['lastCheckIn'] as String)
          : null,
      badges: (json['badges'] as List<dynamic>?)?.cast<String>() ?? <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'totalPoints': totalPoints,
      'level': level,
      'lastCheckIn': lastCheckIn?.toIso8601String(),
      'badges': badges,
    };
  }

  bool get isCheckedInToday {
    if (lastCheckIn == null) return false;
    final now = DateTime.now();
    return lastCheckIn!.year == now.year &&
        lastCheckIn!.month == now.month &&
        lastCheckIn!.day == now.day;
  }

  bool get isCheckedInYesterday {
    if (lastCheckIn == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return lastCheckIn!.year == yesterday.year &&
        lastCheckIn!.month == yesterday.month &&
        lastCheckIn!.day == yesterday.day;
  }
}
