import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/services/api/image_generation_service.dart';

// ── Per-culture metadata ──────────────────────────────────────────────────────
class _CultureMeta {
  final String flag;
  final String tagline;
  final List<Color> gradientColors;
  final IconData icon;
  final List<String> visualEmojis; // emoji strip shown in the occasion header
  final _PatternType patternType;

  const _CultureMeta({
    required this.flag,
    required this.tagline,
    required this.gradientColors,
    required this.icon,
    required this.visualEmojis,
    this.patternType = _PatternType.circles,
  });
}

enum _PatternType { circles, diamonds, waves, hexagons, stars, stripes }

const _cultureMeta = <String, _CultureMeta>{
  'Bengali': _CultureMeta(
    flag: '🇧🇩',
    tagline: 'Rich weaves & vibrant sarees',
    gradientColors: [Color(0xFF006A4E), Color(0xFFF42A41)],
    icon: Icons.spa_outlined,
    visualEmojis: ['🥻', '🌺', '💎', '🌿', '🎨'],
    patternType: _PatternType.waves,
  ),
  'Indian': _CultureMeta(
    flag: '🇮🇳',
    tagline: 'Silk, embroidery & bold color',
    gradientColors: [Color(0xFFFF9933), Color(0xFF800080)],
    icon: Icons.auto_awesome_outlined,
    visualEmojis: ['🥻', '💍', '🌸', '✨', '👘'],
    patternType: _PatternType.stars,
  ),
  'Pakistani': _CultureMeta(
    flag: '🇵🇰',
    tagline: 'Intricate embroidery & grace',
    gradientColors: [Color(0xFF01411C), Color(0xFF2E8B57)],
    icon: Icons.star_outline_rounded,
    visualEmojis: ['👘', '🌙', '⭐', '🪡', '💫'],
    patternType: _PatternType.hexagons,
  ),
  'Arabic': _CultureMeta(
    flag: '🕌',
    tagline: 'Modest elegance & luxury',
    gradientColors: [Color(0xFF8B6914), Color(0xFFC5A028)],
    icon: Icons.nights_stay_outlined,
    visualEmojis: ['🧕', '🌙', '⭐', '🏺', '💛'],
    patternType: _PatternType.diamonds,
  ),
  'Japanese': _CultureMeta(
    flag: '🇯🇵',
    tagline: 'Minimalist precision & kimono',
    gradientColors: [Color(0xFFBC002D), Color(0xFF6B1A2A)],
    icon: Icons.wb_sunny_outlined,
    visualEmojis: ['👘', '🌸', '⛩️', '🍵', '🌿'],
    patternType: _PatternType.waves,
  ),
  'Korean': _CultureMeta(
    flag: '🇰🇷',
    tagline: 'Hanbok tradition meets K-style',
    gradientColors: [Color(0xFF003478), Color(0xFF5B8DD9)],
    icon: Icons.favorite_outline_rounded,
    visualEmojis: ['👘', '🎋', '🌺', '💙', '🏮'],
    patternType: _PatternType.circles,
  ),
  'Nigerian': _CultureMeta(
    flag: '🇳🇬',
    tagline: 'Ankara prints & vibrant pride',
    gradientColors: [Color(0xFF008751), Color(0xFF2D6A4F)],
    icon: Icons.brightness_7_outlined,
    visualEmojis: ['👔', '🌍', '🟢', '🎨', '👑'],
    patternType: _PatternType.hexagons,
  ),
  'Western': _CultureMeta(
    flag: '🏙️',
    tagline: 'Contemporary & diverse style',
    gradientColors: [Color(0xFF2C3E6B), Color(0xFF4A6FA5)],
    icon: Icons.checkroom_outlined,
    visualEmojis: ['👔', '👗', '🧥', '👟', '💼'],
    patternType: _PatternType.stripes,
  ),
  'Chinese': _CultureMeta(
    flag: '🇨🇳',
    tagline: 'Qipao tradition & red culture',
    gradientColors: [Color(0xFFDE2910), Color(0xFFAA1608)],
    icon: Icons.local_fire_department_outlined,
    visualEmojis: ['👗', '🏮', '🔴', '🐉', '✨'],
    patternType: _PatternType.stars,
  ),
  'Ethiopian': _CultureMeta(
    flag: '🇪🇹',
    tagline: 'Habesha kemis & heritage',
    gradientColors: [Color(0xFF078930), Color(0xFFFFCC00)],
    icon: Icons.landscape_outlined,
    visualEmojis: ['👗', '🌾', '🟡', '🌿', '🦁'],
    patternType: _PatternType.stripes,
  ),
};

// ── Color name → swatch color mapping ────────────────────────────────────────
const _colorSwatches = <String, Color>{
  'white': Color(0xFFF5F5F5),
  'black': Color(0xFF1A1A1A),
  'red': Color(0xFFE53935),
  'crimson': Color(0xFFB71C1C),
  'scarlet': Color(0xFFC62828),
  'maroon': Color(0xFF6D1C1C),
  'green': Color(0xFF43A047),
  'emerald': Color(0xFF00897B),
  'olive': Color(0xFF827717),
  'forest': Color(0xFF1B5E20),
  'blue': Color(0xFF1E88E5),
  'navy': Color(0xFF1A237E),
  'royal blue': Color(0xFF1565C0),
  'sky blue': Color(0xFF0288D1),
  'turquoise': Color(0xFF00ACC1),
  'gold': Color(0xFFFFB300),
  'golden': Color(0xFFFFB300),
  'yellow': Color(0xFFFDD835),
  'saffron': Color(0xFFFF6F00),
  'amber': Color(0xFFFFB300),
  'orange': Color(0xFFFB8C00),
  'purple': Color(0xFF8E24AA),
  'violet': Color(0xFF7B1FA2),
  'indigo': Color(0xFF3949AB),
  'pink': Color(0xFFE91E63),
  'rose': Color(0xFFF06292),
  'peach': Color(0xFFFF8A65),
  'silver': Color(0xFF9E9E9E),
  'grey': Color(0xFF757575),
  'gray': Color(0xFF757575),
  'brown': Color(0xFF6D4C41),
  'beige': Color(0xFFF5F0E8),
  'cream': Color(0xFFFFF8E1),
  'ivory': Color(0xFFFFF9F0),
  'teal': Color(0xFF00897B),
  'cyan': Color(0xFF00BCD4),
  'coral': Color(0xFFFF5252),
};

// ── Garment → emoji mapping ───────────────────────────────────────────────────
const _garmentEmoji = <String, String>{
  'saree': '🥻',  'sari': '🥻',   'lehenga': '👗',  'salwar': '👘',
  'kurta': '👕',  'sherwani': '🎩', 'tuxedo': '🤵',  'suit': '💼',
  'dress': '👗',  'gown': '👗',    'kimono': '👘',   'yukata': '👘',
  'hanbok': '👘', 'qipao': '👗',   'cheongsam': '👗','thobe': '👘',
  'abaya': '🧕',  'hijab': '🧕',   'dupatta': '🧣',  'agbada': '👘',
  'ankara': '👔', 'kaftan': '👘',  'jalabiya': '👘', 'habesha': '👗',
  'netela': '🧣', 'shirt': '👕',   'blouse': '👚',   'pants': '👖',
  'skirt': '🩱',  'jacket': '🧥',  'coat': '🧥',     'shoes': '👟',
  'heels': '👠',  'sandals': '👡', 'boots': '👢',    'scarf': '🧣',
  'veil': '🧕',   'headscarf': '🧕','jewelry': '💍', 'necklace': '📿',
  'bangles': '📿','turban': '🎩',  'cap': '🧢',      'hat': '🎩',
};

// ── Pattern painter ───────────────────────────────────────────────────────────
class _PatternPainter extends CustomPainter {
  final _PatternType type;
  final Color color;
  final double opacity;

  const _PatternPainter({required this.type, required this.color, this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    switch (type) {
      case _PatternType.circles:
        _drawCircles(canvas, size, paint);
      case _PatternType.diamonds:
        _drawDiamonds(canvas, size, paint);
      case _PatternType.waves:
        _drawWaves(canvas, size, paint);
      case _PatternType.hexagons:
        _drawHexagons(canvas, size, paint);
      case _PatternType.stars:
        _drawStars(canvas, size, paint);
      case _PatternType.stripes:
        _drawStripes(canvas, size, paint);
    }
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint) {
    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 6, paint);
      }
    }
  }

  void _drawDiamonds(Canvas canvas, Size size, Paint paint) {
    const spacing = 36.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y - 8)
          ..lineTo(x + 8, y)
          ..lineTo(x, y + 8)
          ..lineTo(x - 8, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    const amplitude = 6.0;
    const period = 40.0;
    final strokePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (double y = 10; y < size.height; y += 18) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x++) {
        path.lineTo(x, y + amplitude * math.sin((x / period) * 2 * math.pi));
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint) {
    const r = 14.0;
    const hx = r * 1.732;
    const hy = r * 1.5;
    for (double row = 0; row * hy < size.height + r; row++) {
      final offsetX = (row % 2 == 0) ? 0.0 : hx / 2;
      for (double col = 0; col * hx < size.width + r; col++) {
        final cx = col * hx + offsetX;
        final cy = row * hy;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (math.pi / 180) * (60 * i - 30);
          final px = cx + r * 0.7 * math.cos(angle);
          final py = cy + r * 0.7 * math.sin(angle);
          if (i == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
        }
        path.close();
        canvas.drawPath(path, paint..style = PaintingStyle.stroke..strokeWidth = 1);
      }
    }
  }

  void _drawStars(Canvas canvas, Size size, Paint paint) {
    const spacing = 44.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), 7, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (math.pi / 180) * (72 * i - 90);
      final innerAngle = outerAngle + math.pi / 5;
      final ox = center.dx + r * math.cos(outerAngle);
      final oy = center.dy + r * math.sin(outerAngle);
      final ix = center.dx + (r * 0.4) * math.cos(innerAngle);
      final iy = center.dy + (r * 0.4) * math.sin(innerAngle);
      if (i == 0) { path.moveTo(ox, oy); } else { path.lineTo(ox, oy); }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawStripes(Canvas canvas, Size size, Paint paint) {
    const spacing = 24.0;
    for (double y = 0; y < size.height + spacing; y += spacing) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 3), paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.type != type || old.color != color || old.opacity != opacity;
}

// ══════════════════════════════════════════════════════════════════════════════
// GuideScreen
// ══════════════════════════════════════════════════════════════════════════════
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _analysisService = AnalysisService();
  final _imageService = ImageGenerationService();
  final _searchController = TextEditingController();

  String? _selectedCulture;
  String? _selectedOccasion;
  Map<String, dynamic>? _guidance;
  bool _isLoading = false;
  String? _generatedImageUrl;
  bool _isGeneratingImage = false;
  String _searchQuery = '';
  String _sortOrder = 'default';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredCultures {
    var list = _searchQuery.isEmpty
        ? List<String>.from(AppConstants.cultures)
        : AppConstants.cultures
            .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
    switch (_sortOrder) {
      case 'az':
        list.sort();
      case 'za':
        list.sort((a, b) => b.compareTo(a));
      case 'occasions':
        list.sort((a, b) {
          final aCount = AppConstants.culturalOccasions[a]?.length ?? 0;
          final bCount = AppConstants.culturalOccasions[b]?.length ?? 0;
          return bCount.compareTo(aCount);
        });
    }
    return list;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.darkCard,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text('Sort Cultures',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const Divider(color: AppTheme.darkBorder),
            _SortTile('Default order', 'default', _sortOrder, (v) { setState(() => _sortOrder = v); Navigator.pop(context); }),
            _SortTile('A → Z', 'az', _sortOrder, (v) { setState(() => _sortOrder = v); Navigator.pop(context); }),
            _SortTile('Z → A', 'za', _sortOrder, (v) { setState(() => _sortOrder = v); Navigator.pop(context); }),
            _SortTile('Most occasions', 'occasions', _sortOrder, (v) { setState(() => _sortOrder = v); Navigator.pop(context); }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchGuidance() async {
    setState(() {
      _isLoading = true;
      _guidance = null;
      _generatedImageUrl = null;
      _isGeneratingImage = _imageService.isAvailable;
    });
    // Fire image generation in parallel — doesn't block guidance text
    if (_imageService.isAvailable) _generateCulturalImage();
    try {
      final result = await _analysisService.getCulturalGuidance(
          _selectedCulture!, _selectedOccasion!);
      if (mounted) setState(() { _guidance = result; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateCulturalImage() async {
    try {
      final image = await _imageService.generateOutfitPreview(
        outfitDescription:
            'traditional $_selectedCulture $_selectedOccasion outfit, '
            'authentic cultural dress, respectful fashion photography, '
            'vibrant colors, editorial quality',
        occasion: _selectedOccasion,
      );
      if (mounted) {
        setState(() {
          _generatedImageUrl = image.url;
          _isGeneratingImage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  void _goBack() {
    setState(() {
      if (_selectedOccasion != null) {
        _selectedOccasion = null;
        _guidance = null;
      } else {
        _selectedCulture = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: _selectedOccasion != null
          ? _buildGuidanceView()
          : _selectedCulture != null
              ? _buildOccasionView()
              : _buildDiscoveryView(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Discovery view — culture grid
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDiscoveryView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF2D1B6B),
          surfaceTintColor: Colors.transparent,
          title: const Text('Cultural Dress Codes',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 18, letterSpacing: -0.2)),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showSortSheet(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search a culture…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.4), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.4), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.darkCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.darkBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Subtitle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '${_filteredCultures.length} traditions • Tap to explore occasions',
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        ),

        // Grid
        _filteredCultures.isEmpty
            ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No results for "$_searchQuery"',
                          style: const TextStyle(color: AppTheme.mediumGrey, fontSize: 15)),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCultureCard(_filteredCultures[i], i),
                    childCount: _filteredCultures.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCultureCard(String culture, int index) {
    final meta     = _cultureMeta[culture];
    final occasions = AppConstants.culturalOccasions[culture]?.length ?? 0;
    final colors   = meta?.gradientColors ?? [AppTheme.primaryMain, AppTheme.accentMain];
    final pattern  = meta?.patternType ?? _PatternType.circles;

    return GestureDetector(
      onTap: () => setState(() => _selectedCulture = culture),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: colors.first.withValues(alpha: 0.35),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Stack(
          children: [
            // Cultural pattern background
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _PatternPainter(type: pattern, color: Colors.white, opacity: 0.07),
                ),
              ),
            ),
            // Decorative circles
            Positioned(right: -18, top: -18,
              child: Container(width: 80, height: 80,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08)))),
            Positioned(left: -10, bottom: -10,
              child: Container(width: 55, height: 55,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06)))),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meta?.flag ?? '🌍', style: const TextStyle(fontSize: 34)),
                  // Emoji strip
                  const SizedBox(height: 6),
                  if (meta != null)
                    Text(
                      meta.visualEmojis.take(3).join('  '),
                      style: const TextStyle(fontSize: 14),
                    ),
                  const Spacer(),
                  Text(culture,
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(meta?.tagline ?? 'Explore dress codes',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10.5, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$occasions occasions',
                            style: const TextStyle(color: Colors.white, fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.94, 0.94)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Occasion view
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildOccasionView() {
    final meta     = _cultureMeta[_selectedCulture];
    final occasions = AppConstants.culturalOccasions[_selectedCulture] ?? [];
    final colors   = meta?.gradientColors ?? [AppTheme.primaryMain, AppTheme.accentMain];
    final pattern  = meta?.patternType ?? _PatternType.circles;
    final topPad   = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Rich cultural header ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: Stack(
            children: [
              // Pattern painter
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(type: pattern, color: Colors.white, opacity: 0.06),
                ),
              ),
              // Decorative orb
              Positioned(right: -20, top: -20,
                child: Container(width: 130, height: 130,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07)))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Large flag
                  Text(meta?.flag ?? '🌍', style: const TextStyle(fontSize: 52))
                      .animate().scale(begin: const Offset(0.7, 0.7), duration: 400.ms,
                          curve: Curves.elasticOut),
                  const SizedBox(height: 8),
                  Text(_selectedCulture!,
                      style: const TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(meta?.tagline ?? '',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                  const SizedBox(height: 14),
                  // Emoji visual strip
                  if (meta != null)
                    Row(
                      children: meta.visualEmojis.map((emoji) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(emoji,
                            style: const TextStyle(fontSize: 20))),
                      )).toList(),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                ],
              ),
            ],
          ),
        ),

        // ── Occasion count & label ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppTheme.darkSurface,
          child: Row(
            children: [
              Icon(Icons.event_note_rounded, size: 14, color: colors.first),
              const SizedBox(width: 6),
              Text('${occasions.length} occasions — tap to get AI guidance',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.55))),
            ],
          ),
        ),

        // ── Occasion list ─────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: occasions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final occasion = occasions[i];
              final occasionIcons = <String, IconData>{
                'Wedding': Icons.favorite_rounded,
                'Eid': Icons.star_rounded,
                'Formal': Icons.business_center_outlined,
                'Festival': Icons.celebration_outlined,
                'Casual': Icons.weekend_outlined,
                'Party': Icons.local_bar_outlined,
                'Traditional': Icons.museum_outlined,
                'Business': Icons.work_outline_rounded,
              };
              final icon = occasionIcons[occasion] ?? Icons.event_outlined;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedOccasion = occasion);
                  _fetchGuidance();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.first.withValues(alpha: 0.25),
                              colors.last.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: colors.first, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(occasion,
                                style: const TextStyle(fontWeight: FontWeight.w700,
                                    fontSize: 15, color: Colors.white)),
                            Text('AI dress code guidance',
                                style: TextStyle(fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.4))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.first.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: colors.first),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 40 * i))
                  .fadeIn(duration: 250.ms)
                  .slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Guidance view — the detailed dress code content
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGuidanceView() {
    final meta   = _cultureMeta[_selectedCulture];
    final colors = meta?.gradientColors ?? [AppTheme.primaryMain, AppTheme.accentMain];
    final pattern = meta?.patternType ?? _PatternType.circles;
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // ── Compact cultural header ───────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PatternPainter(type: pattern, color: Colors.white, opacity: 0.06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(meta?.flag ?? '🌍', style: const TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedCulture!,
                                style: const TextStyle(color: Colors.white, fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            Text(_selectedOccasion!,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                          ],
                        ),
                      ),
                      // Visual emoji preview
                      if (meta != null)
                        Row(
                          children: meta.visualEmojis.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(e, style: const TextStyle(fontSize: 18)),
                          )).toList(),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? _buildLoadingState(colors)
              : _guidance == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI-generated cultural image
                          if (_isGeneratingImage || _generatedImageUrl != null)
                            _buildAiImageCard(colors)
                                .animate().fadeIn(duration: 400.ms).slideY(begin: 0.04),

                          // Summary
                          if (_guidance!['dress_code_summary'] is String)
                            _section(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Summary',
                              accentColor: colors.first,
                              child: Text(
                                _guidance!['dress_code_summary'] as String,
                                style: TextStyle(fontSize: 14, height: 1.6,
                                    color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

                          // Garments — visual emoji chips
                          if (_guidance!['appropriate_garments'] is List)
                            _section(
                              icon: Icons.checkroom_rounded,
                              title: 'Appropriate Garments',
                              accentColor: AppTheme.accentMain,
                              child: _garmentChips(
                                (_guidance!['appropriate_garments'] as List)
                                    .whereType<String>().toList()),
                            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                          // Colors — swatch chips
                          if (_guidance!['color_guidance'] is List)
                            _section(
                              icon: Icons.palette_rounded,
                              title: 'Color Palette',
                              accentColor: AppTheme.amber,
                              child: _colorSwatchSection(
                                (_guidance!['color_guidance'] as List)
                                    .whereType<Map<String, dynamic>>().toList()),
                            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

                          // Accessories
                          if (_guidance!['accessory_rules'] is List)
                            _section(
                              icon: Icons.diamond_outlined,
                              title: 'Accessories & Styling',
                              accentColor: AppTheme.primaryLight,
                              child: _iconBulletList(
                                (_guidance!['accessory_rules'] as List)
                                    .whereType<String>().toList(),
                                icon: Icons.star_rounded,
                                iconColor: AppTheme.primaryLight,
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                          // Faux Pas — red warning cards
                          if (_guidance!['faux_pas'] is List)
                            _fauxPasSection(
                              (_guidance!['faux_pas'] as List)
                                  .whereType<String>().toList(),
                            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                          // Fusion Tips — teal idea cards
                          if (_guidance!['fusion_tips'] is List)
                            _fusionSection(
                              (_guidance!['fusion_tips'] as List)
                                  .whereType<String>().toList(),
                            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                          // Regional Notes
                          if (_guidance!['regional_notes'] is String &&
                              (_guidance!['regional_notes'] as String).isNotEmpty)
                            _section(
                              icon: Icons.map_outlined,
                              title: 'Regional Notes',
                              accentColor: AppTheme.mediumGrey,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppTheme.darkBorder.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('🗺️', style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _guidance!['regional_notes'] as String,
                                        style: TextStyle(fontSize: 13, height: 1.55,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.white.withValues(alpha: 0.65)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  // ── AI-generated cultural image card ─────────────────────────────────────

  Widget _buildAiImageCard(List<Color> colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.first.withValues(alpha: 0.10),
              border: const Border(bottom: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, size: 15, color: colors.first),
                ),
                const SizedBox(width: 10),
                Text('AI Style Preview',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: colors.first, letterSpacing: 0.1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Generated by AI',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: colors.first.withValues(alpha: 0.85))),
                ),
              ],
            ),
          ),
          // Image area
          if (_isGeneratingImage)
            Container(
              height: 260,
              color: colors.first.withValues(alpha: 0.04),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [colors.first, colors.last]),
                      ),
                      child: const Icon(Icons.image_search_rounded,
                          color: Colors.white, size: 26),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1200.ms,
                            color: Colors.white.withValues(alpha: 0.35)),
                    const SizedBox(height: 14),
                    Text('Generating cultural image…',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.w600, color: colors.first)),
                    const SizedBox(height: 4),
                    Text('This may take a few seconds',
                        style: TextStyle(fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
              ),
            )
          else if (_generatedImageUrl != null)
            CachedNetworkImage(
              imageUrl: _generatedImageUrl!,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 280,
                color: colors.first.withValues(alpha: 0.06),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120,
                color: colors.first.withValues(alpha: 0.06),
                child: Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.white.withValues(alpha: 0.3), size: 36),
                ),
              ),
            ),
          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              '$_selectedCulture · $_selectedOccasion — AI-generated illustration for visual reference only.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.4), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated loading state ────────────────────────────────────────────────

  Widget _buildLoadingState(List<Color> colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated spinning culture symbol
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.first, colors.last],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3))
              .then()
              .scale(begin: const Offset(1, 1), end: const Offset(0.95, 0.95), duration: 700.ms)
              .then()
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 700.ms),
          const SizedBox(height: 20),
          Text('Consulting cultural archives…',
              style: TextStyle(color: colors.first, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 6),
          Text('Getting accurate dress code guidance',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
          const SizedBox(height: 24),
          // Animated dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => Container(
              width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: colors.first, shape: BoxShape.circle),
            ).animate(delay: Duration(milliseconds: 150 * i), onPlay: (c) => c.repeat())
              .fadeOut(duration: 500.ms).then().fadeIn(duration: 500.ms)),
          ),
        ],
      ),
    );
  }

  // ── Section wrapper ───────────────────────────────────────────────────────

  Widget _section({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: const Border(bottom: BorderSide(color: AppTheme.darkBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: accentColor),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: accentColor, letterSpacing: 0.1)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // ── Garment chips with emoji ──────────────────────────────────────────────

  Widget _garmentChips(List<String> garments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: garments.asMap().entries.map((e) {
        final idx   = e.key;
        final name  = e.value;
        final emoji = _emojiForGarment(name);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.accentMain.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentMain.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
        ).animate(delay: Duration(milliseconds: 30 * idx)).fadeIn().scale(
            begin: const Offset(0.88, 0.88));
      }).toList(),
    );
  }

  String _emojiForGarment(String name) {
    final lower = name.toLowerCase();
    for (final entry in _garmentEmoji.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return '👗';
  }

  // ── Color swatches ────────────────────────────────────────────────────────

  Widget _colorSwatchSection(List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Swatch row
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: items.map((item) {
              final colorName    = (item['color'] as String? ?? '').toLowerCase();
              final swatch       = _swatchFor(colorName);
              final appropriate  = item['appropriateness'] as String? ?? 'neutral';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: appropriate == 'avoid'
                              ? AppTheme.coral
                              : appropriate == 'encouraged'
                                  ? AppTheme.accentMain
                                  : AppTheme.darkBorder,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(color: swatch.withValues(alpha: 0.4),
                              blurRadius: 6, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: appropriate == 'avoid'
                          ? const Icon(Icons.close_rounded, size: 14, color: Colors.white)
                          : appropriate == 'encouraged'
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        // Detail list
        ...items.asMap().entries.map((e) {
          final item          = e.value;
          final colorName     = (item['color'] as String? ?? '');
          final appropriate   = item['appropriateness'] as String? ?? 'neutral';
          final swatch        = _swatchFor(colorName.toLowerCase());
          final statusColor   = appropriate == 'encouraged'
              ? AppTheme.accentMain
              : appropriate == 'avoid'
                  ? AppTheme.coral
                  : AppTheme.amber;
          final statusIcon    = appropriate == 'encouraged'
              ? '✓' : appropriate == 'avoid' ? '✗' : '~';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: swatch, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 22, height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(statusIcon, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: statusColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, height: 1.45,
                          color: Colors.white.withValues(alpha: 0.75)),
                      children: [
                        TextSpan(text: '$colorName: ',
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        TextSpan(text: item['meaning'] as String? ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _swatchFor(String name) {
    for (final entry in _colorSwatches.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    return AppTheme.mediumGrey;
  }

  // ── Icon bullet list (accessories) ────────────────────────────────────────

  Widget _iconBulletList(List<String> items,
      {required IconData icon, required Color iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 10),
              width: 20, height: 20,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 11, color: iconColor),
            ),
            Expanded(
              child: Text(e.value,
                  style: TextStyle(fontSize: 13, height: 1.5,
                      color: Colors.white.withValues(alpha: 0.75))),
            ),
          ],
        ),
      )).toList(),
    );
  }

  // ── Faux Pas section — styled warning cards ───────────────────────────────

  Widget _fauxPasSection(List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.coral.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.coral.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppTheme.coral.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, size: 15, color: AppTheme.coral),
                ),
                const SizedBox(width: 10),
                const Text('Faux Pas to Avoid',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: AppTheme.coral)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.coral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length} to avoid',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.coral)),
                ),
              ],
            ),
          ),
          // Warning cards
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.coral.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.coral.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20, height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text('${e.key + 1}',
                          style: const TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w800, color: AppTheme.coral)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: TextStyle(fontSize: 13, height: 1.45,
                              color: Colors.white.withValues(alpha: 0.75))),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fusion Tips section — styled teal idea cards ──────────────────────────

  Widget _fusionSection(List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.accentMain.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.accentMain.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentMain.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: AppTheme.accentMain.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentMain.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, size: 15, color: AppTheme.accentMain),
                ),
                const SizedBox(width: 10),
                const Text('Modern Fusion Tips',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                        color: AppTheme.accentMain)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentMain.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${items.length} ideas',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: AppTheme.accentMain)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: items.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accentMain.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accentMain.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: TextStyle(fontSize: 13, height: 1.45,
                              color: Colors.white.withValues(alpha: 0.75))),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sort tile ─────────────────────────────────────────────────────────────────

class _SortTile extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onSelect;

  const _SortTile(this.label, this.value, this.current, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return ListTile(
      title: Text(label,
          style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              color: selected ? AppTheme.primaryLight : Colors.white)),
      trailing: selected
          ? const Icon(Icons.check_rounded, color: AppTheme.primaryMain)
          : null,
      onTap: () => onSelect(value),
    );
  }
}
