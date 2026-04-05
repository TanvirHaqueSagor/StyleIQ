import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:styleiq/core/widgets/main_scaffold.dart';
import 'package:styleiq/features/analysis/models/style_analysis.dart';
import 'package:styleiq/features/analysis/screens/analysis_screen.dart';
import 'package:styleiq/features/analysis/screens/home_screen.dart';
import 'package:styleiq/features/community/screens/community_screen.dart';
import 'package:styleiq/features/cultural_guide/screens/guide_screen.dart';
import 'package:styleiq/features/history/screens/history_screen.dart';
import 'package:styleiq/features/makeover/screens/hairstyle_screen.dart';
import 'package:styleiq/features/makeover/screens/makeover_screen.dart';
import 'package:styleiq/features/notifications/screens/notification_center_screen.dart';
import 'package:styleiq/features/onboarding/screens/onboarding_screen.dart';
import 'package:styleiq/features/profile/screens/privacy_settings_screen.dart';
import 'package:styleiq/features/profile/screens/profile_screen.dart';
import 'package:styleiq/features/settings/screens/notification_settings_screen.dart';
import 'package:styleiq/features/subscription/screens/subscription_screen.dart';
import 'package:styleiq/features/engagement/screens/engagement_dashboard_screen.dart';
import 'package:styleiq/features/live_camera/screens/live_camera_screen.dart';
import 'package:styleiq/features/wardrobe/screens/wardrobe_screen.dart';

// Cached at startup — avoids async redirect which causes duplicate page-key crashes.
bool _onboardingDone = false;

/// Call once from main() after reading SharedPreferences.
void initRouterPrefs({required bool onboardingDone}) {
  _onboardingDone = onboardingDone;
}

/// Call from OnboardingScreen before context.go('/') so the sync redirect passes.
void markOnboardingComplete() {
  _onboardingDone = true;
}

/// Call from ProfileScreen when resetting onboarding (dev/testing).
void resetOnboardingFlag() {
  _onboardingDone = false;
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (!_onboardingDone && state.matchedLocation != '/onboarding') {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    // ── Full-screen routes outside the bottom-nav shell ─────────────────────
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) return const HomeScreen();
        return AnalysisScreen(
          imageBytes: extra['bytes'] as dynamic,
          imageName: extra['name'] as String? ?? 'photo.jpg',
          existingAnalysis: extra['analysis'] as StyleAnalysis?,
        );
      },
    ),
    GoRoute(
      path: '/hairstyles',
      builder: (_, __) => const HairstyleScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (_, __) => const CommunityScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, __) => const NotificationCenterScreen(),
    ),
    GoRoute(
      path: '/engagement',
      builder: (_, __) => const EngagementDashboardScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (_, __) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (_, __) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/subscription',
      builder: (_, __) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/live',
      builder: (_, __) => const LiveCameraScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (_, __) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/makeover',
      builder: (_, __) => const MakeoverScreen(),
    ),

    // ── Bottom-nav shell: Home / Guide / Wardrobe / Profile ─────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/guide', builder: (_, __) => const GuideScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/wardrobe', builder: (_, __) => const WardrobeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('Route not found: ${state.error}')),
  ),
);
