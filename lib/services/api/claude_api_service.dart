import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:styleiq/core/constants/api_keys.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/makeover/models/hairstyle_recommendation.dart';

/// Exception thrown when Claude API returns an error
class ClaudeApiException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  ClaudeApiException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'ClaudeApiException: $message (code: $code)';
}

/// Service for interacting with the Claude API (the StyleIQ brain)
class ClaudeApiService {
  final Dio _dio;
  final String _apiKey;

  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _messagesEndpoint = '/messages';

  // ─── OUTFIT ANALYSIS SYSTEM PROMPT ───────────────────────────────────────
  static const String _outfitSystemPrompt =
      "You are StyleIQ, the world's most knowledgeable AI fashion analyst. "
      "You combine the eye of a professional stylist, the cultural depth of a "
      "fashion historian, and the warmth of an encouraging friend.\n\n"
      "=== CORE IDENTITY ===\n"
      "Personality: Warm, witty, encouraging but honest. Celebrate what works "
      "before suggesting improvements. Use fashion terminology naturally.\n\n"
      "=== ANALYSIS PROTOCOL ===\n"
      "STEP 1 - DETECT AND IDENTIFY\n"
      "- Identify each visible clothing item (top, bottom, outerwear, footwear, accessories)\n"
      "- Detect colors, patterns, and apparent fabric types\n"
      "- Assess body type and proportions (without judgment)\n"
      "- Note setting/background for occasion context\n"
      "- Detect any traditional or cultural garments\n\n"
      "STEP 2 - CULTURAL CONTEXT CHECK\n"
      "- If traditional garments detected (saree, kimono, thobe, agbada, hanbok etc.), "
      "switch to Cultural Scoring Mode\n"
      "- Evaluate against that tradition's own standards, NOT Western fashion norms\n"
      "- Respect regional variations within traditions\n\n"
      "STEP 3 - SCORE ACROSS 5 DIMENSIONS (0-100 each)\n"
      "1. COLOR HARMONY (25%): color wheel relationships, contrast, palette cohesion, skin tone compatibility\n"
      "2. FIT & PROPORTION (25%): flattering silhouette, length, balance between fitted/relaxed\n"
      "3. OCCASION MATCH (20%): formality level, cultural appropriateness, practical considerations\n"
      "4. TREND ALIGNMENT (15%): current season trends, regional style, timelessness vs trendiness\n"
      "5. STYLE COHESION (15%): internal consistency, intentional contrast, accessory integration\n\n"
      "STEP 4 - CALCULATE OVERALL SCORE\n"
      "Overall = (Color*0.25) + (Fit*0.25) + (Occasion*0.20) + (Trend*0.15) + (Cohesion*0.15)\n"
      "Letter Grade: S(95-100), A+(90-94), A(85-89), B+(80-84), B(75-79), C+(70-74), C(65-69), D(50-64), F(<50)\n\n"
      "STEP 5 - GENERATE FEEDBACK\n"
      "a) HEADLINE: One punchy memorable line\n"
      "a2) EASY SUMMARY: One plain-English sentence a non-fashion user can understand immediately\n"
      "b) TOP STRENGTHS: 2-3 specific things that work brilliantly\n"
      "c) IMPROVEMENT SUGGESTIONS: 2-3 suggestions each with what/why/score impact/budget option\n"
      "d) QUICK WINS: 2-3 ultra-short action lines starting with a verb\n"
      "e) IMPROVED LOOK NARRATIVE: Describe how the outfit would feel after the suggested changes, in one vivid sentence\n"
      "f) STYLE INSIGHT: One educational fashion tip\n\n"
      "=== RESPONSE FORMAT ===\n"
      "Return ONLY valid JSON with no markdown, no code blocks:\n"
      '{"headline":"string","easy_summary":"string","overall_score":number,"letter_grade":"string",'
      '"dimensions":{"color_harmony":{"score":number,"comment":"string"},'
      '"fit_proportion":{"score":number,"comment":"string"},'
      '"occasion_match":{"score":number,"comment":"string"},'
      '"trend_alignment":{"score":number,"comment":"string"},'
      '"style_cohesion":{"score":number,"comment":"string"}},'
      '"strengths":["string"],"suggestions":[{"change":"string","reason":"string",'
      '"score_impact":"+number","budget_option":"string"}],'
      '"quick_wins":["string"],"improved_look_narrative":"string",'
      '"style_insight":"string","detected_items":["string"],'
      '"cultural_context":"string or null","body_type_detected":"string",'
      '"season_appropriateness":"string","aesthetic_category":"string"}\n\n'
      "=== CRITICAL RULES ===\n"
      "1. NEVER body-shame. Frame as style optimization, never body criticism.\n"
      "2. NEVER say a body type is wrong.\n"
      "3. ALWAYS celebrate before critiquing.\n"
      "4. RESPECT cultural dress. A saree is not costume.\n"
      "5. BE SPECIFIC with every suggestion.\n"
      "6. SCORE FAIRLY. An honest 72 beats a fake 90.\n"
      "7. CONSIDER CONTEXT. A graphic tee scores differently for a concert vs interview.\n"
      "8. SIZE INCLUSIVE. Recommendations work for ALL sizes XS through 5XL.\n"
      "9. GENDER FLUID. Analyze the outfit, not assumptions about the wearer.\n"
      "10. BUDGET AWARE. Always include thrift-friendly options.";

  // ─── HAIRSTYLE SYSTEM PROMPT ──────────────────────────────────────────────
  static const String _hairstyleSystemPrompt =
      "You are StyleIQ's hairstyle intelligence module. Analyze selfie photos "
      "to detect face shape and hair texture, then recommend personalized hairstyles.\n\n"
      "=== DETECTION PROTOCOL ===\n"
      "1. FACE SHAPE: Classify as oval, round, square, heart, oblong, or diamond\n"
      "2. HAIR TEXTURE (Andre Walker system):\n"
      "   - Straight: 1A/1B/1C  |  Wavy: 2A/2B/2C  |  Curly: 3A/3B/3C  |  Coily: 4A/4B/4C\n\n"
      "=== RECOMMENDATION CRITERIA ===\n"
      "- Recommend 3-5 hairstyles suited to face shape and texture\n"
      "- Include styles across different lengths and maintenance levels\n"
      "- Include at least one low-maintenance option\n"
      "- Never shame natural texture — work with it\n\n"
      "=== RESPONSE FORMAT ===\n"
      "Return ONLY valid JSON with no markdown:\n"
      '{"face_shape":"string","hair_texture":"string","recommendations":['
      '{"name":"string","description":"string","why_it_works":"string",'
      '"maintenance_level":"low|medium|high","length":"short|medium|long",'
      '"styling_tips":"string"}],"style_notes":"string"}';

  // ─── CULTURAL DRESS CODE SYSTEM PROMPT ───────────────────────────────────
  static const String _culturalSystemPrompt =
      "You are StyleIQ's cultural fashion intelligence module. Provide respectful, "
      "accurate, detailed guidance on traditional and cultural dress codes.\n\n"
      "=== CORE PRINCIPLES ===\n"
      "1. Center each culture's own values — never evaluate through a Western lens\n"
      "2. Respect regional variations within cultures\n"
      "3. Fashion rules are guidelines, not laws — personal expression matters\n"
      "4. Flag cultural appropriation with education not judgment\n"
      "5. Never rate one culture's dress as superior to another\n\n"
      "=== RESPONSE FORMAT ===\n"
      "Return ONLY valid JSON with no markdown:\n"
      '{"culture":"string","occasion":"string","appropriate_garments":["string"],'
      '"color_guidance":[{"color":"string","meaning":"string","appropriateness":"encouraged|neutral|avoid"}],'
      '"accessory_rules":["string"],"faux_pas":["string"],"fusion_tips":["string"],'
      '"regional_notes":"string","dress_code_summary":"string"}';

  ClaudeApiService({String? apiKey, Dio? dio})
      : _apiKey = apiKey ?? ApiKeys.claudeApiKey,
        _dio = dio ?? Dio();

  // ─── PUBLIC METHODS ───────────────────────────────────────────────────────

  /// Analyze an outfit from raw image bytes → returns [StyleAnalysis]
  Future<StyleAnalysis> analyzeOutfit(
      Uint8List imageBytes, String imageName) async {
    _validateKey();
    _validateImageName(imageName);

    try {
      final base64Image = ImageUtils.bytesToBase64(imageBytes);
      final mediaType = ImageUtils.getMediaTypeFromName(imageName);
      final dataUrl = ImageUtils.toDataUrl(imageBytes, imageName);

      final requestBody = {
        'model': AppConstants.claudeModel,
        'max_tokens': AppConstants.claudeMaxTokens,
        'system': _outfitSystemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                }
              },
              {
                'type': 'text',
                'text':
                    'Please analyze this outfit photo and provide comprehensive style analysis in the exact JSON format specified.',
              }
            ]
          }
        ]
      };

      final text = await _post(requestBody);
      final analysis = StyleAnalysis.fromJson(_parseJson(text));
      // Store as data URL so image renders on web and native
      return analysis.copyWith(imageUrl: dataUrl);
    } on ClaudeApiException {
      rethrow;
    } on FormatException catch (e) {
      throw ClaudeApiException(
        message: 'Invalid JSON in API response: ${e.message}',
        code: 'JSON_PARSE_ERROR',
        originalError: e,
      );
    } on DioException catch (e) {
      debugPrint('=== DIO ERROR (analyzeOutfit) ===');
      debugPrint('Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      throw ClaudeApiException(
        message: 'Network error [${e.type.name}]: ${e.message}',
        code: 'NETWORK_ERROR',
        originalError:
            'Status: ${e.response?.statusCode} | ${e.response?.data ?? e.message}',
      );
    } catch (e, stack) {
      debugPrint('=== UNKNOWN ERROR (analyzeOutfit) ===\n$e\n$stack');
      throw ClaudeApiException(
        message: 'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );
    }
  }

  /// Analyze a selfie from raw bytes → returns [HairstyleRecommendation]
  Future<HairstyleRecommendation> getHairstyleRecommendations(
      Uint8List imageBytes, String imageName) async {
    _validateKey();
    _validateImageName(imageName);

    try {
      final base64Image = ImageUtils.bytesToBase64(imageBytes);
      final mediaType = ImageUtils.getMediaTypeFromName(imageName);

      final requestBody = {
        'model': AppConstants.claudeModel,
        'max_tokens': 2048,
        'system': _hairstyleSystemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                }
              },
              {
                'type': 'text',
                'text':
                    'Please analyze my face shape and hair texture from this photo and recommend the best hairstyles in the exact JSON format specified.',
              }
            ]
          }
        ]
      };

      final text = await _post(requestBody);
      return HairstyleRecommendation.fromJson(_parseJson(text));
    } on ClaudeApiException {
      rethrow;
    } on FormatException catch (e) {
      throw ClaudeApiException(
        message: 'Invalid JSON in API response: ${e.message}',
        code: 'JSON_PARSE_ERROR',
        originalError: e,
      );
    } on DioException catch (e) {
      throw ClaudeApiException(
        message: 'Network error: ${e.message}',
        code: 'NETWORK_ERROR',
        originalError: e,
      );
    } catch (e) {
      throw ClaudeApiException(
        message: 'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );
    }
  }

  /// Get cultural dress code guidance → returns structured JSON string
  Future<String> getCulturalDressCodeGuidance(
    String culture,
    String occasion,
  ) async {
    _validateKey();

    try {
      final requestBody = {
        'model': AppConstants.claudeModel,
        'max_tokens': 2048,
        'system': _culturalSystemPrompt,
        'messages': [
          {
            'role': 'user',
            'content': 'Provide complete dress code guidance for $culture culture, '
                'specifically for a $occasion occasion. Return the structured JSON as specified.',
          }
        ]
      };

      return await _post(requestBody);
    } on DioException catch (e) {
      throw ClaudeApiException(
        message: 'Network error: ${e.message}',
        code: 'NETWORK_ERROR',
        originalError: e,
      );
    } catch (e) {
      throw ClaudeApiException(
        message: 'Unexpected error: $e',
        code: 'UNKNOWN_ERROR',
        originalError: e,
      );
    }
  }

  // ─── PRIVATE HELPERS ──────────────────────────────────────────────────────

  void _validateKey() {
    if (_apiKey.isEmpty) {
      throw ClaudeApiException(
        message: 'Claude API key not configured. '
            'Run with: flutter run --dart-define=CLAUDE_API_KEY=your-key-here',
        code: 'NO_API_KEY',
      );
    }
  }

  void _validateImageName(String name) {
    if (!ImageUtils.isValidImageName(name)) {
      throw ClaudeApiException(
        message: 'Invalid image format. Supported: jpg, png, webp',
        code: 'INVALID_IMAGE',
      );
    }
  }

  /// POST to the messages endpoint and return the text content
  Future<String> _post(Map<String, dynamic> body) async {
    final response = await _dio.post(
      '$_baseUrl$_messagesEndpoint',
      data: jsonEncode(body),
      options: Options(
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
          // Required for direct browser access (Flutter web)
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        sendTimeout: const Duration(seconds: AppConstants.claudeTimeoutSeconds),
        receiveTimeout:
            const Duration(seconds: AppConstants.claudeTimeoutSeconds),
      ),
    );

    if (response.statusCode != 200) {
      throw ClaudeApiException(
        message: 'API returned status ${response.statusCode}',
        code: response.statusCode.toString(),
        originalError: response.data,
      );
    }

    final responseData = response.data as Map<String, dynamic>;
    final content = responseData['content'] as List?;

    if (content == null || content.isEmpty) {
      throw ClaudeApiException(
        message: 'Empty response from API',
        code: 'EMPTY_RESPONSE',
      );
    }

    final text = (content.first as Map<String, dynamic>)['text'] as String?;
    if (text == null) {
      throw ClaudeApiException(
        message: 'No text content in API response',
        code: 'NO_TEXT_CONTENT',
      );
    }
    return text;
  }

  /// Strip markdown code fences and parse JSON
  Map<String, dynamic> _parseJson(String text) {
    String cleaned = text.trim();
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
}
