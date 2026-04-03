
/// Model for a single dimension score (e.g., Color Harmony, Fit, etc.)
class DimensionScore {
  final double score;
  final String comment;

  DimensionScore({
    required this.score,
    required this.comment,
  });

  factory DimensionScore.fromJson(Map<String, dynamic> json) {
    return DimensionScore(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'comment': comment,
    };
  }
}

/// Container for all five dimension scores
class DimensionScores {
  final DimensionScore colorHarmony;
  final DimensionScore fitProportion;
  final DimensionScore occasionMatch;
  final DimensionScore trendAlignment;
  final DimensionScore styleCohesion;

  DimensionScores({
    required this.colorHarmony,
    required this.fitProportion,
    required this.occasionMatch,
    required this.trendAlignment,
    required this.styleCohesion,
  });

  factory DimensionScores.fromJson(Map<String, dynamic> json) {
    return DimensionScores(
      colorHarmony: DimensionScore.fromJson(
        json['color_harmony'] as Map<String, dynamic>? ?? {},
      ),
      fitProportion: DimensionScore.fromJson(
        json['fit_proportion'] as Map<String, dynamic>? ?? {},
      ),
      occasionMatch: DimensionScore.fromJson(
        json['occasion_match'] as Map<String, dynamic>? ?? {},
      ),
      trendAlignment: DimensionScore.fromJson(
        json['trend_alignment'] as Map<String, dynamic>? ?? {},
      ),
      styleCohesion: DimensionScore.fromJson(
        json['style_cohesion'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color_harmony': colorHarmony.toJson(),
      'fit_proportion': fitProportion.toJson(),
      'occasion_match': occasionMatch.toJson(),
      'trend_alignment': trendAlignment.toJson(),
      'style_cohesion': styleCohesion.toJson(),
    };
  }

  /// Get dimensions as a list of entries for easy UI iteration
  List<MapEntry<String, DimensionScore>> asList() {
    return [
      MapEntry('Color Harmony', colorHarmony),
      MapEntry('Fit & Proportion', fitProportion),
      MapEntry('Occasion Match', occasionMatch),
      MapEntry('Trend Alignment', trendAlignment),
      MapEntry('Style Cohesion', styleCohesion),
    ];
  }

  /// Get average of all dimension scores
  double getAverageScore() {
    final scores = [
      colorHarmony.score,
      fitProportion.score,
      occasionMatch.score,
      trendAlignment.score,
      styleCohesion.score,
    ];
    return scores.fold(0.0, (a, b) => a + b) / scores.length;
  }
}

/// Model for a suggestion to improve the outfit
class Suggestion {
  final String change;
  final String reason;
  final String scoreImpact;
  final String? budgetOption;

  Suggestion({
    required this.change,
    required this.reason,
    required this.scoreImpact,
    this.budgetOption,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      change: json['change'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      scoreImpact: json['score_impact'] as String? ?? '',
      budgetOption: json['budget_option'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'change': change,
      'reason': reason,
      'score_impact': scoreImpact,
      'budget_option': budgetOption,
    };
  }
}

/// Complete style analysis for an outfit
class StyleAnalysis {
  final String headline;
  final double overallScore;
  final String letterGrade;
  final DimensionScores dimensions;
  final List<String> strengths;
  final List<Suggestion> suggestions;
  final String styleInsight;
  final List<String> detectedItems;
  final String? culturalContext;
  final String? bodyTypeDetected;
  final String? seasonAppropriateness;
  final String? aestheticCategory;
  final DateTime analyzedAt;
  final String? imageUrl;

  StyleAnalysis({
    required this.headline,
    required this.overallScore,
    required this.letterGrade,
    required this.dimensions,
    required this.strengths,
    required this.suggestions,
    required this.styleInsight,
    required this.detectedItems,
    this.culturalContext,
    this.bodyTypeDetected,
    this.seasonAppropriateness,
    this.aestheticCategory,
    DateTime? analyzedAt,
    this.imageUrl,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory StyleAnalysis.fromJson(Map<String, dynamic> json) {
    return StyleAnalysis(
      headline: json['headline'] as String? ?? '',
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0,
      letterGrade: json['letter_grade'] as String? ?? 'F',
      dimensions: DimensionScores.fromJson(
        json['dimensions'] as Map<String, dynamic>? ?? {},
      ),
      strengths: List<String>.from(json['strengths'] as List? ?? []),
      suggestions: (json['suggestions'] as List?)
              ?.map((s) => Suggestion.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      styleInsight: json['style_insight'] as String? ?? '',
      detectedItems: List<String>.from(json['detected_items'] as List? ?? []),
      culturalContext: json['cultural_context'] as String?,
      bodyTypeDetected: json['body_type_detected'] as String?,
      seasonAppropriateness: json['season_appropriateness'] as String?,
      aestheticCategory: json['aesthetic_category'] as String?,
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'overall_score': overallScore,
      'letter_grade': letterGrade,
      'dimensions': dimensions.toJson(),
      'strengths': strengths,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'style_insight': styleInsight,
      'detected_items': detectedItems,
      'cultural_context': culturalContext,
      'body_type_detected': bodyTypeDetected,
      'season_appropriateness': seasonAppropriateness,
      'aesthetic_category': aestheticCategory,
      'analyzed_at': analyzedAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }

  /// Copy with method for immutability
  StyleAnalysis copyWith({
    String? headline,
    double? overallScore,
    String? letterGrade,
    DimensionScores? dimensions,
    List<String>? strengths,
    List<Suggestion>? suggestions,
    String? styleInsight,
    List<String>? detectedItems,
    String? culturalContext,
    String? bodyTypeDetected,
    String? seasonAppropriateness,
    String? aestheticCategory,
    DateTime? analyzedAt,
    String? imageUrl,
  }) {
    return StyleAnalysis(
      headline: headline ?? this.headline,
      overallScore: overallScore ?? this.overallScore,
      letterGrade: letterGrade ?? this.letterGrade,
      dimensions: dimensions ?? this.dimensions,
      strengths: strengths ?? this.strengths,
      suggestions: suggestions ?? this.suggestions,
      styleInsight: styleInsight ?? this.styleInsight,
      detectedItems: detectedItems ?? this.detectedItems,
      culturalContext: culturalContext ?? this.culturalContext,
      bodyTypeDetected: bodyTypeDetected ?? this.bodyTypeDetected,
      seasonAppropriateness:
          seasonAppropriateness ?? this.seasonAppropriateness,
      aestheticCategory: aestheticCategory ?? this.aestheticCategory,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
