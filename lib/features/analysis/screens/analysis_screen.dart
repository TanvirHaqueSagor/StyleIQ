import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/photo_preview.dart';
import 'package:styleiq/core/widgets/screen_app_bar.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/features/analysis/widgets/dark_score_card_widget.dart';
import 'package:styleiq/services/api/claude_api_service.dart';

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
  bool _isLoading = true;

  final List<String> _loadingMessages = [
    'Scanning your outfit...',
    'Analyzing color harmony...',
    'Checking fit & proportions...',
    'Evaluating style cohesion...',
    'Generating your score card...',
  ];
  int _currentMessageIndex = 0;

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

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  Future<void> _analyzeOutfit() async {
    try {
      final analysis = await _analysisService.analyzeOutfit(
        widget.imageBytes,
        widget.imageName,
        'guest',
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
      if (mounted) setState(() { _error = detail; _isLoading = false; });
    } catch (e, stack) {
      final detail = 'Error: $e\n\nStack:\n$stack';
      debugPrint('=== ANALYSIS ERROR ===\n$detail');
      if (mounted) setState(() { _error = detail; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _analysis != null ? const Color(0xFF0a0a0f) : null,
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _loadingMessages[_currentMessageIndex],
                    key: ValueKey<int>(_currentMessageIndex),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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
          // Scrollable error log
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _error ?? 'Unknown error',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
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
    return SingleChildScrollView(
      child: DarkScoreCardWidget(
        analysis: _analysis!,
        imageBytes: widget.imageBytes,
      ),
    );
  }
}
