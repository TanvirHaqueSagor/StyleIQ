import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';
import 'package:styleiq/services/api/claude_api_service.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeClaudeApi implements ClaudeApiService {
  StyleAnalysis? analyzeOutfitResult;
  HairstyleRecommendation? hairstyleResult;
  String? culturalGuidanceResult;
  Exception? throwOnAnalyze;

  @override
  Future<StyleAnalysis> analyzeOutfit(
      Uint8List imageBytes, String imageName) async {
    if (throwOnAnalyze != null) throw throwOnAnalyze!;
    return analyzeOutfitResult ??
        StyleAnalysis(
          headline: 'Default',
          overallScore: 75,
          letterGrade: 'B',
          dimensions: DimensionScores(
            colorHarmony: DimensionScore(score: 75, comment: ''),
            fitProportion: DimensionScore(score: 75, comment: ''),
            occasionMatch: DimensionScore(score: 75, comment: ''),
            trendAlignment: DimensionScore(score: 75, comment: ''),
            styleCohesion: DimensionScore(score: 75, comment: ''),
          ),
          strengths: ['Good'],
          suggestions: [],
          styleInsight: 'Insight',
          detectedItems: ['jeans'],
        );
  }

  @override
  Future<HairstyleRecommendation> getHairstyleRecommendations(
      Uint8List imageBytes, String imageName) async {
    return hairstyleResult ??
        const HairstyleRecommendation(
          faceShape: 'oval',
          hairTexture: '2A',
          recommendations: [],
          styleNotes: 'Notes',
        );
  }

  @override
  Future<String> getCulturalDressCodeGuidance(
      String culture, String occasion) async {
    return culturalGuidanceResult ?? '{"result": "ok"}';
  }

  // Unused methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements LocalStorageService {
  final List<StyleAnalysis> _analyses = [];
  final List<HairstyleResult> _hairstyleResults = [];
  String? lastDeletedKey;
  bool clearedAll = false;

  @override
  Future<void> saveStyleAnalysis(StyleAnalysis analysis, String userId) async {
    _analyses.add(analysis);
  }

  @override
  Future<List<StyleAnalysis>> getStyleAnalyses(String userId) async =>
      List.from(_analyses);

  @override
  Future<void> deleteStyleAnalysis(String key) async {
    lastDeletedKey = key;
  }

  @override
  Future<void> clearAllStyleAnalyses(String userId) async {
    clearedAll = true;
    _analyses.clear();
  }

  @override
  Future<void> saveHairstyleResult(HairstyleResult result) async {
    _hairstyleResults.add(result);
  }

  @override
  Future<List<HairstyleResult>> getHairstyleHistory() async =>
      List.from(_hairstyleResults);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _imageBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]); // minimal JPEG

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late _FakeClaudeApi fakeApi;
  late _FakeStorage fakeStorage;
  late AnalysisService service;

  setUp(() {
    fakeApi = _FakeClaudeApi();
    fakeStorage = _FakeStorage();
    service = AnalysisService(
      claudeApiService: fakeApi,
      storageService: fakeStorage,
    );
  });

  // ── analyzeOutfit ──────────────────────────────────────────────────────────

  group('analyzeOutfit', () {
    test('returns analysis with imageUrl attached as data URL', () async {
      final result =
          await service.analyzeOutfit(_imageBytes, 'photo.jpg', 'user-1');
      expect(result.imageUrl, isNotNull);
      expect(result.imageUrl, startsWith('data:image/jpeg;base64,'));
    });

    test('persists analysis to storage', () async {
      await service.analyzeOutfit(_imageBytes, 'photo.jpg', 'user-1');
      expect(fakeStorage._analyses.length, 1);
    });

    test('stored analysis has the imageUrl set', () async {
      await service.analyzeOutfit(_imageBytes, 'photo.jpg', 'user-1');
      expect(fakeStorage._analyses.first.imageUrl, isNotNull);
    });

    test('returns the API result headline', () async {
      fakeApi.analyzeOutfitResult = StyleAnalysis(
        headline: 'Street Chic',
        overallScore: 88,
        letterGrade: 'B+',
        dimensions: DimensionScores(
          colorHarmony: DimensionScore(score: 88, comment: ''),
          fitProportion: DimensionScore(score: 88, comment: ''),
          occasionMatch: DimensionScore(score: 88, comment: ''),
          trendAlignment: DimensionScore(score: 88, comment: ''),
          styleCohesion: DimensionScore(score: 88, comment: ''),
        ),
        strengths: ['Bold color'],
        suggestions: [],
        styleInsight: 'Tip',
        detectedItems: ['hoodie'],
      );
      final result =
          await service.analyzeOutfit(_imageBytes, 'photo.jpg', 'user-1');
      expect(result.headline, 'Street Chic');
      expect(result.overallScore, 88.0);
    });

    test('propagates exception from API', () async {
      fakeApi.throwOnAnalyze = Exception('API timeout');
      expect(
        () => service.analyzeOutfit(_imageBytes, 'photo.jpg', 'user-1'),
        throwsException,
      );
    });
  });

  // ── getAnalysisHistory ─────────────────────────────────────────────────────

  group('getAnalysisHistory', () {
    test('returns empty list when nothing saved', () async {
      final history = await service.getAnalysisHistory('user-1');
      expect(history, isEmpty);
    });

    test('returns saved analyses', () async {
      await service.analyzeOutfit(_imageBytes, 'a.jpg', 'user-1');
      await service.analyzeOutfit(_imageBytes, 'b.jpg', 'user-1');
      final history = await service.getAnalysisHistory('user-1');
      expect(history.length, 2);
    });
  });

  // ── getCulturalGuidance ────────────────────────────────────────────────────

  group('getCulturalGuidance', () {
    test('parses plain JSON response', () async {
      fakeApi.culturalGuidanceResult = '{"guidance": "Wear red"}';
      final result =
          await service.getCulturalGuidance('Bengali', 'wedding');
      expect(result['guidance'], 'Wear red');
    });

    test('strips ```json code fences', () async {
      fakeApi.culturalGuidanceResult =
          '```json\n{"guidance": "Wear saree"}\n```';
      final result =
          await service.getCulturalGuidance('Bengali', 'puja');
      expect(result['guidance'], 'Wear saree');
    });

    test('strips plain ``` code fences', () async {
      fakeApi.culturalGuidanceResult =
          '```\n{"key": "value"}\n```';
      final result =
          await service.getCulturalGuidance('Japanese', 'tea ceremony');
      expect(result['key'], 'value');
    });

    test('handles nested JSON structure', () async {
      fakeApi.culturalGuidanceResult =
          jsonEncode({'colors': ['red', 'gold'], 'avoid': ['white']});
      final result =
          await service.getCulturalGuidance('Bengali', 'wedding');
      expect(result['colors'], ['red', 'gold']);
      expect(result['avoid'], ['white']);
    });
  });

  // ── getHairstyleRecommendations ────────────────────────────────────────────

  group('getHairstyleRecommendations', () {
    test('returns recommendation from API', () async {
      fakeApi.hairstyleResult = const HairstyleRecommendation(
        faceShape: 'heart',
        hairTexture: '3B',
        recommendations: [],
        styleNotes: 'Soft layers work well',
      );
      final result = await service.getHairstyleRecommendations(
          _imageBytes, 'selfie.jpg');
      expect(result.faceShape, 'heart');
      expect(result.hairTexture, '3B');
    });

    test('persists result to storage', () async {
      await service.getHairstyleRecommendations(_imageBytes, 'selfie.jpg');
      expect(fakeStorage._hairstyleResults.length, 1);
    });

    test('stored result has imageUrl as data URL', () async {
      await service.getHairstyleRecommendations(_imageBytes, 'selfie.jpg');
      expect(fakeStorage._hairstyleResults.first.imageUrl,
          startsWith('data:image/jpeg;base64,'));
    });

    test('stored result has non-empty id', () async {
      await service.getHairstyleRecommendations(_imageBytes, 'selfie.jpg');
      expect(fakeStorage._hairstyleResults.first.id, isNotEmpty);
    });
  });

  // ── deleteAnalysis ─────────────────────────────────────────────────────────

  group('deleteAnalysis', () {
    test('calls storage with correct key', () async {
      final analysis = await service.analyzeOutfit(
          _imageBytes, 'photo.jpg', 'user-42');
      await service.deleteAnalysis(analysis, 'user-42');
      expect(fakeStorage.lastDeletedKey, isNotNull);
      expect(fakeStorage.lastDeletedKey,
          contains('user-42'));
    });
  });

  // ── clearAnalysisHistory ───────────────────────────────────────────────────

  group('clearAnalysisHistory', () {
    test('clears all analyses from storage', () async {
      await service.analyzeOutfit(_imageBytes, 'a.jpg', 'user-1');
      await service.clearAnalysisHistory('user-1');
      expect(fakeStorage.clearedAll, isTrue);
      final history = await service.getAnalysisHistory('user-1');
      expect(history, isEmpty);
    });
  });

  // ── getHairstyleHistory ────────────────────────────────────────────────────

  group('getHairstyleHistory', () {
    test('returns empty when nothing saved', () async {
      final history = await service.getHairstyleHistory();
      expect(history, isEmpty);
    });

    test('returns saved results', () async {
      await service.getHairstyleRecommendations(_imageBytes, 'a.jpg');
      await service.getHairstyleRecommendations(_imageBytes, 'b.jpg');
      final history = await service.getHairstyleHistory();
      expect(history.length, 2);
    });
  });
}
