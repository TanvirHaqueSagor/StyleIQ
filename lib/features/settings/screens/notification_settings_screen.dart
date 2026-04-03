import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/models/notification_settings.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _surface     = Color(0xFFFAF9FF);
const Color _surfaceCard = Color(0xFFFFFFFF);
const Color _onSurface   = Color(0xFF1A1528);
const Color _midTone     = Color(0xFF6B6882);
// ─────────────────────────────────────────────────────────────────────────────

const String _prefsKey = 'styleiq_notification_settings_v1';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings _settings = NotificationSettings(userId: 'guest');
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
        final s = NotificationSettings.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        if (mounted) setState(() { _settings = s; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist(NotificationSettings updated) async {
    setState(() { _settings = updated; _saving = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(updated.toJson()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(NotificationSettings Function(NotificationSettings) fn) {
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
                      title: 'Delivery',
                      icon: Icons.send_rounded,
                      color: AppTheme.primaryMain,
                      tiles: [
                        _ToggleTile(
                          label: 'Push notifications',
                          subtitle: 'Alerts directly on your device',
                          value: _settings.pushNotifications,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(pushNotifications: v)),
                        ),
                        _ToggleTile(
                          label: 'Email notifications',
                          subtitle: 'Updates sent to your inbox',
                          value: _settings.emailNotifications,
                          showDivider: false,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(emailNotifications: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Content',
                      icon: Icons.article_rounded,
                      color: AppTheme.accentMain,
                      tiles: [
                        _ToggleTile(
                          label: 'Daily style tips',
                          subtitle: 'One actionable tip every morning',
                          value: _settings.dailyStyleTips,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(dailyStyleTips: v)),
                        ),
                        _ToggleTile(
                          label: 'Weekly digest',
                          subtitle: 'Your style highlights from the week',
                          value: _settings.weeklyDigest,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(weeklyDigest: v)),
                        ),
                        _ToggleTile(
                          label: 'New features',
                          subtitle: 'Be the first to know what\'s new',
                          value: _settings.newFeatures,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(newFeatures: v)),
                        ),
                        _ToggleTile(
                          label: 'Cultural reminders',
                          subtitle:
                              'Upcoming festivals and dress code heads-ups',
                          value: _settings.culturalReminders,
                          showDivider: false,
                          onChanged: (v) => _toggle(
                              (s) => s.copyWith(culturalReminders: v)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
            'Notifications',
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
          const Divider(height: 1, indent: 18, endIndent: 18,
              color: Color(0xFFF0EFF9)),
      ],
    );
  }
}
