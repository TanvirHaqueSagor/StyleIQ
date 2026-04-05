import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/services/api/image_generation_service.dart';

/// Visual card that shows one AI recommendation with an optional
/// generated image preview. Calls FAL.ai when [autoGenerate] is true.
class RecommendationCard extends StatefulWidget {
  final Suggestion suggestion;
  final int index;
  final bool autoGenerate;
  final String? bodyType;
  final String? occasion;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.suggestion,
    required this.index,
    this.autoGenerate = false,
    this.bodyType,
    this.occasion,
    this.onTap,
  });

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  final _genService = ImageGenerationService();
  String? _imageUrl;
  bool _generating = false;
  bool _failed = false;

  static const _icons = ['✨', '🎨', '👗', '👠', '💼', '🌟'];
  static const _gradients = [
    [Color(0xFF6C4FF0), Color(0xFF9B7FFF)],
    [Color(0xFF00D4AA), Color(0xFF009E7E)],
    [Color(0xFFFF4081), Color(0xFFFF80AB)],
    [Color(0xFF536DFE), Color(0xFF82B1FF)],
    [Color(0xFFFFB547), Color(0xFFFFD080)],
    [Color(0xFF6C4FF0), Color(0xFF00D4AA)],
  ];

  List<Color> get _gradient =>
      _gradients[widget.index % _gradients.length];

  @override
  void initState() {
    super.initState();
    if (widget.autoGenerate && _genService.isAvailable) {
      _generateImage();
    }
  }

  Future<void> _generateImage() async {
    if (_generating) return;
    setState(() { _generating = true; _failed = false; });
    try {
      final result = await _genService.generateOutfitPreview(
        outfitDescription: widget.suggestion.change,
        bodyType: widget.bodyType,
        occasion: widget.occasion,
      );
      if (mounted) setState(() { _imageUrl = result.url; });
    } catch (_) {
      if (mounted) setState(() { _failed = true; });
    } finally {
      if (mounted) setState(() { _generating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_gradient[0].withValues(alpha: 0.15), _gradient[1].withValues(alpha: 0.08)],
          ),
          border: Border.all(color: _gradient[0].withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview area
            if (widget.autoGenerate)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: _buildImageArea(),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _gradient),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _icons[widget.index % _icons.length],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Suggestion ${widget.index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _gradient[0],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (widget.autoGenerate && !_generating && !_failed && _imageUrl == null)
                        GestureDetector(
                          onTap: _generateImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _gradient),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Preview',
                                style: TextStyle(fontSize: 10, color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Change text
                  Text(
                    widget.suggestion.change,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Reason text
                  Text(
                    widget.suggestion.reason,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 80 * widget.index)).slideY(begin: 0.1),
    );
  }

  Widget _buildImageArea() {
    if (_generating) {
      return Container(
        height: 160,
        color: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _gradient[0],
              ),
            ),
            const SizedBox(height: 8),
            Text('Generating preview…',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      );
    }
    if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_gradient[0].withValues(alpha: 0.3), _gradient[1].withValues(alpha: 0.1)],
          ),
        ),
        child: Center(
          child: Icon(Icons.auto_awesome_rounded,
              color: _gradient[0].withValues(alpha: 0.5), size: 32),
        ),
      );
}

/// Quick-win chip — compact tag showing a fast styling win
class QuickWinChip extends StatelessWidget {
  final String text;
  final int index;

  const QuickWinChip({super.key, required this.text, required this.index});

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppTheme.primaryMain,
      AppTheme.accentMain,
      AppTheme.rose,
      AppTheme.indigo,
      AppTheme.amber,
    ];
    final color = colors[index % colors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 60 * index)).scale(begin: const Offset(0.8, 0.8));
  }
}

/// Before/After comparison widget using a drag slider
class BeforeAfterSlider extends StatefulWidget {
  final Uint8List beforeBytes;
  final String? afterUrl;
  final double height;

  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    this.afterUrl,
    this.height = 300,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          return GestureDetector(
            onHorizontalDragUpdate: (d) {
              setState(() {
                _split = (_split + d.delta.dx / w).clamp(0.05, 0.95);
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // After image (full width underneath)
                  if (widget.afterUrl != null)
                    Image.network(widget.afterUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryMain.withValues(alpha: 0.3),
                            AppTheme.accentMain.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Text('AI Preview\nComing Soon',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ),
                    ),

                  // Before image (clipped left)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _split,
                      child: Image.memory(widget.beforeBytes,
                          fit: BoxFit.cover, width: w, height: widget.height),
                    ),
                  ),

                  // Labels
                  Positioned(
                    left: 12, top: 12,
                    child: _label('BEFORE'),
                  ),
                  Positioned(
                    right: 12, top: 12,
                    child: _label('AFTER'),
                  ),

                  // Divider line + handle
                  Positioned(
                    left: w * _split - 1,
                    top: 0, bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Positioned(
                    left: w * _split - 18,
                    top: widget.height / 2 - 18,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.2))],
                      ),
                      child: const Icon(Icons.compare_arrows_rounded,
                          size: 20, color: AppTheme.primaryMain),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      );
}
