import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/services/subscription_capability_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/styleiq_logo.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
import 'package:styleiq/models/subscription_plan.dart';
import 'package:styleiq/routes/app_router.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _analysisService = AnalysisService();
  final _storage = LocalStorageService();

  int _analysisCount = 0;
  int _wardrobeCount = 0;
  int _savedLookCount = 0;
  String? _focusArea;
  Map<String, String> _stylePrefs = {};
  SubscriptionPlan _subscription = SubscriptionCapabilityService.freePlan();
  bool _loading = true;

  String get _userId => AppUserService.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _userId;
      final analyses = await _analysisService.getAnalysisHistory(userId);
      final wardrobe = await _storage.getWardrobeItems(userId);
      final stylePrefs = await AppUserService.getStylePreferences();
      final subscription = await _storage.getSubscription(userId);

      if (mounted) {
        final focusArea = _deriveFocusArea(analyses);
        setState(() {
          _analysisCount = analyses.length;
          _wardrobeCount = wardrobe.length;
          _savedLookCount =
              analyses.fold(0, (sum, a) => sum + a.generatedMockups.length);
          _focusArea = focusArea;
          _stylePrefs = stylePrefs;
          _subscription = subscription;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load profile data')),
        );
      }
    }
  }

  // ── Pretty label for preference keys ─────────────────────────────────────
  static String _prefLabel(String key) => switch (key) {
        'dress_code' => 'Daily Style',
        'color_palette' => 'Color Palette',
        'style_goals' => 'Style Goal',
        'cultural_background' => 'Cultural Background',
        'fashion_adventure' => 'Style Approach',
        'shopping_budget' => 'Budget',
        _ => key,
      };

  static const _prefEmoji = {
    'dress_code': '👔',
    'color_palette': '🎨',
    'style_goals': '🎯',
    'cultural_background': '🌍',
    'fashion_adventure': '🚀',
    'shopping_budget': '💳',
  };

  static String? _deriveFocusArea(List<StyleAnalysis> analyses) {
    if (analyses.isEmpty) return null;
    final totals = <String, double>{
      'Color': 0,
      'Fit': 0,
      'Occasion': 0,
      'Trend': 0,
      'Cohesion': 0,
    };
    for (final analysis in analyses) {
      totals['Color'] =
          totals['Color']! + analysis.dimensions.colorHarmony.score;
      totals['Fit'] = totals['Fit']! + analysis.dimensions.fitProportion.score;
      totals['Occasion'] =
          totals['Occasion']! + analysis.dimensions.occasionMatch.score;
      totals['Trend'] =
          totals['Trend']! + analysis.dimensions.trendAlignment.score;
      totals['Cohesion'] =
          totals['Cohesion']! + analysis.dimensions.styleCohesion.score;
    }
    return totals.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildProfileBanner()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildStats(),
                          if (_focusArea != null) ...[
                            const SizedBox(height: 20),
                            _buildProgressFocus(),
                          ],
                          if (_stylePrefs.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            _buildStyleDNA(),
                          ],
                          const SizedBox(height: 28),
                          _buildSettings(),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  SliverAppBar _buildHeader() {
    return const SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: Text(
        'My Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      actions: [],
    );
  }

  // ── Profile banner (scrolls with content) ────────────────────────────────
  Widget _buildProfileBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B6B), AppTheme.primaryMain],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            children: [
              const StyleIQLogo(size: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Style Explorer',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✦  Local only',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subscription.isFree
                          ? 'Free plan active on this device'
                          : '${_subscription.name} preview saved locally',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '$_analysisCount',
            label: 'Analyses',
            icon: Icons.photo_camera,
            color: AppTheme.primaryMain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '$_wardrobeCount',
            label: 'Wardrobe Items',
            icon: Icons.checkroom,
            color: AppTheme.accentMain,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '$_savedLookCount',
            label: 'Saved Looks',
            icon: Icons.auto_awesome,
            color: AppTheme.amber,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildProgressFocus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Focus',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.mediumGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Most room to improve: $_focusArea',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.dark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use your next analysis, hairstyle suggestions, or guide recommendations to improve this dimension first.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppTheme.mediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Style DNA ─────────────────────────────────────────────────────────────
  Widget _buildStyleDNA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🧬', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Your Style DNA',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: _stylePrefs.entries.toList().asMap().entries.map((e) {
              final index = e.key;
              final entry = e.value;
              final isLast = index == _stylePrefs.length - 1;
              return _PrefTile(
                emoji: _prefEmoji[entry.key] ?? '•',
                label: _prefLabel(entry.key),
                value: entry.value,
                showDivider: !isLast,
              ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn();
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Widget _buildSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                color: AppTheme.primaryMain,
                onTap: () => context.push('/settings/notifications'),
              ),
              _SettingsTile(
                icon: Icons.auto_awesome_outlined,
                label: 'Style Challenges',
                color: AppTheme.coral,
                onTap: () => context.push('/engagement'),
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                color: AppTheme.accentMain,
                onTap: () => context.push('/settings/privacy'),
              ),
              _SettingsTile(
                icon: Icons.star_outline,
                label: 'Upgrade to Style+',
                color: AppTheme.amber,
                onTap: () => context.push('/subscription'),
                showBadge: true,
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'About StyleIQ',
                color: AppTheme.mediumGrey,
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'StyleIQ',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 StyleIQ. All rights reserved.',
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                        'AI-powered personal style intelligence. Analyze, improve, and celebrate your unique style.'),
                  ],
                ),
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Redo onboarding
        OutlinedButton.icon(
          onPressed: () async {
            final prefs = await AppUserService.getStylePreferences();
            if (prefs.isNotEmpty && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Profile answers stay saved. Onboarding will reopen after app restart.')),
              );
            }
            final sharedPrefs = await SharedPreferences.getInstance();
            await sharedPrefs.remove('completed_onboarding');
            resetOnboardingFlag();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Restart the app to redo onboarding')),
              );
            }
          },
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Redo Style Quiz'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.mediumGrey,
            side: BorderSide(color: AppTheme.mediumGrey.withValues(alpha: 0.4)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ],
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mediumGrey,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final bool showDivider;

  const _PrefTile({
    required this.emoji,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGrey,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGrey,
                    ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 48,
            color: AppTheme.lightGrey,
          ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.showBadge = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showBadge)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.amber,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppTheme.mediumGrey),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 64, color: AppTheme.lightGrey),
      ],
    );
  }
}
