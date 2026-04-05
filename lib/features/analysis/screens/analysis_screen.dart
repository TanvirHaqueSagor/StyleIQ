import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/photo_preview.dart';
import 'package:styleiq/core/widgets/screen_app_bar.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/features/analysis/widgets/dark_score_card_widget.dart';
import 'package:styleiq/services/api/claude_api_service.dart';
import 'package:styleiq/services/api/image_generation_service.dart';

/// Analysis screen — accepts raw image bytes (new analysis) or a pre-computed
/// [existingAnalysis] (history replay). On history replay the AI call is skipped.
class AnalysisScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String imageName;

  /// When non-null the screen shows this result immediately without calling AI.
  final StyleAnalysis? existingAnalysis;

  const AnalysisScreen({
    super.key,
    required this.imageBytes,
    required this.imageName,
    this.existingAnalysis,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late AnalysisService _analysisService;
  StyleAnalysis? _analysis;
  String? _error;
  String? _technicalError;
  bool _isLoading = true;

  static const List<String> _loadingMessages = [
    'Stage 1/5: Scanning your outfit...',
    'Stage 2/5: Diagnosing color and fit...',
    'Stage 3/5: Planning the strongest changes...',
    'Stage 4/5: Preparing recommendation variants...',
    'Stage 5/5: Building your interactive result...',
  ];
  final ValueNotifier<int> _messageIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _analysisService = AnalysisService();
    if (widget.existingAnalysis != null) {
      // History replay — show stored result immediately, no API call needed
      _analysis = widget.existingAnalysis;
      _isLoading = false;
    } else {
      _analyzeOutfit();
      _startMessageRotation();
    }
  }

  @override
  void dispose() {
    _messageIndex.dispose();
    super.dispose();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        _messageIndex.value =
            (_messageIndex.value + 1) % _loadingMessages.length;
        _startMessageRotation();
      }
    });
  }

  Future<void> _analyzeOutfit() async {
    try {
      final analysis = await _analysisService.analyzeOutfit(
        widget.imageBytes,
        widget.imageName,
        AppUserService.currentUserId,
      );
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } on ClaudeApiException catch (e) {
      final detail = [
        e.message,
        if (e.code != null) 'Code: ${e.code}',
        if (e.originalError != null) 'Detail: ${e.originalError}',
      ].join('\n');
      debugPrint('=== CLAUDE API ERROR ===\n$detail');
      if (mounted) {
        setState(() {
          _error =
              'We could not analyze this photo right now. Try another clear outfit photo or retry in a moment.';
          _technicalError = detail;
          _isLoading = false;
        });
      }
    } on ImageGenerationException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not generate style preview. Please try again.';
          _technicalError = e.toString();
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      final detail = 'Error: $e\n\nStack:\n$stack';
      debugPrint('=== ANALYSIS ERROR ===\n$detail');
      if (mounted) {
        setState(() {
          _error =
              'Something went wrong while generating your style result. Please retry.';
          _technicalError = detail;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _analysis != null ? const Color(0xFF0a0a0f) : null,
      appBar: const ScreenAppBar(title: 'Style Analysis'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_analysis != null) return _buildSuccessState();
    return const Center(child: Text('No data available'));
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        PhotoPreview(bytes: widget.imageBytes),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                ValueListenableBuilder<int>(
                  valueListenable: _messageIndex,
                  builder: (_, idx, __) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _loadingMessages[idx],
                      key: ValueKey<int>(idx),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 12),
          Text('Analysis Failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F5FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppTheme.darkGrey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          if (kDebugMode && _technicalError != null) ...[
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _technicalError!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                      _analysis = null;
                    });
                    _analyzeOutfit();
                    _startMessageRotation();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMain,
                      foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DarkScoreCardWidget(
              analysis: _analysis!,
              imageBytes: widget.imageBytes,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: const Color(0xFF0a0a0f),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/wardrobe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('Add to Wardrobe'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/hairstyles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMain,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Hairstyle'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
