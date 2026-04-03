import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/live_camera/models/live_score.dart';
import 'package:styleiq/features/live_camera/services/session_manager.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

LiveScore _score({double overallScore = 75, String letterGrade = 'B'}) =>
    LiveScore(
      overallScore: overallScore,
      letterGrade: letterGrade,
      dimensions: LiveDimensions.empty,
      detectedItems: const [],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SessionManager initial state', () {
    test('apiCallCount starts at 0', () {
      expect(SessionManager().apiCallCount, 0);
    });

    test('snapshots starts empty', () {
      expect(SessionManager().snapshots, isEmpty);
    });

    test('peakScore is 0 when no calls made', () {
      expect(SessionManager().peakScore, 0.0);
    });

    test('finalScore is 0 when no calls made', () {
      expect(SessionManager().finalScore, 0.0);
    });

    test('isLimitReached is false at start', () {
      expect(SessionManager().isLimitReached, isFalse);
    });
  });

  group('SessionManager tier limits', () {
    test('free tier: callLimit is 4', () {
      expect(SessionManager(tier: 'free').callLimit, 4);
    });

    test('style+ tier: callLimit is 15', () {
      expect(SessionManager(tier: 'style+').callLimit, 15);
    });

    test('pro tier: callLimit is 40', () {
      expect(SessionManager(tier: 'pro').callLimit, 40);
    });

    test('family tier: callLimit is 40', () {
      expect(SessionManager(tier: 'family').callLimit, 40);
    });

    test('unknown tier falls back to free limit', () {
      expect(SessionManager(tier: 'unknown').callLimit, TierLimits.free);
    });

    test('remainingCalls equals callLimit before any calls', () {
      final mgr = SessionManager(tier: 'free');
      expect(mgr.remainingCalls, mgr.callLimit);
    });
  });

  group('SessionManager.recordCall', () {
    test('increments apiCallCount', () {
      final mgr = SessionManager();
      mgr.recordCall(_score());
      expect(mgr.apiCallCount, 1);
      mgr.recordCall(_score());
      expect(mgr.apiCallCount, 2);
    });

    test('decrements remainingCalls', () {
      final mgr = SessionManager(tier: 'free');
      final initial = mgr.remainingCalls;
      mgr.recordCall(_score());
      expect(mgr.remainingCalls, initial - 1);
    });

    test('adds snapshot for each call', () {
      final mgr = SessionManager();
      mgr.recordCall(_score(overallScore: 80));
      mgr.recordCall(_score(overallScore: 85));
      expect(mgr.snapshots.length, 2);
    });

    test('snapshot stores correct score and grade', () {
      final mgr = SessionManager();
      mgr.recordCall(_score(overallScore: 88, letterGrade: 'B+'));
      expect(mgr.snapshots.first.score, 88.0);
      expect(mgr.snapshots.first.grade, 'B+');
    });

    test('snapshot has recent timestamp', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final mgr = SessionManager();
      mgr.recordCall(_score());
      expect(mgr.snapshots.first.timestamp.isAfter(before), isTrue);
    });

    test('isLimitReached becomes true when free tier exhausted', () {
      final mgr = SessionManager(tier: 'free');
      for (int i = 0; i < TierLimits.free; i++) {
        mgr.recordCall(_score());
      }
      expect(mgr.isLimitReached, isTrue);
    });

    test('remainingCalls never goes below 0', () {
      final mgr = SessionManager(tier: 'free');
      for (int i = 0; i <= TierLimits.free + 2; i++) {
        mgr.recordCall(_score());
      }
      expect(mgr.remainingCalls, 0);
    });
  });

  group('SessionManager.peakScore', () {
    test('returns highest score across all snapshots', () {
      final mgr = SessionManager();
      mgr.recordCall(_score(overallScore: 70));
      mgr.recordCall(_score(overallScore: 92));
      mgr.recordCall(_score(overallScore: 85));
      expect(mgr.peakScore, 92.0);
    });

    test('returns single score when only one call made', () {
      final mgr = SessionManager();
      mgr.recordCall(_score(overallScore: 78));
      expect(mgr.peakScore, 78.0);
    });
  });

  group('SessionManager.finalScore', () {
    test('returns last recorded score', () {
      final mgr = SessionManager();
      mgr.recordCall(_score(overallScore: 70));
      mgr.recordCall(_score(overallScore: 88));
      mgr.recordCall(_score(overallScore: 65));
      expect(mgr.finalScore, 65.0);
    });

    test('returns 0 when no calls made', () {
      expect(SessionManager().finalScore, 0.0);
    });
  });

  group('SessionManager score cache', () {
    test('getCachedScore returns null for unknown key', () {
      final mgr = SessionManager();
      final result =
          mgr.getCachedScore('unknown_hash', LiveOccasion.casual);
      expect(result, isNull);
    });

    test('getCachedScore returns stored score', () {
      final mgr = SessionManager();
      final score = _score(overallScore: 82);
      mgr.cacheScore('frame_hash_1', LiveOccasion.work, score);
      final retrieved = mgr.getCachedScore('frame_hash_1', LiveOccasion.work);
      expect(retrieved, isNotNull);
      expect(retrieved!.overallScore, 82.0);
    });

    test('cache is occasion-specific: different occasion returns null', () {
      final mgr = SessionManager();
      mgr.cacheScore('hash_1', LiveOccasion.casual, _score());
      final result = mgr.getCachedScore('hash_1', LiveOccasion.work);
      expect(result, isNull);
    });

    test('cache is hash-specific: different hash returns null', () {
      final mgr = SessionManager();
      mgr.cacheScore('hash_A', LiveOccasion.casual, _score());
      final result = mgr.getCachedScore('hash_B', LiveOccasion.casual);
      expect(result, isNull);
    });

    test('overwriting a cache entry stores the new score', () {
      final mgr = SessionManager();
      mgr.cacheScore('hash_1', LiveOccasion.party, _score(overallScore: 70));
      mgr.cacheScore('hash_1', LiveOccasion.party, _score(overallScore: 90));
      final result = mgr.getCachedScore('hash_1', LiveOccasion.party);
      expect(result!.overallScore, 90.0);
    });

    test('snapshots list is unmodifiable', () {
      final mgr = SessionManager();
      mgr.recordCall(_score());
      expect(
        () => mgr.snapshots.add(
          ScoreSnapshot(timestamp: DateTime.now(), score: 1, grade: 'F'),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('SessionManager.elapsed', () {
    test('elapsed is a non-negative duration', () {
      final mgr = SessionManager();
      expect(mgr.elapsed.inMilliseconds, greaterThanOrEqualTo(0));
    });
  });
}
