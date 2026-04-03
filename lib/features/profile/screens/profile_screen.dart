import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/core/widgets/styleiq_logo.dart';
import 'package:styleiq/features/analysis/services/analysis_service.dart';
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
  Map<String, String> _stylePrefs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final analyses = await _analysisService.getAnalysisHistory('guest');
      final wardrobe = await _storage.getWardrobeItems('guest');
      final prefs = await SharedPreferences.getInstance();

      final stylePrefs = <String, String>{};
      for (final key in [
        'dress_code',
        'color_palette',
        'style_goals',
        'cultural_background',
        'fashion_adventure',
        'shopping_budget',
      ]) {
        final v = prefs.getString(key);
        if (v != null && v.isNotEmpty) stylePrefs[key] = v;
      }

      if (mounted) {
        setState(() {
          _analysisCount = analyses.length;
          _wardrobeCount = wardrobe.length;
          _stylePrefs = stylePrefs;
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
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined,
                color: Colors.white, size: 18),
          ),
        ),
      ],
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
                        '✦  Free Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
            value: '${3 - _analysisCount.clamp(0, 3)}',
            label: 'Free Left',
            icon: Icons.auto_awesome,
            color: AppTheme.amber,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ── Style DNA ─────────────────────────────────────────────────────────────
  Widget _buildStyleDNA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🧬',
                style: TextStyle(fontSize: 18)),
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
                    const Text('AI-powered personal style intelligence. Analyze, improve, and celebrate your unique style.'),
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
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('completed_onboarding');
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
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
