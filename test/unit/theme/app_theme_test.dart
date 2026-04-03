import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styleiq/core/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Prevent GoogleFonts from trying to fetch fonts over the network in tests.
    // Falls back to system font — theme structure is still fully testable.
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  group('AppTheme.getScoreColor', () {
    test('returns scoreExcellent for 85+', () {
      expect(AppTheme.getScoreColor(85), AppTheme.scoreExcellent);
      expect(AppTheme.getScoreColor(100), AppTheme.scoreExcellent);
      expect(AppTheme.getScoreColor(90), AppTheme.scoreExcellent);
    });

    test('returns scoreGood for 70–84', () {
      expect(AppTheme.getScoreColor(70), AppTheme.scoreGood);
      expect(AppTheme.getScoreColor(84), AppTheme.scoreGood);
      expect(AppTheme.getScoreColor(77), AppTheme.scoreGood);
    });

    test('returns scoreOk for 55–69', () {
      expect(AppTheme.getScoreColor(55), AppTheme.scoreOk);
      expect(AppTheme.getScoreColor(69), AppTheme.scoreOk);
    });

    test('returns scorePoor for below 55', () {
      expect(AppTheme.getScoreColor(0), AppTheme.scorePoor);
      expect(AppTheme.getScoreColor(54), AppTheme.scorePoor);
    });
  });

  group('AppTheme.getLetterGrade', () {
    test('S for 95+', () => expect(AppTheme.getLetterGrade(95), 'S'));
    test('A+ for 90–94', () => expect(AppTheme.getLetterGrade(91), 'A+'));
    test('A for 85–89', () => expect(AppTheme.getLetterGrade(85), 'A'));
    test('B+ for 80–84', () => expect(AppTheme.getLetterGrade(80), 'B+'));
    test('B for 75–79', () => expect(AppTheme.getLetterGrade(75), 'B'));
    test('C+ for 70–74', () => expect(AppTheme.getLetterGrade(70), 'C+'));
    test('C for 65–69', () => expect(AppTheme.getLetterGrade(65), 'C'));
    test('D for 50–64', () => expect(AppTheme.getLetterGrade(50), 'D'));
    test('F for below 50', () => expect(AppTheme.getLetterGrade(49), 'F'));
    test('F for 0', () => expect(AppTheme.getLetterGrade(0), 'F'));
  });

  group('AppTheme.purpleToTealGradient', () {
    test('is a LinearGradient', () {
      expect(AppTheme.purpleToTealGradient, isA<LinearGradient>());
    });

    test('starts with primaryMain', () {
      final g = AppTheme.purpleToTealGradient;
      expect(g.colors.first, AppTheme.primaryMain);
    });

    test('ends with accentMain', () {
      final g = AppTheme.purpleToTealGradient;
      expect(g.colors.last, AppTheme.accentMain);
    });
  });

  group('AppTheme colour constants', () {
    test('all core colors are fully opaque', () {
      final colors = [
        AppTheme.primaryMain,
        AppTheme.primaryDark,
        AppTheme.accentMain,
        AppTheme.accentLight,
        AppTheme.coral,
        AppTheme.amber,
        AppTheme.light,
        AppTheme.lightGrey,
        AppTheme.mediumGrey,
        AppTheme.darkGrey,
        AppTheme.dark,
      ];
      for (final c in colors) {
        final alpha = (c.a * 255.0).round().clamp(0, 255);
        expect(alpha, 255, reason: '${c.toARGB32().toRadixString(16)} should be fully opaque');
      }
    });

    test('scaffoldBg is distinct from light', () {
      expect(AppTheme.scaffoldBg, isNot(equals(AppTheme.light)));
    });
  });

  group('AppTheme.lightTheme', () {
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses Material3', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()));
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    testWidgets('primary color matches primaryMain', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()));
      expect(AppTheme.lightTheme.primaryColor, AppTheme.primaryMain);
    });

    testWidgets('scaffold background matches light', (tester) async {
      await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()));
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppTheme.light);
    });
  });
}
