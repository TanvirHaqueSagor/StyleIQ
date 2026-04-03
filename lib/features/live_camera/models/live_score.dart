import 'dart:typed_data';

/// Lightweight speed-mode response returned by the live scoring API.
class LiveDimensions {
  final double colorHarmony;
  final double fitProportion;
  final double occasionMatch;
  final double trendAlignment;
  final double styleCohesion;

  final String colorHarmonyComment;
  final String fitProportionComment;
  final String occasionMatchComment;
  final String trendAlignmentComment;
  final String styleCohesionComment;

  const LiveDimensions({
    required this.colorHarmony,
    required this.fitProportion,
    required this.occasionMatch,
    required this.trendAlignment,
    required this.styleCohesion,
    required this.colorHarmonyComment,
    required this.fitProportionComment,
    required this.occasionMatchComment,
    required this.trendAlignmentComment,
    required this.styleCohesionComment,
  });

  /// Values in display order: Color, Fit, Occasion, Trend, Cohesion.
  List<double> get asList => [
        colorHarmony,
        fitProportion,
        occasionMatch,
        trendAlignment,
        styleCohesion,
      ];

  factory LiveDimensions.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> d(String key) =>
        json[key] as Map<String, dynamic>? ?? {};
    double s(Map<String, dynamic> m) =>
        (m['score'] as num?)?.toDouble() ?? 0;
    String c(Map<String, dynamic> m) => m['comment'] as String? ?? '';

    final ch = d('color_harmony');
    final fp = d('fit_proportion');
    final om = d('occasion_match');
    final ta = d('trend_alignment');
    final sc = d('style_cohesion');
    return LiveDimensions(
      colorHarmony: s(ch),
      fitProportion: s(fp),
      occasionMatch: s(om),
      trendAlignment: s(ta),
      styleCohesion: s(sc),
      colorHarmonyComment: c(ch),
      fitProportionComment: c(fp),
      occasionMatchComment: c(om),
      trendAlignmentComment: c(ta),
      styleCohesionComment: c(sc),
    );
  }

  static LiveDimensions get empty => const LiveDimensions(
        colorHarmony: 0,
        fitProportion: 0,
        occasionMatch: 0,
        trendAlignment: 0,
        styleCohesion: 0,
        colorHarmonyComment: '',
        fitProportionComment: '',
        occasionMatchComment: '',
        trendAlignmentComment: '',
        styleCohesionComment: '',
      );
}

class LiveScore {
  final double overallScore;
  final String letterGrade;
  final LiveDimensions dimensions;
  final List<String> detectedItems;
  final String? deltaNote;
  final DateTime scoredAt;

  LiveScore({
    required this.overallScore,
    required this.letterGrade,
    required this.dimensions,
    required this.detectedItems,
    this.deltaNote,
    DateTime? scoredAt,
  }) : scoredAt = scoredAt ?? DateTime.now();

  factory LiveScore.fromJson(Map<String, dynamic> json) {
    return LiveScore(
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      letterGrade: json['letter_grade'] as String? ?? '?',
      dimensions: LiveDimensions.fromJson(
        json['dimensions'] as Map<String, dynamic>? ?? {},
      ),
      detectedItems:
          List<String>.from(json['detected_items'] as List? ?? []),
      deltaNote: json['delta_note'] as String?,
    );
  }

  static LiveScore get empty => LiveScore(
        overallScore: 0,
        letterGrade: '?',
        dimensions: LiveDimensions.empty,
        detectedItems: [],
      );
}

/// State machine for the live camera session.
enum LiveState {
  initializing,
  firstScan,
  scored,
  monitoring,
  analyzing,
  error,
  rateLimited,
}

/// Available occasions for context-aware scoring.
enum LiveOccasion {
  autoDetect('Auto-detect', '🔍'),
  casual('Casual', '☀️'),
  work('Work / Office', '💼'),
  dateNight('Date Night', '🌙'),
  party('Party', '🎉'),
  wedding('Wedding', '💍'),
  interview('Interview', '📋'),
  religious('Religious', '🕌'),
  funeral('Funeral', '🖤');

  const LiveOccasion(this.label, this.emoji);
  final String label;
  final String emoji;

  String get promptText => this == autoDetect ? 'auto-detect' : label;
}

/// Tier limits for live session API calls.
class TierLimits {
  static const Map<String, int> callsPerSession = {
    'free': 4,
    'style+': 15,
    'pro': 40,
    'family': 40,
  };

  static int get free => callsPerSession['free']!;
  static int get stylePlus => callsPerSession['style+']!;
  static int get pro => callsPerSession['pro']!;
}

/// Snapshot of a score at a point in time during a session.
class ScoreSnapshot {
  final DateTime timestamp;
  final double score;
  final String grade;

  const ScoreSnapshot({
    required this.timestamp,
    required this.score,
    required this.grade,
  });
}

/// Frame data used for change detection.
class FrameData {
  final Uint8List pixels; // grayscale, downsampled
  final int width;
  final int height;
  final DateTime capturedAt;

  const FrameData({
    required this.pixels,
    required this.width,
    required this.height,
    required this.capturedAt,
  });
}
