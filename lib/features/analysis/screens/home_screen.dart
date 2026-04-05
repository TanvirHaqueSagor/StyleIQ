import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/services/subscription_capability_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/core/widgets/animated_score_ring.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/models/subscription_plan.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _analysisService = AnalysisService();
  final _storageService = LocalStorageService();

  List<StyleAnalysis> _recentAnalyses = [];
  SubscriptionPlan _subscription = SubscriptionCapabilityService.freePlan();
  int _wardrobeCount = 0;

  // Image byte cache — decode base64 data URLs once, reuse on every rebuild
  final Map<String, Uint8List> _imageCache = {};

  late AnimationController _pulseCtrl;
  late AnimationController _heroCtrl;

  static const _tips = [
    {'title': 'Mix High & Low', 'body': 'Pair one premium statement piece with affordable basics. A great jacket elevates everything.', 'icon': '✨', 'color': Color(0xFF6C4FF0)},
    {'title': 'Rule of Three', 'body': 'Limit your outfit to three colors for a cohesive look. A fourth only as a small accent.', 'icon': '🎨', 'color': Color(0xFF00D4AA)},
    {'title': 'Fit is Everything', 'body': 'A well-fitted \$20 shirt beats an ill-fitting \$200 one. Tailoring is the real secret weapon.', 'icon': '📐', 'color': Color(0xFFFF4081)},
    {'title': 'Shoes Set the Tone', 'body': 'Your footwear communicates the formality of your look before you say a word.', 'icon': '👟', 'color': Color(0xFF536DFE)},
    {'title': 'One Statement Piece', 'body': 'Build around a single standout item — bold bag, printed blazer — then keep the rest neutral.', 'icon': '💫', 'color': Color(0xFFFFB547)},
    {'title': 'Dress One Level Up', 'body': 'Always dress slightly above the occasion\'s expectation. You\'ll be remembered.', 'icon': '🏆', 'color': Color(0xFF00D4AA)},
    {'title': 'Analogous Colors', 'body': 'Colors next to each other on the wheel (blue + teal + green) always look harmonious.', 'icon': '🌈', 'color': Color(0xFFFF4081)},
  ];

  Map<String, dynamic> get _todaysTip => _tips[DateTime.now().weekday - 1] as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _heroCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _heroCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userId = AppUserService.currentUserId;
    final analyses = await _analysisService.getAnalysisHistory(userId);
    final sub    = await _storageService.getSubscription(userId);
    final wardrobe = await _storageService.getWardrobeItems(userId);
    if (!mounted) return;
    setState(() {
      _recentAnalyses = analyses;
      _subscription   = sub;
      _wardrobeCount  = wardrobe.length;
    });
    _heroCtrl.forward();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  StyleAnalysis? get _latest => _recentAnalyses.isEmpty ? null : _recentAnalyses.first;

  /// Decode a base64 data-URL once and cache the result.
  /// Called from build — safe because it's O(1) on subsequent calls.
  Uint8List? _cachedBytes(String? url) {
    if (url == null || url.isEmpty) return null;
    return _imageCache.putIfAbsent(url, () => ImageUtils.dataUrlToBytes(url));
  }

  double? get _bestScore => _recentAnalyses.isEmpty
      ? null
      : _recentAnalyses.map((a) => a.overallScore).reduce((a, b) => a > b ? a : b);

  // ── Photo pick ─────────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    if (!kIsWeb && source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) _showSnack('Camera permission denied');
        return;
      }
    }
    final file = await _picker.pickImage(
      source: source, imageQuality: 85, maxWidth: 1200, maxHeight: 1600,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > ImageUtils.maxImageSizeBytes) {
      _showSnack('Image too large — please choose one under 2 MB');
      return;
    }
    if (!ImageUtils.isValidImageName(file.name)) {
      _showSnack('Unsupported format — use JPG, PNG or WEBP');
      return;
    }
    if (mounted) {
      context.push('/analysis', extra: {'bytes': bytes, 'name': file.name});
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  void _showPhotoSource() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppTheme.darkBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Analyse Your Outfit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Take a photo or choose from your gallery',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _sourceButton(Icons.camera_alt_rounded, 'Camera', ImageSource.camera, AppTheme.primaryMain)),
                const SizedBox(width: 12),
                Expanded(child: _sourceButton(Icons.photo_library_rounded, 'Gallery', ImageSource.gallery, AppTheme.accentMain)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(IconData icon, String label, ImageSource source, Color color) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); _pickPhoto(source); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                if (_latest != null) ...[
                  _buildLastAnalysisCard(),
                  const SizedBox(height: 20),
                ],
                _buildAnalyseCTA(),
                const SizedBox(height: 24),
                _buildStatsRow(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildDailyTip(),
                const SizedBox(height: 24),
                if (_recentAnalyses.length > 1) ...[
                  _buildHistorySection(),
                  const SizedBox(height: 24),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver header ──────────────────────────────────────────────────────────

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: AppTheme.darkBg,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1C1232), AppTheme.darkBg],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$_greeting 👋',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        const Text('StyleIQ',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.5)),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.1),
                  ),
                  // Subscription badge
                  _buildSubscriptionBadge(),
                  const SizedBox(width: 10),
                  // Notification icon
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge() {
    final isPro = _subscription.name == 'Style Pro' || _subscription.name == 'Family';
    final isPlus = _subscription.name == 'Style+';
    if (!isPro && !isPlus) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: isPro ? AppTheme.purpleToTealGradient : AppTheme.purpleGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPro ? '⭐ PRO' : '✦ PLUS',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  // ── Last analysis hero card ─────────────────────────────────────────────────

  Widget _buildLastAnalysisCard() {
    final a = _latest!;
    final score = a.overallScore;
    final color = AppTheme.getScoreColor(score);

    return GestureDetector(
      onTap: () {
        final bytes = _cachedBytes(a.imageUrl);
        if (bytes != null) {
          context.push('/analysis', extra: {'bytes': bytes, 'name': 'history.jpg', 'existing': a});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              AppTheme.darkCard,
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Stack(
          children: [
            // Glow orb
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Photo thumbnail
                  if (_cachedBytes(a.imageUrl) case final bytes?) ...[
                    Container(
                      width: 72, height: 88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(bytes, fit: BoxFit.cover,
                            cacheWidth: 144, cacheHeight: 176),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Latest Analysis',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: color, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 6),
                        Text(a.headline,
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: Colors.white, height: 1.3)),
                        const SizedBox(height: 6),
                        Text(a.aestheticCategory ?? a.letterGrade,
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Score ring
                  AnimatedScoreRing(score: score, grade: a.letterGrade, size: 72, strokeWidth: 6),
                ],
              ),
            ),
          ],
        ),
      ).animate(controller: _heroCtrl).fadeIn().slideY(begin: 0.06),
    );
  }

  // ── Analyse CTA ─────────────────────────────────────────────────────────────

  Widget _buildAnalyseCTA() {
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final pulse = 0.95 + 0.05 * _pulseCtrl.value;
        return Transform.scale(
          scale: pulse,
          child: GestureDetector(
            onTap: _showPhotoSource,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: AppTheme.purpleToTealGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMain.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Analyse My Outfit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text(
                          _latest == null
                              ? 'Get your AI style score in seconds'
                              : 'Score yours today — see what improved',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  // ── Stats row ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    final count  = _recentAnalyses.length;
    final best   = _bestScore;
    final weekly = _recentAnalyses.where((a) => DateTime.now().difference(a.analyzedAt).inDays < 7).length;

    return Row(
      children: [
        _statTile('$count', 'Analyses', Icons.auto_awesome_rounded, AppTheme.primaryMain),
        const SizedBox(width: 10),
        _statTile(best != null ? '${best.toInt()}' : '—', 'Best Score', Icons.emoji_events_rounded, AppTheme.amber),
        const SizedBox(width: 10),
        _statTile('$_wardrobeCount', 'Wardrobe', Icons.checkroom_rounded, AppTheme.accentMain),
        const SizedBox(width: 10),
        _statTile('$weekly', 'This Week', Icons.calendar_today_rounded, AppTheme.rose),
      ],
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _statTile(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.face_retouching_natural_rounded, 'label': 'Hairstyle', 'route': '/hairstyles',
       'gradient': [const Color(0xFF00D4AA), const Color(0xFF009E7E)]},
      {'icon': Icons.auto_fix_high_rounded, 'label': 'Makeover', 'route': '/makeover',
       'gradient': [const Color(0xFFFF4081), const Color(0xFFAD1457)]},
      {'icon': Icons.public_rounded, 'label': 'Dress Codes', 'route': '/guide',
       'gradient': [const Color(0xFFFFB547), const Color(0xFFE65100)]},
      {'icon': Icons.checkroom_rounded, 'label': 'Wardrobe', 'route': '/wardrobe',
       'gradient': [const Color(0xFF536DFE), const Color(0xFF3D5AFE)]},
      {'icon': Icons.videocam_rounded, 'label': 'Live Cam', 'route': '/live',
       'gradient': [const Color(0xFF6C4FF0), const Color(0xFF3D1FC8)]},
      {'icon': Icons.people_alt_rounded, 'label': 'Community', 'route': '/community',
       'gradient': [const Color(0xFF00B0FF), const Color(0xFF0091EA)]},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Explore',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            final grads = a['gradient'] as List<Color>;
            return GestureDetector(
              onTap: () => context.push(a['route'] as String),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [grads[0].withValues(alpha: 0.15), grads[1].withValues(alpha: 0.08)],
                  ),
                  border: Border.all(color: grads[0].withValues(alpha: 0.25)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: grads),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(a['icon'] as IconData, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(a['label'] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * i)).scale(begin: const Offset(0.9, 0.9)),
            );
          },
        ),
      ],
    );
  }

  // ── Daily tip ───────────────────────────────────────────────────────────────

  Widget _buildDailyTip() {
    final tip = _todaysTip;
    final color = tip['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.darkCard,
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(tip['icon'] as String, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Daily Tip',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: color, letterSpacing: 0.5)),
                    const Spacer(),
                    Text('Day ${DateTime.now().weekday}',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.3))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(tip['title'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(tip['body'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── History section ─────────────────────────────────────────────────────────

  Widget _buildHistorySection() {
    final shown = _recentAnalyses.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Looks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            GestureDetector(
              onTap: () => context.push('/history'),
              child: const Text('See all',
                style: TextStyle(fontSize: 13, color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _historyThumbnail(shown[i], i),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _historyThumbnail(StyleAnalysis a, int i) {
    final color = AppTheme.getScoreColor(a.overallScore);
    final bytes = _cachedBytes(a.imageUrl);

    return GestureDetector(
      onTap: () {
        if (bytes != null) {
          context.push('/analysis', extra: {'bytes': bytes, 'name': 'history.jpg', 'existing': a});
        }
      },
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.darkCard,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.memory(bytes, fit: BoxFit.cover,
                    cacheWidth: 200, cacheHeight: 260),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.checkroom_rounded, color: color.withValues(alpha: 0.4), size: 32),
              ),
            // Score badge
            Positioned(
              bottom: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${a.overallScore.toInt()}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: 50 * i)),
    );
  }
}
