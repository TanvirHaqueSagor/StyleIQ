import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:styleiq/features/engagement/services/engagement_service.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('styleiq_test_');
    Hive.init(tempDir.path);

    await Hive.openBox<dynamic>(LocalStorageService.appPreferencesBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('EngagementService', () {
    const userId = 'test-user';
    late EngagementService service;

    setUp(() {
      service = EngagementService();
    });

    test('initial state is empty and default', () async {
      final state = await service.getEngagementState(userId);
      expect(state.userId, userId);
      expect(state.currentStreak, 0);
      expect(state.totalPoints, 0);
      expect(state.level, 1);
      expect(state.badges, isEmpty);
    });

    test('checkInToday increments streak and points', () async {
      final first = await service.checkInToday(userId);
      expect(first.currentStreak, 1);
      expect(first.totalPoints, 20);
      expect(first.level, 1);
      expect(first.isCheckedInToday, isTrue);

      // second call same day should not increase again
      final second = await service.checkInToday(userId);
      expect(second.currentStreak, 1);
      expect(second.totalPoints, 20);
      expect(second.level, 1);
      expect(second.isCheckedInToday, isTrue);
    });

    test('badge grants and level progression', () async {
      // mimic sequential days by updating lastCheckIn to yesterday using deep state
      var state = await service.getEngagementState(userId);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      state = state.copyWith(
          lastCheckIn: yesterday, currentStreak: 2, totalPoints: 70);
      await service.saveEngagementState(state);

      final updated = await service.checkInToday(userId);
      expect(updated.currentStreak, 3);
      expect(updated.totalPoints, 90);
      expect(updated.level, 2);
      expect(updated.badges, contains('3-day streak'));
    });
  });
}
