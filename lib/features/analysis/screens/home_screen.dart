import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/utils/image_utils.dart';
import 'package:styleiq/core/widgets/styleiq_logo.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _analysisService = AnalysisService();

  List<StyleAnalysis> _recentAnalyses = [];
  bool _loadingHistory = true;

  // ── Daily tips rotate by day of week ──────────────────────────────────────
  static const _tips = [
    {
      'title': 'Mix High & Low',
      'body':
          'Pair one premium statement piece with affordable basics. A great jacket elevates everything underneath it.',
      'icon': '✨',
    },
    {
      'title': 'The Rule of Three',
      'body':
          'Limit your outfit to three colors for a cohesive, polished look. Add a fourth only as a small accent.',
      'icon': '🎨',
    },
    {
      'title': 'Fit is Everything',
      'body':
          'A well-fitted \$20 shirt looks better than an ill-fitting \$200 one. Tailoring is the secret weapon.',
      'icon': '📐',
    },
    {
      'title': 'Shoes Set the Tone',
      'body':
          'Your footwear communicates the formality of your outfit before you say a word.',
      'icon': '👟',
    },
    {
      'title': 'One Statement Piece',
      'body':
          'Build around a single standout item — a bold bag, printed blazer, or statement shoe — then keep the rest neutral.',
      'icon': '💫',
    },
    {
      'title': 'Dress One Level Up',
      'body':
          'Always dress slightly above the occasion\'s expectation. You\'ll be remembered for the right reason.',
      'icon': '🏆',
    },
    {
      'title': 'Analogous Colors',
      'body':
          'Colors next to each other on the color wheel (e.g., blue + teal + green) always look harmonious together.',
      'icon': '🌈',
    },
  ];

  Map<String, dynamic> get _todaysTip => _tips[DateTime.now().weekday - 1];

  // ── Quick action tiles ────────────────────────────────────────────────────
  static const _actions = [
    {
      'icon': Icons.face_retouching_natural,
      'label': 'Hairstyle',
      'route': '/hairstyles',
      'color': AppTheme.accentMain,
      'bg': Color(0xFFE8F8F2),
    },
    {
      'icon': Icons.public,
      'label': 'Dress Codes',
      'route': '/guide',
      'color': AppTheme.amber,
      'bg': Color(0xFFFFF8E8),
    },
    {
      'icon': Icons.checkroom,
      'label': 'Wardrobe',
      'route': '/wardrobe',
      'color': AppTheme.primaryMain,
      'bg': Color(0xFFF0EEFF),
    },
    {
      'icon': Icons.auto_fix_high,
      'label': 'Community',
      'route': '/community',
      'color': AppTheme.coral,
      'bg': Color(0xFFFFF0EC),
    },
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final hour = DateTime.now().hour;
    if (hour < 12) return '👋';
    if (hour < 17) return '☀️';
    return '🌙';
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Shows a confirmation dialog. Returns true if user confirms, false otherwise.
  Future<bool> _confirmDelete(StyleAnalysis analysis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: const Text('Delete Analysis?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Remove "${analysis.headline}" from your history? This cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteAnalysis(StyleAnalysis analysis) async {
    await _analysisService.deleteAnalysis(analysis, 'guest');
    if (mounted) {
      setState(() => _recentAnalyses.removeWhere(
          (a) => a.analyzedAt == analysis.analyzedAt));
    }
  }

  Future<void> _loadHistory() async {
    try {
      final analyses = await _analysisService.getAnalysisHistory('guest');
      if (mounted) {
        setState(() {
          _recentAnalyses = analyses;
          _loadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load recent analyses')),
        );
      }
    }
  }

  // ── Image picker ──────────────────────────────────────────────────────────
  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Choose Photo',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select how to get your outfit photo',
                  style: TextStyle(fontSize: 13, color: AppTheme.mediumGrey),
                ),
                const SizedBox(height: 20),
                _PickerOption(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppTheme.primaryMain,
                  iconBg: const Color(0xFFF0EEFF),
                  title: 'Take a Photo',
                  subtitle: 'Use your camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pick(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
                _PickerOption(
                  icon: Icons.photo_library_rounded,
                  iconColor: AppTheme.accentMain,
                  iconBg: const Color(0xFFE8F8F2),
                  title: 'Choose from Gallery',
                  subtitle: 'Pick an existing photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pick(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    if (_recentAnalyses.length >= AppConstants.freeTierAnalysesPerMonth) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          title: const Text('Free Limit Reached',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'You\'ve used all 3 free analyses this month.\n\nUpgrade to Style+ for 30 analyses/month.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMain,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)))),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      return;
    }

    if (!kIsWeb) {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required'),
              action: SnackBarAction(
                  label: 'Settings', onPressed: openAppSettings),
            ),
          );
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted && !status.isLimited && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo library permission is required'),
              action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
            ),
          );
          return;
        }
      }
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        context.push('/analysis', extra: {'bytes': bytes, 'name': file.name});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _showAllAnalyses(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('All Analyses',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _recentAnalyses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx2, i) {
                  final a = _recentAnalyses[i];
                  return Dismissible(
                    key: ValueKey(a.analyzedAt),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 24),
                    ),
                    confirmDismiss: (_) => _confirmDelete(a),
                    onDismissed: (_) => _deleteAnalysis(a),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: a.imageUrl != null && a.imageUrl!.startsWith('data:')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                ImageUtils.dataUrlToBytes(a.imageUrl!),
                                width: 48, height: 48, fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image_outlined, size: 40),
                      title: Text(a.headline, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${a.letterGrade}  •  ${a.overallScore.toStringAsFixed(0)}/100',
                          style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        Navigator.pop(ctx2);
                        final bytes = a.imageUrl != null && a.imageUrl!.startsWith('data:')
                            ? ImageUtils.dataUrlToBytes(a.imageUrl!)
                            : null;
                        if (bytes != null) {
                          context.push('/analysis', extra: {
                            'bytes': bytes,
                            'name': 'photo.jpg',
                            'analysis': a,
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: RefreshIndicator(
          onRefresh: _loadHistory,
          child: CustomScrollView(
            slivers: [
              _buildHeader(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickActions(),
                    const SizedBox(height: 28),
                    _buildDailyTip(),
                    const SizedBox(height: 28),
                    _buildRecentSection(),
                    SizedBox(height: 80 + bottomPad),
                  ]),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      expandedHeight: topPad + 152,
      collapsedHeight: kToolbarHeight,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.primaryDark,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      // Collapsed state — logo + title + bell
      title: Row(
        children: [
          const StyleIQLogo(size: 28, withShadow: false),
          const SizedBox(width: 10),
          const Text(
            'StyleIQ',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 24),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
        ],
      ),
      titleSpacing: 16,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryDark, Color(0xFF6C5ECF)],
            ),
          ),
          child: Stack(
            children: [
              // Subtle decorative circle
              Positioned(
                right: -30,
                top: -20,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              // Content — pushed below status bar / Dynamic Island
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_greetingEmoji  $_greeting',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'What are you\nwearing today?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.dark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(_actions.length, (i) {
            final a = _actions[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _actions.length - 1 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => context.push(a['route'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: a['bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            a['icon'] as IconData,
                            color: a['color'] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a['label'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkGrey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: 60 * i))
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.12, end: 0),
            );
          }),
        ),
      ],
    );
  }

  // ── Daily tip ─────────────────────────────────────────────────────────────
  Widget _buildDailyTip() {
    final tip = _todaysTip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Daily Style Tip',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accentMain.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Day ${DateTime.now().weekday} / 7',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accentMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF534AB7), Color(0xFF1D9E75)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryMain.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(tip['icon']!,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tip['body']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
      ],
    );
  }

  // ── Recent analyses ───────────────────────────────────────────────────────
  Widget _buildRecentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Analyses',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.dark,
                letterSpacing: -0.2,
              ),
            ),
            if (_recentAnalyses.isNotEmpty)
              TextButton(
                onPressed: () => _showAllAnalyses(context),
                child: const Text('See All',
                    style: TextStyle(
                        color: AppTheme.primaryMain,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingHistory)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(
                color: AppTheme.primaryMain, strokeWidth: 2),
          ))
        else if (_recentAnalyses.isEmpty)
          _buildEmptyState()
        else
          _buildAnalysisList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryMain.withValues(alpha: 0.1),
                  AppTheme.accentMain.withValues(alpha: 0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt_outlined,
                size: 32, color: AppTheme.primaryMain),
          ),
          const SizedBox(height: 16),
          const Text(
            'No analyses yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Analyze Outfit" to get your\nfirst AI style score',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mediumGrey,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildAnalysisList() {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _recentAnalyses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final a = _recentAnalyses[i];
          final scoreColor = AppTheme.getScoreColor(a.overallScore);
          return GestureDetector(
            onTap: () {
              final bytes = a.imageUrl != null && a.imageUrl!.startsWith('data:')
                  ? ImageUtils.dataUrlToBytes(a.imageUrl!)
                  : null;
              if (bytes != null) {
                context.push('/analysis', extra: {
                  'bytes': bytes,
                  'name': 'photo.jpg',
                  'analysis': a,
                });
              }
            },
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (a.imageUrl != null && a.imageUrl!.startsWith('data:'))
                    Image.memory(
                      ImageUtils.dataUrlToBytes(a.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  else
                    const ColoredBox(
                      color: Color(0xFFF0EEFF),
                      child: Icon(Icons.checkroom,
                          size: 40, color: AppTheme.primaryMain),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${a.overallScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        a.letterGrade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 4,
                    left: 4,
                    child: GestureDetector(
                      onTap: () async {
                        if (await _confirmDelete(a)) _deleteAnalysis(a);
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: Duration(milliseconds: 60 * i))
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.95, 0.95)),
          );
        },
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // ── Analyze Outfit button ─────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: _showPickerSheet,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryMain, Color(0xFF1D9E75)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryMain.withValues(alpha: 0.40),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Analyze Outfit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ── LIVE button ───────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/live'),
            child: _LiveButton(),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.4, end: 0, duration: 450.ms).fadeIn();
  }
}

// ── Picker option tile ────────────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.dark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mediumGrey)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.mediumGrey, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── LIVE button with pulsing gold indicator ───────────────────────────────────
class _LiveButton extends StatefulWidget {
  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      width: 82,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1206),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFd4a853), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFd4a853).withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFd4a853)
                    .withValues(alpha: _pulseAnim.value),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFd4a853)
                        .withValues(alpha: _pulseAnim.value * 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFd4a853),
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
