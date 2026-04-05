import 'dart:convert';
import 'package:styleiq/models/engagement_state.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class EngagementService {
  final LocalStorageService _storage;

  EngagementService({LocalStorageService? storage})
      : _storage = storage ?? LocalStorageService();

  static const _engagementKeyPrefix = 'engagement_state_';

  int _deriveLevel(int points) {
    if (points >= 1200) return 7;
    if (points >= 800) return 6;
    if (points >= 500) return 5;
    if (points >= 300) return 4;
    if (points >= 180) return 3;
    if (points >= 80) return 2;
    return 1;
  }

  Future<EngagementState> getEngagementState(String userId) async {
    final saved = await _storage.getPreference('$_engagementKeyPrefix$userId');
    if (saved == null) {
      return EngagementState(userId: userId);
    }

    try {
      final map = jsonDecode(saved as String) as Map<String, dynamic>;
      return EngagementState.fromJson(map);
    } catch (_) {
      return EngagementState(userId: userId);
    }
  }

  Future<void> saveEngagementState(EngagementState state) async {
    await _storage.savePreference(
      '$_engagementKeyPrefix${state.userId}',
      jsonEncode(state.toJson()),
    );
  }

  Future<EngagementState> checkInToday(String userId) async {
    final current = await getEngagementState(userId);
    if (current.isCheckedInToday) {
      return current;
    }

    final newStreak =
        current.isCheckedInYesterday ? current.currentStreak + 1 : 1;
    final newPoints = current.totalPoints + 20;
    final newLevel = _deriveLevel(newPoints);

    final updated = current.copyWith(
      currentStreak: newStreak,
      totalPoints: newPoints,
      level: newLevel,
      lastCheckIn: DateTime.now(),
      badges: _computeBadges(current, newStreak, newPoints),
    );

    await saveEngagementState(updated);
    return updated;
  }

  List<String> _computeBadges(
      EngagementState previous, int streak, int points) {
    final badges = {...previous.badges};

    if (streak >= 3) badges.add('3-day streak');
    if (streak >= 7) badges.add('7-day streak');
    if (streak >= 14) badges.add('14-day fashion streak');
    if (points >= 500) badges.add('Style Guru');
    if (points >= 1000) badges.add('Style Master');

    return badges.toList();
  }

  Future<EngagementState> prepareDailyChallenge(String userId) async {
    return getEngagementState(userId);
  }
}
