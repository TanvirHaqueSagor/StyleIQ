import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:styleiq/core/constants/app_constants.dart';

/// Result from image generation
class GeneratedImage {
  final String url;
  final Uint8List? bytes;
  final String prompt;
  final String model;

  const GeneratedImage({
    required this.url,
    this.bytes,
    required this.prompt,
    required this.model,
  });
}

class ImageGenerationException implements Exception {
  final String message;
  final int? statusCode;
  ImageGenerationException(this.message, {this.statusCode});
  @override
  String toString() => 'ImageGenerationException: $message';
}

/// Service for AI image generation using FAL.ai
/// Generates outfit previews, hairstyle visualizations, and makeover suggestions
class ImageGenerationService {
  static const String _falBaseUrl = 'https://fal.run';

  // Fast generation model (Flux Schnell)
  static const String _fastModel = 'fal-ai/flux/schnell';

  // High quality model (Flux Pro) — for Pro tier users
  static const String _proModel = 'fal-ai/flux-pro/v1.1-ultra';

  final http.Client _client;
  final String _apiKey;

  ImageGenerationService({http.Client? client})
      : _client = client ?? http.Client(),
        _apiKey = AppConstants.falApiKey;

  bool get isAvailable => _apiKey.isNotEmpty;

  /// Generate an outfit recommendation image from a text description
  Future<GeneratedImage> generateOutfitPreview({
    required String outfitDescription,
    String? bodyType,
    String? occasion,
    bool highQuality = false,
  }) async {
    final model = highQuality ? _proModel : _fastModel;
    final prompt = _buildOutfitPrompt(
      outfitDescription: outfitDescription,
      bodyType: bodyType,
      occasion: occasion,
    );
    return _generateImage(prompt: prompt, model: model);
  }

  /// Generate a hairstyle preview image
  Future<GeneratedImage> generateHairstylePreview({
    required String hairstyleName,
    required String hairDescription,
    String? faceShape,
  }) async {
    final prompt = _buildHairstylePrompt(
      hairstyleName: hairstyleName,
      hairDescription: hairDescription,
      faceShape: faceShape,
    );
    return _generateImage(prompt: prompt, model: _fastModel);
  }

  /// Generate a full makeover preview image
  Future<GeneratedImage> generateMakeoverPreview({
    required String outfitDescription,
    required String hairstyleDescription,
    String? makeupDescription,
    String? glassesDescription,
    String? bodyType,
  }) async {
    final prompt = _buildMakeoverPrompt(
      outfitDescription: outfitDescription,
      hairstyleDescription: hairstyleDescription,
      makeupDescription: makeupDescription,
      glassesDescription: glassesDescription,
      bodyType: bodyType,
    );
    return _generateImage(prompt: prompt, model: _fastModel);
  }

  /// Generate style board — flat lay product images
  Future<GeneratedImage> generateStyleBoard({
    required List<String> items,
    String? colorPalette,
    String? occasion,
  }) async {
    final itemsList = items.take(6).join(', ');
    final prompt = [
      'flat lay fashion styling board',
      'professional product photography, white background',
      'clothing items arranged aesthetically: $itemsList',
      if (colorPalette != null) 'color palette: $colorPalette',
      if (occasion != null) 'for $occasion',
      'editorial magazine quality, high resolution',
    ].join(', ');
    return _generateImage(prompt: prompt, model: _fastModel);
  }

  // ── Core generation ────────────────────────────────────────────────────────

  Future<GeneratedImage> _generateImage({
    required String prompt,
    required String model,
    int width = 768,
    int height = 1024,
  }) async {
    if (!isAvailable) {
      throw ImageGenerationException(
        'Image generation API key not configured. Add FAL_API_KEY to your environment.',
      );
    }

    final uri = Uri.parse('$_falBaseUrl/$model');
    final response = await _client
        .post(
          uri,
          headers: {
            'Authorization': 'Key $_apiKey', // ignore: use_string_buffers
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'prompt': prompt,
            'image_size': {'width': width, 'height': height},
            'num_inference_steps': model.contains('schnell') ? 4 : 28,
            'num_images': 1,
            'enable_safety_checker': true,
          }),
        )
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () => throw ImageGenerationException(
            'Image generation timed out. Please try again.',
          ),
        );

    if (response.statusCode != 200) {
      throw ImageGenerationException(
        'Image generation failed: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final images = data['images'] as List?;
    if (images == null || images.isEmpty) {
      throw ImageGenerationException('No images returned from generation API');
    }

    final imageUrl = (images.first as Map<String, dynamic>)['url'] as String;
    return GeneratedImage(url: imageUrl, prompt: prompt, model: model);
  }

  // ── Prompt builders ────────────────────────────────────────────────────────

  String _buildOutfitPrompt({
    required String outfitDescription,
    String? bodyType,
    String? occasion,
  }) {
    return [
      'fashion photography, full body outfit photo',
      outfitDescription,
      if (bodyType != null && bodyType.isNotEmpty) 'person with $bodyType body type',
      if (occasion != null) 'for $occasion',
      'professional fashion editorial, soft studio lighting',
      'clean neutral background, sharp focus, 8k quality',
      'photorealistic, fashion magazine style',
    ].join(', ');
  }

  String _buildHairstylePrompt({
    required String hairstyleName,
    required String hairDescription,
    String? faceShape,
  }) {
    return [
      'professional hair salon photography',
      '$hairstyleName hairstyle, $hairDescription',
      if (faceShape != null) '$faceShape face shape',
      'studio lighting, portrait photography',
      'hair styling editorial, clean background',
      'photorealistic, 8k quality, professional photo',
    ].join(', ');
  }

  String _buildMakeoverPrompt({
    required String outfitDescription,
    required String hairstyleDescription,
    String? makeupDescription,
    String? glassesDescription,
    String? bodyType,
  }) {
    return [
      'full makeover fashion photography',
      'outfit: $outfitDescription',
      'hairstyle: $hairstyleDescription',
      if (makeupDescription != null) 'makeup: $makeupDescription',
      if (glassesDescription != null) 'glasses: $glassesDescription',
      if (bodyType != null) '$bodyType body type',
      'editorial fashion magazine, studio lighting',
      'full body portrait, photorealistic, 8k quality',
    ].join(', ');
  }
}
