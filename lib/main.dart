import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/routes/app_router.dart';
import 'package:styleiq/services/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorageService.initialize();

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
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
