import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/services/auth/auth_service.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _storage = LocalStorageService();
  final _auth = AuthService();

  List<StyleAnalysis> _analyses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final userId = _auth.currentUserId ?? 'guest';
      final analyses = await _storage.getStyleAnalyses(userId);
      if (mounted) {
        setState(() {
          _analyses = analyses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load history. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _openAnalysis(StyleAnalysis analysis) {
    Uint8List? bytes;
    final imageUrl = analysis.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        bytes = ImageUtils.dataUrlToBytes(imageUrl);
      } catch (_) {
        bytes = null;
      }
    }
    context.push('/analysis', extra: {
      'bytes': bytes,
      'name': 'history.jpg',
      'analysis': analysis,
    });
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppTheme.scoreExcellent;
    if (score >= 70) return AppTheme.scoreGood;
    if (score >= 55) return AppTheme.scoreOk;
    return AppTheme.scorePoor;
  }

  String _formattedDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'My Looks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.darkBorder),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryMain),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _isLoading = true; _error = null; });
                _loadHistory();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMain),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analyses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppTheme.primaryMain,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _analyses.length,
        itemBuilder: (context, index) {
          return _HistoryCard(
            analysis: _analyses[index],
            scoreColor: _scoreColor(_analyses[index].overallScore),
            formattedDate: _formattedDate(_analyses[index].analyzedAt),
            onTap: () => _openAnalysis(_analyses[index]),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 60));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.purpleToTealGradient,
            ),
            child: const Icon(Icons.style, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No looks yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyse your first outfit to\nbuild your style history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Analyse an Outfit'),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StyleAnalysis analysis;
  final Color scoreColor;
  final String formattedDate;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.analysis,
    required this.scoreColor,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = analysis.imageUrl;
    Uint8List? bytes;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        bytes = ImageUtils.dataUrlToBytes(imageUrl);
      } catch (_) {
        bytes = null;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: bytes != null
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : Container(
                        color: AppTheme.darkCardLight,
                        child: const Icon(Icons.style, color: Colors.white30, size: 36),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.headline.isNotEmpty
                          ? analysis.headline
                          : 'Style Analysis',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (analysis.detectedItems.isNotEmpty)
                      Text(
                        analysis.detectedItems.take(3).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
            // Score badge
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${analysis.overallScore.round()}',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'score',
                    style: TextStyle(color: scoreColor.withValues(alpha: 0.7), fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
