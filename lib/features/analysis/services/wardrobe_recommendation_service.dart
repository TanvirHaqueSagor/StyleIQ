import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/wardrobe/models/wardrobe_item.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

/// Matches existing wardrobe items to analysis suggestions.
/// Returns ranked recommendations so the user can act immediately.
class WardrobeMatch {
  final WardrobeItem item;
  final String reason;
  final double relevanceScore; // 0-1
  final String matchType; // 'color', 'occasion', 'complement', 'replace'

  const WardrobeMatch({
    required this.item,
    required this.reason,
    required this.relevanceScore,
    required this.matchType,
  });
}

class WardrobeRecommendationService {
  final LocalStorageService _storageService;

  WardrobeRecommendationService({LocalStorageService? storageService})
      : _storageService = storageService ?? LocalStorageService();

  /// Find wardrobe items that complement or improve the analyzed outfit
  Future<List<WardrobeMatch>> findMatchesForAnalysis({
    required StyleAnalysis analysis,
    required String userId,
    int maxResults = 6,
  }) async {
    final allItems = await _storageService.getWardrobeItems(userId);
    if (allItems.isEmpty) return [];

    final matches = <WardrobeMatch>[];

    for (final item in allItems) {
      final match = _scoreItem(item, analysis);
      if (match != null) matches.add(match);
    }

    matches.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return matches.take(maxResults).toList();
  }

  WardrobeMatch? _scoreItem(WardrobeItem item, StyleAnalysis analysis) {
    double score = 0;
    String reason = '';
    String matchType = 'complement';

    // ── Color matching ──────────────────────────────────────────────────────
    final colorScore = _colorRelevance(item, analysis);
    if (colorScore > 0) {
      score += colorScore * 0.4;
      matchType = 'color';
      reason = _colorReason(item, analysis);
    }

    // ── Occasion matching ───────────────────────────────────────────────────
    final occasionScore = _occasionRelevance(item, analysis);
    if (occasionScore > 0) {
      score += occasionScore * 0.3;
      if (matchType != 'color') matchType = 'occasion';
      if (reason.isEmpty) reason = _occasionReason(item, analysis);
    }

    // ── Category gap filling ────────────────────────────────────────────────
    final gapScore = _gapFillRelevance(item, analysis);
    if (gapScore > 0) {
      score += gapScore * 0.3;
      if (matchType == 'complement') matchType = 'complement';
      if (reason.isEmpty) reason = _gapReason(item, analysis);
    }

    if (score < 0.2) return null;
    return WardrobeMatch(
      item: item,
      reason: reason.isNotEmpty ? reason : 'Complements your current look',
      relevanceScore: score.clamp(0, 1),
      matchType: matchType,
    );
  }

  // ── Color analysis ──────────────────────────────────────────────────────────

  double _colorRelevance(WardrobeItem item, StyleAnalysis analysis) {
    final itemColor = item.color.toLowerCase();
    final detectedItems = analysis.detectedItems.join(' ').toLowerCase();
    final suggestions = analysis.suggestions.map((s) => s.change).join(' ').toLowerCase();
    final summary = (analysis.easySummary ?? '').toLowerCase();

    // Mentioned in suggestions — strong signal
    if (suggestions.contains(itemColor)) return 0.9;

    // Neutral colors almost always work
    final neutrals = ['black', 'white', 'grey', 'gray', 'beige', 'navy', 'cream'];
    if (neutrals.contains(itemColor)) return 0.7;

    // Color mentioned in the analysis context
    if (detectedItems.contains(itemColor) || summary.contains(itemColor)) return 0.5;

    return 0;
  }

  String _colorReason(WardrobeItem item, StyleAnalysis analysis) {
    final suggestions = analysis.suggestions.map((s) => s.change).join(' ').toLowerCase();
    if (suggestions.contains(item.color.toLowerCase())) {
      return 'Matches the recommended ${item.color} color suggestion';
    }
    return 'The ${item.color} tone complements your outfit\'s color palette';
  }

  // ── Occasion analysis ───────────────────────────────────────────────────────

  double _occasionRelevance(WardrobeItem item, StyleAnalysis analysis) {
    final occasionText =
        '${analysis.detectedItems.join(' ')} ${analysis.easySummary ?? ''} ${analysis.headline}'
            .toLowerCase();

    final tags = item.tags.map((t) => t.toLowerCase()).toList();

    // Check if any item tag matches the occasion
    for (final tag in tags) {
      if (occasionText.contains(tag)) return 0.8;
    }

    // Category-based occasion fit
    final occasionKeywords = {
      'formal': ['dress', 'blazer', 'trousers', 'shoes'],
      'casual': ['jeans', 'sneakers', 'tshirt', 't-shirt'],
      'smart': ['chinos', 'loafers', 'shirt', 'blouse'],
    };

    for (final entry in occasionKeywords.entries) {
      if (occasionText.contains(entry.key)) {
        final cat = item.subcategory.toLowerCase();
        if (entry.value.any((kw) => cat.contains(kw))) return 0.6;
      }
    }

    return 0;
  }

  String _occasionReason(WardrobeItem item, StyleAnalysis analysis) {
    return 'Great fit for the ${_detectOccasion(analysis)} vibe of this look';
  }

  String _detectOccasion(StyleAnalysis analysis) {
    final text = (analysis.easySummary ?? analysis.headline).toLowerCase();
    if (text.contains('formal') || text.contains('professional')) return 'formal';
    if (text.contains('casual')) return 'casual';
    if (text.contains('evening') || text.contains('party')) return 'evening';
    return 'styled';
  }

  // ── Gap-filling analysis ────────────────────────────────────────────────────

  double _gapFillRelevance(WardrobeItem item, StyleAnalysis analysis) {
    final suggestions = analysis.suggestions.map((s) => s.change.toLowerCase()).toList();
    final category = item.category.toLowerCase();

    // Check if suggestions mention this category
    for (final suggestion in suggestions) {
      if (suggestion.contains(category) ||
          suggestion.contains(item.subcategory.toLowerCase())) {
        return 0.85;
      }
    }

    return 0;
  }

  String _gapReason(WardrobeItem item, StyleAnalysis analysis) {
    return 'Could address the AI\'s recommendation for a ${item.category.toLowerCase()} upgrade';
  }
}
