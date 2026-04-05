import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styleiq/core/services/app_user_service.dart';
import 'package:styleiq/core/services/subscription_capability_service.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/models/subscription_plan.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const Color _surface = Color(0xFFFAF9FF);
const Color _surfaceCard = Color(0xFFFFFFFF);
const Color _onSurface = Color(0xFF1A1528);
const Color _midTone = Color(0xFF6B6882);
const Color _gold = Color(0xFFEF9F27);
// ─────────────────────────────────────────────────────────────────────────────

// Plan UI metadata (id matches SubscriptionPlan.id)
const _planMeta = {
  'free': (
    accent: _midTone,
    badge: 'Current plan',
    features: [
      '3 outfit analyses per month',
      'Basic style scoring',
      'Cultural dress guide',
      'Wardrobe up to 10 items',
      'Local-only progress tracking',
    ],
  ),
  'style_plus': (
    accent: AppTheme.primaryMain,
    badge: 'Coming soon',
    features: [
      '30 outfit analyses per month',
      '5 makeovers per month',
      'Wardrobe up to 50 items',
      'Deeper progress insights',
      'Priority AI processing',
      'Notify me when billing launches',
    ],
  ),
  'style_pro': (
    accent: _gold,
    badge: 'Preview',
    features: [
      'Everything in Style+',
      'Unlimited makeovers',
      'Unlimited wardrobe items',
      'Style DNA profile',
      'Live camera scoring preview',
      'Priority access when payments launch',
    ],
  ),
};

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final LocalStorageService _storage = LocalStorageService();

  late Future<SubscriptionPlan> _currentPlanFuture;
  String _selectedId = 'style_plus';
  bool _processing = false;
  List<SubscriptionPlan> get _availablePlans =>
      SubscriptionCapabilityService.catalog();

  @override
  void initState() {
    super.initState();
    _currentPlanFuture = _storage.getSubscription(AppUserService.currentUserId);
    _currentPlanFuture.then((p) {
      if (mounted && p.id == 'free') {
        setState(() => _selectedId = 'style_plus');
      } else if (mounted) {
        setState(() => _selectedId = p.id);
      }
    });
  }

  Future<void> _subscribe(SubscriptionPlan plan) async {
    if (plan.isFree) return;
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _processing = false);

    // Show "coming soon" dialog — real Stripe integration goes here
    showDialog<void>(
      context: context,
      builder: (_) {
        final meta = _planMeta[plan.id];
        final accent = meta?.accent ?? AppTheme.primaryMain;
        return Dialog(
          backgroundColor: _surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.star_rounded, color: accent, size: 32),
                ),
                const SizedBox(height: 18),
                Text(
                  'Upgrade coming soon',
                  style: GoogleFonts.notoSerif(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Billing is not live yet. ${plan.name} is shown as a preview so you can understand the value. For now, your progress stays local on this device.',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: _midTone, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Got it',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubscriptionPlan>(
      future: _currentPlanFuture,
      builder: (context, snapshot) {
        final current = snapshot.data;
        return Scaffold(
          backgroundColor: _surface,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlock your full style potential',
                        style: GoogleFonts.notoSerif(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _onSurface,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 6),
                      Text(
                        'See what is available now and what is still in preview.',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: _midTone, height: 1.5),
                      ).animate().fadeIn(duration: 380.ms),
                      const SizedBox(height: 28),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else
                        ...List.generate(
                          _availablePlans.length,
                          (i) => _buildPlanCard(_availablePlans[i], current)
                              .animate(
                                delay: Duration(milliseconds: 60 * i),
                              )
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.06, end: 0),
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Local-first today. Paid upgrades will become available when billing launches.',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _midTone.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: current == null ? null : _buildCta(current),
        );
      },
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
          child: Row(
            children: [
              Text(
                'Upgrade',
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '✦  Style+',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _gold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, SubscriptionPlan? current) {
    final isCurrent = current?.id == plan.id;
    final isSelected = _selectedId == plan.id;
    final meta = _planMeta[plan.id];
    final accent = meta?.accent ?? AppTheme.primaryMain;
    final badge = isCurrent ? 'Current plan' : (meta?.badge ?? '');
    final features = meta?.features ?? plan.features;

    return GestureDetector(
      onTap: isCurrent ? null : () => setState(() => _selectedId = plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.05) : _surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent : accent.withValues(alpha: 0.18),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 20 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: GoogleFonts.notoSerif(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        plan.formattedPrice,
                        style: GoogleFonts.notoSerif(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        plan.isFree ? 'forever' : 'per month',
                        style: GoogleFonts.inter(fontSize: 12, color: _midTone),
                      ),
                    ],
                  ),
                  if (!isCurrent) ...[
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? accent
                              : _midTone.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        color: isSelected ? accent : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 13)
                          : null,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0EFF9)),
              const SizedBox(height: 14),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(top: 1, right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.12),
                        ),
                        child: Icon(Icons.check, color: accent, size: 11),
                      ),
                      Expanded(
                        child: Text(
                          f,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: _onSurface.withValues(alpha: 0.8),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCta(SubscriptionPlan current) {
    final selectedPlan = _availablePlans.firstWhere((p) => p.id == _selectedId);
    final isCurrent = current.id == selectedPlan.id;
    final meta = _planMeta[selectedPlan.id];
    final accent = meta?.accent ?? AppTheme.primaryMain;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
      decoration: BoxDecoration(
        color: _surfaceCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isCurrent
            ? Center(
                child: Text(
                  'You\'re already on this plan',
                  style: GoogleFonts.inter(
                      color: _midTone,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              )
            : GestureDetector(
                onTap: _processing ? null : () => _subscribe(selectedPlan),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent,
                        accent.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _processing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text(
                          'Subscribe to ${selectedPlan.name} · ${selectedPlan.formattedPrice}/mo',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}
