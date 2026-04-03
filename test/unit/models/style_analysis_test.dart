import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';

// ── Fixtures ─────────────────────────────────────────────────────────────────

DimensionScore _dim({double score = 80, String comment = 'Good'}) =>
    DimensionScore(score: score, comment: comment);

DimensionScores _dims({
  double colorHarmony = 80,
  double fitProportion = 75,
  double occasionMatch = 85,
  double trendAlignment = 70,
  double styleCohesion = 78,
}) =>
    DimensionScores(
      colorHarmony: _dim(score: colorHarmony),
      fitProportion: _dim(score: fitProportion),
      occasionMatch: _dim(score: occasionMatch),
      trendAlignment: _dim(score: trendAlignment),
      styleCohesion: _dim(score: styleCohesion),
    );

StyleAnalysis _analysis({double score = 78}) => StyleAnalysis(
      headline: 'Smart Casual Done Right',
      overallScore: score,
      letterGrade: 'B+',
      dimensions: _dims(),
      strengths: ['Great color blocking', 'Well-fitted top'],
      suggestions: [
        Suggestion(
          change: 'Swap white sneakers for leather loafers',
          reason: 'Elevates the overall formality',
          scoreImpact: '+5 pts',
          budgetOption: 'ASOS leather loafers ~\$40',
        ),
      ],
      styleInsight: 'You have a strong grasp of smart casual.',
      detectedItems: ['navy blazer', 'white tee', 'chinos'],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('DimensionScore', () {
    test('fromJson parses correctly', () {
      final d = DimensionScore.fromJson({'score': 85.0, 'comment': 'Excellent'});
      expect(d.score, 85.0);
      expect(d.comment, 'Excellent');
    });

    test('fromJson uses defaults for missing fields', () {
      final d = DimensionScore.fromJson({});
      expect(d.score, 0.0);
      expect(d.comment, '');
    });

    test('fromJson coerces int score to double', () {
      final d = DimensionScore.fromJson({'score': 90, 'comment': 'Great'});
      expect(d.score, isA<double>());
      expect(d.score, 90.0);
    });

    test('toJson round-trips', () {
      final d = _dim(score: 72.5, comment: 'Good fit');
      final json = d.toJson();
      final d2 = DimensionScore.fromJson(json);
      expect(d2.score, d.score);
      expect(d2.comment, d.comment);
    });
  });

  group('DimensionScores', () {
    test('asList returns 5 entries', () {
      final list = _dims().asList();
      expect(list.length, 5);
    });

    test('asList keys are human-readable', () {
      final keys = _dims().asList().map((e) => e.key).toList();
      expect(keys, contains('Color Harmony'));
      expect(keys, contains('Fit & Proportion'));
      expect(keys, contains('Occasion Match'));
      expect(keys, contains('Trend Alignment'));
      expect(keys, contains('Style Cohesion'));
    });

    test('getAverageScore computes mean correctly', () {
      final d = _dims(
        colorHarmony: 100,
        fitProportion: 80,
        occasionMatch: 60,
        trendAlignment: 40,
        styleCohesion: 20,
      );
      expect(d.getAverageScore(), 60.0);
    });

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
    });

    test('toJson round-trips', () {
      final d = _dims();
      final d2 = DimensionScores.fromJson(d.toJson());
      expect(d2.colorHarmony.score, d.colorHarmony.score);
      expect(d2.styleCohesion.score, d.styleCohesion.score);
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

    test('toJson round-trips with null budget', () {
      final s = Suggestion(
        change: 'Try layering',
        reason: 'Adds depth',
        scoreImpact: '+4 pts',
      );
      final s2 = Suggestion.fromJson(s.toJson());
      expect(s2.change, s.change);
      expect(s2.budgetOption, isNull);
    });
  });

  group('StyleAnalysis', () {
    test('fromJson parses complete JSON', () {
      final json = {
        'headline': 'Effortlessly Chic',
        'overall_score': 88.0,
        'letter_grade': 'B+',
        'dimensions': {
          'color_harmony': {'score': 90.0, 'comment': ''},
          'fit_proportion': {'score': 85.0, 'comment': ''},
          'occasion_match': {'score': 88.0, 'comment': ''},
          'trend_alignment': {'score': 86.0, 'comment': ''},
          'style_cohesion': {'score': 91.0, 'comment': ''},
        },
        'strengths': ['Great colors'],
        'suggestions': [],
        'style_insight': 'You nail minimalism.',
        'detected_items': ['white shirt', 'black jeans'],
      };
      final a = StyleAnalysis.fromJson(json);
      expect(a.headline, 'Effortlessly Chic');
      expect(a.overallScore, 88.0);
      expect(a.letterGrade, 'B+');
      expect(a.strengths, ['Great colors']);
      expect(a.detectedItems.length, 2);
    });

    test('fromJson defaults on missing fields', () {
      final a = StyleAnalysis.fromJson({});
      expect(a.headline, '');
      expect(a.overallScore, 0.0);
      expect(a.letterGrade, 'F');
      expect(a.strengths, isEmpty);
      expect(a.suggestions, isEmpty);
      expect(a.imageUrl, isNull);
    });

    test('toJson includes all fields', () {
      final a = _analysis();
      final json = a.toJson();
      expect(json['headline'], a.headline);
      expect(json['overall_score'], a.overallScore);
      expect(json['letter_grade'], a.letterGrade);
      expect(json['strengths'], a.strengths);
      expect(json['analyzed_at'], isA<String>());
    });

    test('toJson round-trips headline and score', () {
      final a = _analysis(score: 91.5);
      final json = a.toJson();
      final a2 = StyleAnalysis.fromJson(json);
      expect(a2.headline, a.headline);
      expect(a2.overallScore, a.overallScore);
    });

    test('copyWith overrides only specified fields', () {
      final a = _analysis(score: 78);
      final b = a.copyWith(overallScore: 90, imageUrl: 'data:image/png;base64,abc');
      expect(b.overallScore, 90);
      expect(b.imageUrl, 'data:image/png;base64,abc');
      expect(b.headline, a.headline); // unchanged
      expect(b.strengths, a.strengths); // unchanged
    });

    test('analyzedAt defaults to now when not provided', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final a = _analysis();
      expect(a.analyzedAt.isAfter(before), isTrue);
    });

    test('suggestions list maps correctly', () {
      final a = _analysis();
      expect(a.suggestions.length, 1);
      expect(a.suggestions.first.change, contains('sneakers'));
      expect(a.suggestions.first.budgetOption, isNotNull);
    });
  });
}
