import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/live_camera/models/live_score.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

Map<String, dynamic> _dimJson({
  double colorHarmony = 80,
  double fitProportion = 75,
  double occasionMatch = 85,
  double trendAlignment = 70,
  double styleCohesion = 78,
}) =>
    {
      'color_harmony': {'score': colorHarmony, 'comment': 'Ch'},
      'fit_proportion': {'score': fitProportion, 'comment': 'Fp'},
      'occasion_match': {'score': occasionMatch, 'comment': 'Om'},
      'trend_alignment': {'score': trendAlignment, 'comment': 'Ta'},
      'style_cohesion': {'score': styleCohesion, 'comment': 'Sc'},
    };

Map<String, dynamic> _scoreJson({
  double overallScore = 78,
  String letterGrade = 'B',
}) =>
    {
      'overall_score': overallScore,
      'letter_grade': letterGrade,
      'dimensions': _dimJson(),
      'detected_items': ['navy blazer', 'white tee'],
      'delta_note': 'Collar added +5',
    };

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── LiveDimensions ─────────────────────────────────────────────────────────

  group('LiveDimensions.fromJson', () {
    test('parses all five dimension scores', () {
      final d = LiveDimensions.fromJson(_dimJson(
        colorHarmony: 90,
        fitProportion: 85,
        occasionMatch: 80,
        trendAlignment: 75,
        styleCohesion: 70,
      ));
      expect(d.colorHarmony, 90.0);
      expect(d.fitProportion, 85.0);
      expect(d.occasionMatch, 80.0);
      expect(d.trendAlignment, 75.0);
      expect(d.styleCohesion, 70.0);
    });

    test('parses all five dimension comments', () {
      final json = {
        'color_harmony': {'score': 80.0, 'comment': 'Great palette'},
        'fit_proportion': {'score': 75.0, 'comment': 'Well-fitted'},
        'occasion_match': {'score': 85.0, 'comment': 'Perfect for work'},
        'trend_alignment': {'score': 70.0, 'comment': 'Slightly dated'},
        'style_cohesion': {'score': 78.0, 'comment': 'Cohesive look'},
      };
      final d = LiveDimensions.fromJson(json);
      expect(d.colorHarmonyComment, 'Great palette');
      expect(d.fitProportionComment, 'Well-fitted');
      expect(d.occasionMatchComment, 'Perfect for work');
      expect(d.trendAlignmentComment, 'Slightly dated');
      expect(d.styleCohesionComment, 'Cohesive look');
    });

    test('coerces int scores to double', () {
      final json = {
        'color_harmony': {'score': 90, 'comment': ''},
        'fit_proportion': {'score': 85, 'comment': ''},
        'occasion_match': {'score': 80, 'comment': ''},
        'trend_alignment': {'score': 75, 'comment': ''},
        'style_cohesion': {'score': 70, 'comment': ''},
      };
      final d = LiveDimensions.fromJson(json);
      expect(d.colorHarmony, isA<double>());
      expect(d.colorHarmony, 90.0);
    });

    test('defaults to zeros for missing fields', () {
      final d = LiveDimensions.fromJson({});
      expect(d.colorHarmony, 0.0);
      expect(d.fitProportion, 0.0);
      expect(d.colorHarmonyComment, '');
    });
  });

  group('LiveDimensions.empty', () {
    test('all scores are zero', () {
      final d = LiveDimensions.empty;
      expect(d.colorHarmony, 0.0);
      expect(d.fitProportion, 0.0);
      expect(d.occasionMatch, 0.0);
      expect(d.trendAlignment, 0.0);
      expect(d.styleCohesion, 0.0);
    });

    test('all comments are empty', () {
      final d = LiveDimensions.empty;
      expect(d.colorHarmonyComment, '');
      expect(d.fitProportionComment, '');
      expect(d.occasionMatchComment, '');
      expect(d.trendAlignmentComment, '');
      expect(d.styleCohesionComment, '');
    });
  });

  group('LiveDimensions.asList', () {
    test('returns exactly 5 values', () {
      final d = LiveDimensions.fromJson(_dimJson());
      expect(d.asList.length, 5);
    });

    test('values are in order: Color, Fit, Occasion, Trend, Cohesion', () {
      final d = LiveDimensions.fromJson(_dimJson(
        colorHarmony: 91,
        fitProportion: 82,
        occasionMatch: 73,
        trendAlignment: 64,
        styleCohesion: 55,
      ));
      expect(d.asList[0], 91.0);
      expect(d.asList[1], 82.0);
      expect(d.asList[2], 73.0);
      expect(d.asList[3], 64.0);
      expect(d.asList[4], 55.0);
    });
  });

  // ── LiveScore ──────────────────────────────────────────────────────────────

  group('LiveScore.fromJson', () {
    test('parses overallScore and letterGrade', () {
      final s = LiveScore.fromJson(_scoreJson(overallScore: 82.5, letterGrade: 'B+'));
      expect(s.overallScore, 82.5);
      expect(s.letterGrade, 'B+');
    });

    test('parses dimensions', () {
      final s = LiveScore.fromJson(_scoreJson());
      expect(s.dimensions.colorHarmony, 80.0);
      expect(s.dimensions.styleCohesion, 78.0);
    });

    test('parses detectedItems list', () {
      final s = LiveScore.fromJson(_scoreJson());
      expect(s.detectedItems, ['navy blazer', 'white tee']);
    });

    test('parses deltaNote', () {
      final s = LiveScore.fromJson(_scoreJson());
      expect(s.deltaNote, 'Collar added +5');
    });

    test('handles null deltaNote', () {
      final json = _scoreJson();
      json.remove('delta_note');
      final s = LiveScore.fromJson(json);
      expect(s.deltaNote, isNull);
    });

    test('defaults on empty map', () {
      final s = LiveScore.fromJson({});
      expect(s.overallScore, 0.0);
      expect(s.letterGrade, '?');
      expect(s.detectedItems, isEmpty);
      expect(s.deltaNote, isNull);
    });

    test('coerces int score to double', () {
      final json = _scoreJson();
      json['overall_score'] = 85;
      final s = LiveScore.fromJson(json);
      expect(s.overallScore, isA<double>());
      expect(s.overallScore, 85.0);
    });

    test('scoredAt defaults to approximately now', () {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final s = LiveScore.fromJson(_scoreJson());
      expect(s.scoredAt.isAfter(before), isTrue);
    });
  });

  group('LiveScore.empty', () {
    test('overallScore is zero', () {
      expect(LiveScore.empty.overallScore, 0.0);
    });

    test('letterGrade is "?"', () {
      expect(LiveScore.empty.letterGrade, '?');
    });

    test('detectedItems is empty', () {
      expect(LiveScore.empty.detectedItems, isEmpty);
    });

    test('deltaNote is null', () {
      expect(LiveScore.empty.deltaNote, isNull);
    });
  });

  // ── LiveOccasion ───────────────────────────────────────────────────────────

  group('LiveOccasion', () {
    test('every occasion has a non-empty label', () {
      for (final o in LiveOccasion.values) {
        expect(o.label, isNotEmpty, reason: '${o.name} label is empty');
      }
    });

    test('every occasion has a non-empty emoji', () {
      for (final o in LiveOccasion.values) {
        expect(o.emoji, isNotEmpty, reason: '${o.name} emoji is empty');
      }
    });

    test('autoDetect.promptText returns "auto-detect"', () {
      expect(LiveOccasion.autoDetect.promptText, 'auto-detect');
    });

    test('non-auto occasions promptText equals label', () {
      for (final o in LiveOccasion.values) {
        if (o != LiveOccasion.autoDetect) {
          expect(o.promptText, o.label,
              reason: '${o.name} promptText should equal label');
        }
      }
    });

    test('has exactly 9 cases', () {
      expect(LiveOccasion.values.length, 9);
    });
  });

  // ── TierLimits ─────────────────────────────────────────────────────────────

  group('TierLimits', () {
    test('free tier allows 4 calls', () {
      expect(TierLimits.free, 4);
    });

    test('Style+ tier allows 15 calls', () {
      expect(TierLimits.stylePlus, 15);
    });

    test('Pro tier allows 40 calls', () {
      expect(TierLimits.pro, 40);
    });

    test('free tier is the most restrictive', () {
      expect(TierLimits.free, lessThan(TierLimits.stylePlus));
      expect(TierLimits.stylePlus, lessThan(TierLimits.pro));
    });
  });

  // ── ScoreSnapshot ──────────────────────────────────────────────────────────

  group('ScoreSnapshot', () {
    test('stores timestamp, score, and grade', () {
      final now = DateTime.now();
      final snap = ScoreSnapshot(
        timestamp: now,
        score: 88.5,
        grade: 'B+',
      );
      expect(snap.timestamp, now);
      expect(snap.score, 88.5);
      expect(snap.grade, 'B+');
    });
  });

  // ── FrameData ──────────────────────────────────────────────────────────────

  group('FrameData', () {
    test('stores pixels, width, height, and capturedAt', () {
      final pixels = Uint8List.fromList(List.filled(64 * 64, 128));
      final now = DateTime.now();
      final frame = FrameData(
        pixels: pixels,
        width: 64,
        height: 64,
        capturedAt: now,
      );
      expect(frame.pixels.length, 64 * 64);
      expect(frame.width, 64);
      expect(frame.height, 64);
      expect(frame.capturedAt, now);
    });
  });

  // ── LiveState enum ─────────────────────────────────────────────────────────

  group('LiveState', () {
    test('has all expected states', () {
      const expected = {
        LiveState.initializing,
        LiveState.firstScan,
        LiveState.scored,
        LiveState.monitoring,
        LiveState.analyzing,
        LiveState.error,
        LiveState.rateLimited,
      };
      expect(LiveState.values.toSet(), equals(expected));
    });
  });
}
