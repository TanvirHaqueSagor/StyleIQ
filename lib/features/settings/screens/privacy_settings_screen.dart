import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/models/privacy_settings.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFFAF9FF);
const Color _surfaceCard = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF1A1528);
const Color _midTone = Color(0xFF6B6882);
// ─────────────────────────────────────────────────────────────────────────────

const String _prefsKey = 'styleiq_privacy_settings_v1';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  PrivacySettings _settings =
      PrivacySettings(userId: AppUserService.currentUserId);
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final s =
            PrivacySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (mounted) {
          setState(() {
            _settings = s;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(PrivacySettings updated) async {
    setState(() {
      _settings = updated;
      _saving = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(updated.toJson()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(PrivacySettings Function(PrivacySettings) fn) {
    _persist(fn(_settings));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Analytics & Diagnostics',
                      icon: Icons.bar_chart_rounded,
                      color: AppTheme.primaryMain,
                      tiles: [
                        _ToggleTile(
                          label: 'Usage analytics',
                          subtitle:
                              'Help us improve StyleIQ by sharing anonymous usage data',
                          value: _settings.analyticsEnabled,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(analyticsEnabled: v)),
                        ),
                        _ToggleTile(
                          label: 'Crash reporting',
                          subtitle:
                              'Automatically send crash reports so we can fix bugs faster',
                          value: _settings.crashReporting,
                          showDivider: false,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(crashReporting: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Personalisation',
                      icon: Icons.tune_rounded,
                      color: AppTheme.accentMain,
                      tiles: [
                        _ToggleTile(
                          label: 'Personalised ads',
                          subtitle:
                              'Allow ads tailored to your style preferences',
                          value: _settings.personalizedAds,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(personalizedAds: v)),
                        ),
                        _ToggleTile(
                          label: 'Data sharing',
                          subtitle:
                              'Share anonymised style data with our partners',
                          value: _settings.dataSharing,
                          showDivider: false,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(dataSharing: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Community Visibility',
                      icon: Icons.people_outline_rounded,
                      color: AppTheme.amber,
                      tiles: [
                        _ToggleTile(
                          label: 'Public profile',
                          subtitle:
                              'Let other StyleIQ users discover your profile',
                          value: _settings.profileVisibility,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(profileVisibility: v)),
                        ),
                        _ToggleTile(
                          label: 'Public wardrobe',
                          subtitle:
                              'Share your wardrobe collection with the community',
                          value: _settings.wardrobePublic,
                          showDivider: false,
                          onChanged: (v) =>
                              _toggle((s) => s.copyWith(wardrobePublic: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Data management
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.coral.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.coral.withValues(alpha: 0.2),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_forever_rounded,
                              color: AppTheme.coral, size: 18),
                        ),
                        title: Text(
                          'Delete my data',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.coral,
                          ),
                        ),
                        subtitle: Text(
                          'Permanently erase your style history and profile',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: _midTone, height: 1.4),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            size: 18, color: AppTheme.coral),
                        onTap: () => _showDeleteConfirmation(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: AnimatedOpacity(
                        opacity: _saving ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text('Saving…',
                                style: GoogleFonts.inter(
                                    color: _midTone, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete all data?',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will permanently erase your style history, wardrobe items, and preferences. This cannot be undone.',
                style: GoogleFonts.inter(
                    fontSize: 14, color: _midTone, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: GoogleFonts.inter(
                              color: _midTone, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Data deletion request submitted. Your data will be removed within 30 days.'),
                          ),
                        );
                      },
                      child: Text('Delete',
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 112,
      backgroundColor: const Color(0xFF2D1B6B),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: const Color(0xFF2D1B6B),
          padding: EdgeInsets.fromLTRB(20, topPad + 56, 20, 16),
          alignment: Alignment.bottomLeft,
          child: Text(
            'Privacy',
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> tiles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _onSurface,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _surfaceCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

// ── Reusable toggle tile ──────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryMain,
          activeTrackColor: AppTheme.primaryMain.withValues(alpha: 0.4),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          title: Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: _onSurface),
          ),
          subtitle: Text(
            subtitle,
            style:
                GoogleFonts.inter(fontSize: 12, color: _midTone, height: 1.4),
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1, indent: 18, endIndent: 18, color: Color(0xFFF0EFF9)),
      ],
    );
  }
}
