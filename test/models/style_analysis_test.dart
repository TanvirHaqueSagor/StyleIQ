import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

DimensionScore _dim({double score = 80.0, String comment = 'Good'}) =>
    DimensionScore(score: score, comment: comment);

DimensionScores _dims({
  double colorHarmony = 80.0,
  double fitProportion = 75.0,
  double occasionMatch = 85.0,
  double trendAlignment = 70.0,
  double styleCohesion = 78.0,
}) =>
    DimensionScores(
      colorHarmony: _dim(score: colorHarmony),
      fitProportion: _dim(score: fitProportion),
      occasionMatch: _dim(score: occasionMatch),
      trendAlignment: _dim(score: trendAlignment),
      styleCohesion: _dim(score: styleCohesion),
    );

Suggestion _suggestion({
  String change = 'Swap sneakers for loafers',
  String reason = 'Elevates formality',
  String scoreImpact = '+5 pts',
  String? budgetOption = 'ASOS ~\$40',
}) =>
    Suggestion(
      change: change,
      reason: reason,
      scoreImpact: scoreImpact,
      budgetOption: budgetOption,
    );

StyleAnalysis _analysis({double score = 78.0}) => StyleAnalysis(
      headline: 'Smart Casual Done Right',
      overallScore: score,
      letterGrade: 'B+',
      dimensions: _dims(),
      strengths: ['Great color blocking', 'Well-fitted top'],
      suggestions: [_suggestion()],
      styleInsight: 'You have a strong grasp of smart casual.',
      detectedItems: ['navy blazer', 'white tee', 'chinos'],
      analyzedAt: DateTime(2024, 6, 1, 12),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DimensionScore', () {
    test('fromJson parses score and comment', () {
      final d = DimensionScore.fromJson({'score': 85.0, 'comment': 'Excellent'});
      expect(d.score, 85.0);
      expect(d.comment, 'Excellent');
    });

    test('fromJson uses zero and empty string for missing fields', () {
      final d = DimensionScore.fromJson({});
      expect(d.score, 0.0);
      expect(d.comment, '');
    });

    test('fromJson coerces integer score to double', () {
      final d = DimensionScore.fromJson({'score': 90, 'comment': 'Great'});
      expect(d.score, isA<double>());
      expect(d.score, 90.0);
    });

    test('toJson / fromJson round-trip preserves values', () {
      final original = _dim(score: 72.5, comment: 'Good fit');
      final copy = DimensionScore.fromJson(original.toJson());
      expect(copy.score, original.score);
      expect(copy.comment, original.comment);
    });

    test('toJson keys are snake_case', () {
      final json = _dim().toJson();
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('comment'), isTrue);
    });
  });

  group('DimensionScores', () {
    test('fromJson parses all five dimensions', () {
      final json = {
        'color_harmony': {'score': 90.0, 'comment': 'A'},
        'fit_proportion': {'score': 85.0, 'comment': 'B'},
        'occasion_match': {'score': 80.0, 'comment': 'C'},
        'trend_alignment': {'score': 75.0, 'comment': 'D'},
        'style_cohesion': {'score': 70.0, 'comment': 'E'},
      };
      final d = DimensionScores.fromJson(json);
      expect(d.colorHarmony.score, 90.0);
      expect(d.fitProportion.score, 85.0);
      expect(d.occasionMatch.score, 80.0);
      expect(d.trendAlignment.score, 75.0);
      expect(d.styleCohesion.score, 70.0);
    });

    test('fromJson handles empty map with zero defaults', () {
      final d = DimensionScores.fromJson({});
      expect(d.colorHarmony.score, 0.0);
      expect(d.fitProportion.score, 0.0);
      expect(d.occasionMatch.score, 0.0);
      expect(d.trendAlignment.score, 0.0);
      expect(d.styleCohesion.score, 0.0);
    });

    test('toJson / fromJson round-trip preserves all scores', () {
      final original = _dims();
      final copy = DimensionScores.fromJson(original.toJson());
      expect(copy.colorHarmony.score, original.colorHarmony.score);
      expect(copy.fitProportion.score, original.fitProportion.score);
      expect(copy.occasionMatch.score, original.occasionMatch.score);
      expect(copy.trendAlignment.score, original.trendAlignment.score);
      expect(copy.styleCohesion.score, original.styleCohesion.score);
    });

    test('getAverageScore computes the arithmetic mean', () {
      final d = _dims(
        colorHarmony: 100.0,
        fitProportion: 80.0,
        occasionMatch: 60.0,
        trendAlignment: 40.0,
        styleCohesion: 20.0,
      );
      // (100 + 80 + 60 + 40 + 20) / 5 = 60
      expect(d.getAverageScore(), 60.0);
    });

    test('getAverageScore returns 0 when all dimensions are 0', () {
      final d = _dims(
        colorHarmony: 0.0,
        fitProportion: 0.0,
        occasionMatch: 0.0,
        trendAlignment: 0.0,
        styleCohesion: 0.0,
      );
      expect(d.getAverageScore(), 0.0);
    });

    test('asList returns exactly 5 entries', () {
      expect(_dims().asList().length, 5);
    });

    test('asList entries have human-readable keys', () {
      final keys = _dims().asList().map((e) => e.key).toList();
      expect(keys, containsAll([
        'Color Harmony',
        'Fit & Proportion',
        'Occasion Match',
        'Trend Alignment',
        'Style Cohesion',
      ]));
    });
  });

  group('Suggestion', () {
    test('fromJson parses required fields', () {
      final s = Suggestion.fromJson({
        'change': 'Add a belt',
        'reason': 'Defines the waist',
        'score_impact': '+3 pts',
      });
      expect(s.change, 'Add a belt');
      expect(s.reason, 'Defines the waist');
      expect(s.scoreImpact, '+3 pts');
      expect(s.budgetOption, isNull);
    });

    test('fromJson parses optional budgetOption', () {
      final s = Suggestion.fromJson({
        'change': 'Swap shoes',
        'reason': 'Formality',
        'score_impact': '+5 pts',
        'budget_option': 'Amazon \$25',
      });
      expect(s.budgetOption, 'Amazon \$25');
    });

    test('fromJson uses empty strings for missing required fields', () {
      final s = Suggestion.fromJson({});
      expect(s.change, '');
      expect(s.reason, '');
      expect(s.scoreImpact, '');
      expect(s.budgetOption, isNull);
    });

    test('toJson / fromJson round-trip with null budgetOption', () {
      final original = Suggestion(
        change: 'Try layering',
        reason: 'Adds depth',
        scoreImpact: '+4 pts',
      );
      final copy = Suggestion.fromJson(original.toJson());
      expect(copy.change, original.change);
      expect(copy.reason, original.reason);
      expect(copy.scoreImpact, original.scoreImpact);
      expect(copy.budgetOption, isNull);
    });

    test('toJson / fromJson round-trip with budgetOption present', () {
      final original = _suggestion();
      final copy = Suggestion.fromJson(original.toJson());
      expect(copy.budgetOption, original.budgetOption);
    });
  });

  group('StyleAnalysis', () {
    test('fromJson parses a complete JSON object', () {
      final json = {
        'headline': 'Effortlessly Chic',
        'overall_score': 88.0,
        'letter_grade': 'A',
        'dimensions': {
          'color_harmony': {'score': 90.0, 'comment': ''},
          'fit_proportion': {'score': 85.0, 'comment': ''},
          'occasion_match': {'score': 88.0, 'comment': ''},
          'trend_alignment': {'score': 86.0, 'comment': ''},
          'style_cohesion': {'score': 91.0, 'comment': ''},
        },
        'strengths': ['Great colors', 'Perfect fit'],
        'suggestions': [
          {
            'change': 'Add accessories',
            'reason': 'Completes the look',
            'score_impact': '+3 pts',
          }
        ],
        'style_insight': 'You nail minimalism.',
        'detected_items': ['white shirt', 'black jeans'],
        'cultural_context': 'Western casual',
        'body_type_detected': 'Athletic',
        'season_appropriateness': 'Spring',
        'aesthetic_category': 'Minimalist',
        'analyzed_at': '2024-06-01T12:00:00.000',
        'image_url': 'data:image/jpeg;base64,abc',
      };
      final a = StyleAnalysis.fromJson(json);
      expect(a.headline, 'Effortlessly Chic');
      expect(a.overallScore, 88.0);
      expect(a.letterGrade, 'A');
      expect(a.strengths, ['Great colors', 'Perfect fit']);
      expect(a.suggestions.length, 1);
      expect(a.detectedItems.length, 2);
      expect(a.culturalContext, 'Western casual');
      expect(a.bodyTypeDetected, 'Athletic');
      expect(a.seasonAppropriateness, 'Spring');
      expect(a.aestheticCategory, 'Minimalist');
      expect(a.imageUrl, 'data:image/jpeg;base64,abc');
    });

    test('fromJson defaults to "F" for missing letterGrade', () {
      final a = StyleAnalysis.fromJson({});
      expect(a.letterGrade, 'F');
    });

    test('fromJson defaults on all missing fields', () {
      final a = StyleAnalysis.fromJson({});
      expect(a.headline, '');
      expect(a.overallScore, 0.0);
      expect(a.letterGrade, 'F');
      expect(a.strengths, isEmpty);
      expect(a.suggestions, isEmpty);
      expect(a.detectedItems, isEmpty);
      expect(a.styleInsight, '');
      expect(a.culturalContext, isNull);
      expect(a.bodyTypeDetected, isNull);
      expect(a.seasonAppropriateness, isNull);
      expect(a.aestheticCategory, isNull);
      expect(a.imageUrl, isNull);
    });

    test('toJson / fromJson round-trip preserves headline and score', () {
      final original = _analysis(score: 91.5);
      final copy = StyleAnalysis.fromJson(original.toJson());
      expect(copy.headline, original.headline);
      expect(copy.overallScore, original.overallScore);
      expect(copy.letterGrade, original.letterGrade);
    });

    test('toJson includes analyzed_at as ISO-8601 string', () {
      final a = _analysis();
      final json = a.toJson();
      expect(json['analyzed_at'], isA<String>());
      // Should parse back to the same instant
      final parsed = DateTime.parse(json['analyzed_at'] as String);
      expect(parsed.year, a.analyzedAt.year);
      expect(parsed.month, a.analyzedAt.month);
      expect(parsed.day, a.analyzedAt.day);
    });

    test('toJson / fromJson round-trip preserves suggestions', () {
      final original = _analysis();
      final copy = StyleAnalysis.fromJson(original.toJson());
      expect(copy.suggestions.length, original.suggestions.length);
      expect(copy.suggestions.first.change, original.suggestions.first.change);
      expect(copy.suggestions.first.budgetOption, original.suggestions.first.budgetOption);
    });

    test('toJson / fromJson round-trip preserves strengths list', () {
      final original = _analysis();
      final copy = StyleAnalysis.fromJson(original.toJson());
      expect(copy.strengths, original.strengths);
    });

    test('copyWith overrides only specified fields', () {
      final original = _analysis(score: 78.0);
      final updated = original.copyWith(
        overallScore: 90.0,
        imageUrl: 'data:image/png;base64,xyz',
      );
      expect(updated.overallScore, 90.0);
      expect(updated.imageUrl, 'data:image/png;base64,xyz');
      // Unchanged fields
      expect(updated.headline, original.headline);
      expect(updated.letterGrade, original.letterGrade);
      expect(updated.strengths, original.strengths);
      expect(updated.styleInsight, original.styleInsight);
    });

    test('copyWith preserves analyzedAt when not specified', () {
      final original = _analysis();
      final updated = original.copyWith(letterGrade: 'A');
      expect(updated.analyzedAt, original.analyzedAt);
    });

    test('copyWith can update nullable optional fields', () {
      final original = _analysis();
      final updated = original.copyWith(
        culturalContext: 'South Asian',
        bodyTypeDetected: 'Hourglass',
      );
      expect(updated.culturalContext, 'South Asian');
      expect(updated.bodyTypeDetected, 'Hourglass');
      expect(updated.headline, original.headline); // unchanged
    });

    test('analyzedAt defaults to approximately now when not provided', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final a = StyleAnalysis(
        headline: 'Test',
        overallScore: 70.0,
        letterGrade: 'C+',
        dimensions: _dims(),
        strengths: [],
        suggestions: [],
        styleInsight: '',
        detectedItems: [],
      );
      expect(a.analyzedAt.isAfter(before), isTrue);
    });
  });
}
