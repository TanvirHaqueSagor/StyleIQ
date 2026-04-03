import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:styleiq/core/constants/api_keys.dart';

import '../models/live_score.dart';

/// Calls Claude Sonnet with a speed-mode prefix for fast live scoring.
///
/// Uses a lighter system prompt that skips style_insight and suggestions —
/// returns only scores, one-sentence comments, detected items, and delta note.
class LiveAnalysisService {
  final Dio _dio;
  final String _apiKey;

  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _messagesEndpoint = '/messages';
  // Sonnet for speed (~1.2s) vs Opus (~3.5s)
  static const String _liveModel = 'claude-sonnet-4-20250514';
  static const int _maxTokens = 400;
  static const int _timeoutSeconds = 7;

  LiveAnalysisService({String? apiKey, Dio? dio})
      : _apiKey = apiKey ?? ApiKeys.claudeApiKey,
        _dio = dio ?? Dio();

  // ── Speed-mode system prompt prefix ─────────────────────────────────────────
  static String _buildSystemPrompt(
      LiveOccasion occasion, double? previousScore) {
    final occasionText = occasion.promptText;
    final prevText =
        previousScore != null ? previousScore.round().toString() : 'unknown';

    return 'SPEED MODE ACTIVE. You are scoring a live camera frame for StyleIQ.\n'
        'Return ONLY the JSON score object below. No style_insight, no suggestions, no budget_option.\n'
        'Keep each dimension comment to ONE sentence (max 8 words).\n'
        'Occasion context: $occasionText.\n'
        'Previous score: $prevText (note what changed if applicable).\n'
        'Respond in under 200 tokens.\n\n'
        'Return ONLY valid JSON — no markdown, no code blocks:\n'
        '{"overall_score":number,"letter_grade":"string",'
        '"dimensions":{'
        '"color_harmony":{"score":number,"comment":"string"},'
        '"fit_proportion":{"score":number,"comment":"string"},'
        '"occasion_match":{"score":number,"comment":"string"},'
        '"trend_alignment":{"score":number,"comment":"string"},'
        '"style_cohesion":{"score":number,"comment":"string"}},'
        '"detected_items":["string"],'
        '"delta_note":"string or null"}\n\n'
        // Keep cultural intelligence from the full prompt
        'IMPORTANT: If traditional garments are visible (saree, kimono, thobe, agbada, hanbok, etc.) '
        'evaluate against that tradition\'s OWN standards, not Western fashion norms.\n'
        'Never body-shame. Score fairly. Gender-fluid analysis only.';
  }

  /// Score a live camera frame.
  ///
  /// [jpegBytes] — JPEG image (quality ~85, max 1080px on longest side)
  /// [occasion] — Selected occasion for context
  /// [previousScore] — Last score for delta calculation
  Future<LiveScore> scoreFrame({
    required Uint8List jpegBytes,
    required LiveOccasion occasion,
    double? previousScore,
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('API key not configured');
    }

    final base64Image = base64Encode(jpegBytes);

    final requestBody = {
      'model': _liveModel,
      'max_tokens': _maxTokens,
      'system': _buildSystemPrompt(occasion, previousScore),
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Image,
              }
            },
            {
              'type': 'text',
              'text':
                  'Score this live outfit photo. Return only the JSON object.',
            }
          ]
        }
      ]
    };

    final response = await _dio.post(
      '$_baseUrl$_messagesEndpoint',
      data: jsonEncode(requestBody),
      options: Options(
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        sendTimeout: const Duration(seconds: _timeoutSeconds),
        receiveTimeout: const Duration(seconds: _timeoutSeconds),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('API status ${response.statusCode}');
    }

    final content =
        (response.data as Map<String, dynamic>)['content'] as List?;
    if (content == null || content.isEmpty) {
      throw Exception('Empty API response');
    }

    final text = (content.first as Map<String, dynamic>)['text'] as String? ?? '';
    final json = _parseJson(text);
    return LiveScore.fromJson(json);
  }

  /// Compress and resize image for API submission.
  /// Target: JPEG quality 85, max 1080px on longest side.
  static Future<Uint8List> prepareFrame(Uint8List rawBytes) async {
    return compute(_compressFrame, rawBytes);
  }

  static Uint8List _compressFrame(Uint8List raw) {
    var decoded = img.decodeImage(raw);
    if (decoded == null) return raw;

    const maxSide = 1080;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? maxSide : -1,
        height: decoded.height >= decoded.width ? maxSide : -1,
      );
    }

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
  }

  Map<String, dynamic> _parseJson(String text) {
    final clean = text.trim();
    // Strip any markdown code fences Claude might add
    final jsonStart = clean.indexOf('{');
    final jsonEnd = clean.lastIndexOf('}');
    if (jsonStart == -1 || jsonEnd == -1) {
      throw FormatException('No JSON object in response: $clean');
    }
    return jsonDecode(clean.substring(jsonStart, jsonEnd + 1))
        as Map<String, dynamic>;
  }
}
