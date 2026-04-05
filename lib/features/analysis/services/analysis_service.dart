import 'dart:convert';
import 'dart:typed_data';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';
import 'package:styleiq/services/api/claude_api_service.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';
import 'package:uuid/uuid.dart';

/// Business logic layer between the UI and API/storage services
class AnalysisService {
  final ClaudeApiService _claudeApiService;
  final LocalStorageService _storageService;

  AnalysisService({
    ClaudeApiService? claudeApiService,
    LocalStorageService? storageService,
  })  : _claudeApiService = claudeApiService ?? ClaudeApiService(),
        _storageService = storageService ?? LocalStorageService();

  /// Analyze outfit from image bytes, persist result with image attached
  Future<StyleAnalysis> analyzeOutfit(
      Uint8List imageBytes, String imageName, String userId) async {
    final analysis =
        await _claudeApiService.analyzeOutfit(imageBytes, imageName);
    final dataUrl = ImageUtils.toDataUrl(imageBytes, imageName);
    final generatedMockups = _buildGeneratedMockups(analysis, dataUrl);
    // Attach the image as a data URL so history items can display + replay it
    final withImage = analysis.copyWith(
      imageUrl: dataUrl,
      jobStatus: AnalysisJobStatus.completed,
      generatedMockups: generatedMockups,
    );
    await _storageService.saveStyleAnalysis(withImage, userId);
    return withImage;
  }

  List<GeneratedMockup> _buildGeneratedMockups(
    StyleAnalysis analysis,
    String imageUrl,
  ) {
    final mockups = <GeneratedMockup>[];
    final suggestionSets = analysis.suggestions.take(3).toList();
    if (suggestionSets.isEmpty) {
      mockups.add(
        GeneratedMockup(
          id: const Uuid().v4(),
          label: 'Recommended Look',
          imageUrl: imageUrl,
          appliedChanges: analysis.quickWins.take(2).toList(),
          whyItWorks: analysis.improvedLookNarrative ??
              analysis.easySummary ??
              'A cleaner, more intentional version of your current look.',
          provenance:
              'AI-directed styling mockup based on your original photo.',
          isPrimary: true,
        ),
      );
      return mockups;
    }

    for (var i = 0; i < suggestionSets.length; i++) {
      final suggestion = suggestionSets[i];
      mockups.add(
        GeneratedMockup(
          id: const Uuid().v4(),
          label: i == 0 ? 'Best Revision' : 'Option ${i + 1}',
          imageUrl: imageUrl,
          appliedChanges: [
            suggestion.change,
            if (analysis.quickWins.length > i) analysis.quickWins[i],
          ],
          whyItWorks: suggestion.reason,
          provenance:
              'AI-generated styling preview anchored to your original photo.',
          isPrimary: i == 0,
        ),
      );
    }
    return mockups;
  }

  /// Get analysis history for a user
  Future<List<StyleAnalysis>> getAnalysisHistory(String userId) =>
      _storageService.getStyleAnalyses(userId);

  /// Get cultural dress code guidance (returns structured map)
  Future<Map<String, dynamic>> getCulturalGuidance(
    String culture,
    String occasion,
  ) async {
    final raw = await _claudeApiService.getCulturalDressCodeGuidance(
      culture,
      occasion,
    );
    String cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned
          .replaceFirst('```json', '')
          .replaceAll(RegExp(r'```$'), '')
          .trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst('```', '')
          .replaceAll(RegExp(r'```$'), '')
          .trim();
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Get hairstyle recommendations from a selfie photo (bytes) and persist result
  Future<HairstyleRecommendation> getHairstyleRecommendations(
    Uint8List imageBytes,
    String imageName,
  ) async {
    final recommendation = await _claudeApiService.getHairstyleRecommendations(
        imageBytes, imageName);
    final result = HairstyleResult(
      id: const Uuid().v4(),
      recommendation: recommendation,
      imageUrl: ImageUtils.toDataUrl(imageBytes, imageName),
      analyzedAt: DateTime.now(),
    );
    await _storageService.saveHairstyleResult(result);
    return recommendation;
  }

  /// Get hairstyle analysis history
  Future<List<HairstyleResult>> getHairstyleHistory() =>
      _storageService.getHairstyleHistory();

  /// Delete a single analysis entry
  Future<void> deleteAnalysis(StyleAnalysis analysis, String userId) =>
      _storageService.deleteStyleAnalysis(
          '${userId}_${analysis.analyzedAt.millisecondsSinceEpoch}');

  /// Clear analysis history for a user
  Future<void> clearAnalysisHistory(String userId) =>
      _storageService.clearAllStyleAnalyses(userId);
}
