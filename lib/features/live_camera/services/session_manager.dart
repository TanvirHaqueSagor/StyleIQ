import '../models/live_score.dart';

/// Manages per-session state: API call count, tier limits, score cache,
/// and session snapshots.
class SessionManager {
  final String tier; // 'free' | 'style+' | 'pro' | 'family'

  SessionManager({this.tier = 'free'});

  // ── Session counters ─────────────────────────────────────────────────────────
  int _apiCallCount = 0;
  final DateTime _startedAt = DateTime.now();
  final List<ScoreSnapshot> _snapshots = [];

  // ── pHash score cache (key = hash + '_' + occasion label) ──────────────────
  final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 30);

  int get apiCallCount => _apiCallCount;
  int get callLimit => TierLimits.callsPerSession[tier] ?? TierLimits.free;
  int get remainingCalls => (callLimit - _apiCallCount).clamp(0, callLimit);
  bool get isLimitReached => _apiCallCount >= callLimit;
  Duration get elapsed => DateTime.now().difference(_startedAt);
  List<ScoreSnapshot> get snapshots => List.unmodifiable(_snapshots);

  /// Record an API call and store the resulting score snapshot.
  void recordCall(LiveScore score) {
    _apiCallCount++;
    _snapshots.add(ScoreSnapshot(
      timestamp: DateTime.now(),
      score: score.overallScore,
      grade: score.letterGrade,
    ));
  }

  /// Store a score in the cache.
  void cacheScore(String frameHash, LiveOccasion occasion, LiveScore score) {
    final key = '${frameHash}_${occasion.label}';
    _cache[key] = _CacheEntry(score: score, cachedAt: DateTime.now());
  }

  /// Retrieve a cached score, or null if missing / expired.
  LiveScore? getCachedScore(String frameHash, LiveOccasion occasion) {
    final key = '${frameHash}_${occasion.label}';
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.score;
  }

  /// Peak score across the session.
  double get peakScore {
    if (_snapshots.isEmpty) return 0;
    return _snapshots
        .map((s) => s.score)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Final score (last snapshot).
  double get finalScore =>
      _snapshots.isNotEmpty ? _snapshots.last.score : 0;
}

class _CacheEntry {
  final LiveScore score;
  final DateTime cachedAt;

  const _CacheEntry({required this.score, required this.cachedAt});
}
