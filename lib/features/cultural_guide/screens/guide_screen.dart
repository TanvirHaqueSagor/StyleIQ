import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';

// ── Per-culture metadata ──────────────────────────────────────────────────────
class _CultureMeta {
  final String flag;
  final String tagline;
  final List<Color> gradientColors;
  final IconData icon;

  const _CultureMeta({
    required this.flag,
    required this.tagline,
    required this.gradientColors,
    required this.icon,
  });
}

const _cultureMeta = <String, _CultureMeta>{
  'Bengali': _CultureMeta(
    flag: '🇧🇩',
    tagline: 'Rich weaves & vibrant sarees',
    gradientColors: [Color(0xFF006A4E), Color(0xFFF42A41)],
    icon: Icons.spa_outlined,
  ),
  'Indian': _CultureMeta(
    flag: '🇮🇳',
    tagline: 'Silk, embroidery & bold color',
    gradientColors: [Color(0xFFFF9933), Color(0xFF800080)],
    icon: Icons.auto_awesome_outlined,
  ),
  'Pakistani': _CultureMeta(
    flag: '🇵🇰',
    tagline: 'Intricate embroidery & grace',
    gradientColors: [Color(0xFF01411C), Color(0xFF2E8B57)],
    icon: Icons.star_outline_rounded,
  ),
  'Arabic': _CultureMeta(
    flag: '🕌',
    tagline: 'Modest elegance & luxury',
    gradientColors: [Color(0xFF8B6914), Color(0xFFC5A028)],
    icon: Icons.nights_stay_outlined,
  ),
  'Japanese': _CultureMeta(
    flag: '🇯🇵',
    tagline: 'Minimalist precision & kimono',
    gradientColors: [Color(0xFFBC002D), Color(0xFF6B1A2A)],
    icon: Icons.wb_sunny_outlined,
  ),
  'Korean': _CultureMeta(
    flag: '🇰🇷',
    tagline: 'Hanbok tradition meets K-style',
    gradientColors: [Color(0xFF003478), Color(0xFF5B8DD9)],
    icon: Icons.favorite_outline_rounded,
  ),
  'Nigerian': _CultureMeta(
    flag: '🇳🇬',
    tagline: 'Ankara prints & vibrant pride',
    gradientColors: [Color(0xFF008751), Color(0xFF2D6A4F)],
    icon: Icons.brightness_7_outlined,
  ),
  'Western': _CultureMeta(
    flag: '🏙️',
    tagline: 'Contemporary & diverse style',
    gradientColors: [Color(0xFF2C3E6B), Color(0xFF4A6FA5)],
    icon: Icons.checkroom_outlined,
  ),
  'Chinese': _CultureMeta(
    flag: '🇨🇳',
    tagline: 'Qipao tradition & red culture',
    gradientColors: [Color(0xFFDE2910), Color(0xFFAA1608)],
    icon: Icons.local_fire_department_outlined,
  ),
  'Ethiopian': _CultureMeta(
    flag: '🇪🇹',
    tagline: 'Habesha kemis & heritage',
    gradientColors: [Color(0xFF078930), Color(0xFFFFCC00)],
    icon: Icons.landscape_outlined,
  ),
};

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final _analysisService = AnalysisService();
  final _searchController = TextEditingController();

  String? _selectedCulture;
  String? _selectedOccasion;
  Map<String, dynamic>? _guidance;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortOrder = 'default'; // 'default' | 'az' | 'za' | 'occasions'

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
        break;
      case 'za':
        list.sort((a, b) => b.compareTo(a));
        break;
      case 'occasions':
        list.sort((a, b) {
          final aCount = AppConstants.culturalOccasions[a]?.length ?? 0;
          final bCount = AppConstants.culturalOccasions[b]?.length ?? 0;
          return bCount.compareTo(aCount);
        });
        break;
      default:
        break;
    }
    return list;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Sort Cultures',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const Divider(),
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
    });
    try {
      final result = await _analysisService.getCulturalGuidance(
        _selectedCulture!,
        _selectedOccasion!,
      );
      if (mounted) {
        setState(() {
          _guidance = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
      backgroundColor: AppTheme.scaffoldBg,
      body: _selectedOccasion != null
          ? _buildGuidanceView()
          : _selectedCulture != null
              ? _buildOccasionView()
              : _buildDiscoveryView(),
    );
  }

  // ── Discovery view (culture grid) ─────────────────────────────────────────
  Widget _buildDiscoveryView() {
    return CustomScrollView(
      slivers: [
        // ── Clean pinned app bar — title only, no FlexibleSpaceBar duplication ──
        SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF2D1B6B),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Cultural Dress Codes',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _showSortSheet(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
              decoration: InputDecoration(
                hintText: 'Search a culture…',
                hintStyle: const TextStyle(color: AppTheme.mediumGrey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.mediumGrey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.mediumGrey, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
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
                      const Text('🔍',
                          style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'No results for "$_searchQuery"',
                        style: const TextStyle(
                            color: AppTheme.mediumGrey, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _buildCultureCard(
                        _filteredCultures[i], i),
                    childCount: _filteredCultures.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCultureCard(String culture, int index) {
    final meta = _cultureMeta[culture];
    final occasions =
        AppConstants.culturalOccasions[culture]?.length ?? 0;
    final colors = meta?.gradientColors ??
        [AppTheme.primaryMain, AppTheme.accentMain];

    return GestureDetector(
      onTap: () => setState(() => _selectedCulture = culture),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative circle
            Positioned(
              right: -18,
              top: -18,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              left: -10,
              bottom: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag emoji
                  Text(
                    meta?.flag ?? '🌍',
                    style: const TextStyle(fontSize: 36),
                  ),
                  const Spacer(),
                  // Culture name
                  Text(
                    culture,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Tagline
                  Text(
                    meta?.tagline ?? 'Explore dress codes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Occasion count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$occasions occasions',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  // ── Occasion view ─────────────────────────────────────────────────────────
  Widget _buildOccasionView() {
    final meta = _cultureMeta[_selectedCulture];
    final occasions =
        AppConstants.culturalOccasions[_selectedCulture] ?? [];
    final colors = meta?.gradientColors ??
        [AppTheme.primaryMain, AppTheme.accentMain];
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Hero header for selected culture
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                ],
              ),
              const SizedBox(height: 16),
              Text(
                meta?.flag ?? '🌍',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCulture!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta?.tagline ?? 'Explore dress codes',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Occasion list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: occasions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final occasion = occasions[i];
              final occasionIcons = {
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.first.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon,
                            color: colors.first, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          occasion,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.dark,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: colors.first.withValues(alpha: 0.60)),
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

  // ── Guidance view ─────────────────────────────────────────────────────────
  Widget _buildGuidanceView() {
    final meta = _cultureMeta[_selectedCulture];
    final colors = meta?.gradientColors ??
        [AppTheme.primaryMain, AppTheme.accentMain];
    final topPad = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // Compact header
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Column(
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(meta?.flag ?? '🌍',
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCulture!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _selectedOccasion!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                          color: colors.first, strokeWidth: 2),
                      const SizedBox(height: 16),
                      Text(
                        'Analysing dress codes…',
                        style: TextStyle(
                            color: colors.first,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : _guidance == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_guidance!['dress_code_summary'] is String)
                            _section(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Summary',
                              accentColor: colors.first,
                              child: Text(
                                _guidance!['dress_code_summary'] as String,
                                style: const TextStyle(
                                    fontSize: 14, height: 1.5,
                                    color: AppTheme.darkGrey),
                              ),
                            ),
                          if (_guidance!['appropriate_garments'] is List)
                            _section(
                              icon: Icons.checkroom_rounded,
                              title: 'Appropriate Garments',
                              accentColor: AppTheme.accentMain,
                              child: _bulletList(
                                  (_guidance!['appropriate_garments'] as List)
                                      .whereType<String>().toList(),
                                  dotColor: AppTheme.accentMain),
                            ),
                          if (_guidance!['color_guidance'] is List)
                            _section(
                              icon: Icons.palette_rounded,
                              title: 'Color Guidance',
                              accentColor: AppTheme.amber,
                              child: _colorGuidance(
                                  (_guidance!['color_guidance'] as List)
                                      .whereType<Map<String, dynamic>>().toList()),
                            ),
                          if (_guidance!['accessory_rules'] is List)
                            _section(
                              icon: Icons.watch_rounded,
                              title: 'Accessory Rules',
                              accentColor: AppTheme.primaryDark,
                              child: _bulletList(
                                  (_guidance!['accessory_rules'] as List)
                                      .whereType<String>().toList()),
                            ),
                          if (_guidance!['faux_pas'] is List)
                            _section(
                              icon: Icons.warning_amber_rounded,
                              title: 'Faux Pas to Avoid',
                              accentColor: AppTheme.coral,
                              child: _bulletList(
                                  (_guidance!['faux_pas'] as List)
                                      .whereType<String>().toList(),
                                  dotColor: AppTheme.coral),
                            ),
                          if (_guidance!['fusion_tips'] is List)
                            _section(
                              icon: Icons.lightbulb_rounded,
                              title: 'Modern Fusion Tips',
                              accentColor: AppTheme.accentMain,
                              child: _bulletList(
                                  (_guidance!['fusion_tips'] as List)
                                      .whereType<String>().toList()),
                            ),
                          if (_guidance!['regional_notes'] is String &&
                              (_guidance!['regional_notes'] as String)
                                  .isNotEmpty)
                            _section(
                              icon: Icons.map_outlined,
                              title: 'Regional Notes',
                              accentColor: AppTheme.mediumGrey,
                              child: Text(
                                _guidance!['regional_notes'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.darkGrey,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accentColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _bulletList(List<String> items, {Color? dotColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 10),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor ?? AppTheme.accentMain,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(item,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5,
                      color: AppTheme.darkGrey)),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _colorGuidance(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        final appropriateness =
            item['appropriateness'] as String? ?? 'neutral';
        final dotColor = switch (appropriateness) {
          'encouraged' => AppTheme.accentMain,
          'avoid' => AppTheme.coral,
          _ => AppTheme.amber,
        };
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppTheme.darkGrey),
                    children: [
                      TextSpan(
                        text: '${item['color']}: ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.dark),
                      ),
                      TextSpan(text: item['meaning'] as String? ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      trailing: selected ? const Icon(Icons.check_rounded, color: AppTheme.primaryMain) : null,
      onTap: () => onSelect(value),
    );
  }
}
