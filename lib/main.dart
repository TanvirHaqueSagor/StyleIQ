import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/constants/app_constants.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/routes/app_router.dart';
import 'package:styleiq/services/auth/auth_service.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

const bool _forceFullBootstrap = bool.fromEnvironment(
  'STYLEIQ_FULL_BOOTSTRAP',
  defaultValue: false,
);

bool get _shouldSkipFirebaseBootstrap => kDebugMode && !_forceFullBootstrap;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripeKey = AppConstants.stripePublishableKey;
  if (stripeKey.isNotEmpty) {
    Stripe.publishableKey = stripeKey;
    await Stripe.instance.applySettings();
  }

  await LocalStorageService.initialize();

  if (!_shouldSkipFirebaseBootstrap) {
    try {
      await Firebase.initializeApp();

      // Production and opt-in debug boots keep the anonymous auth bootstrap.
      final authService = AuthService();
      if (!authService.isAuthenticated) {
        await authService.signInAnonymously();
      }
    } catch (e) {
      // Firebase init fails if GoogleService-Info.plist / google-services.json
      // is missing. App runs in local-only mode in that case.
      debugPrint('[StyleIQ] Firebase unavailable — running offline: $e');
    }
  }

  // Preload the onboarding flag once so the router redirect stays synchronous.
  // An async redirect causes GoRouter to call it multiple times concurrently,
  // producing duplicate page keys and the !keyReservation assertion crash.
  final prefs = await SharedPreferences.getInstance();
  initRouterPrefs(
    onboardingDone: prefs.getBool('completed_onboarding') ?? false,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StyleIQ',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
