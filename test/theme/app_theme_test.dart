// NOTE: GoogleFonts network fetching is disabled in setUpAll to prevent async
// race conditions during tests. The theme structure and static helper methods
// are fully testable without live font loading.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styleiq/core/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Prevent network requests for fonts — falls back to system font.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // ── getScoreColor ────────────────────────────────────────────────────────────

  group('AppTheme.getScoreColor', () {
    test('returns scoreExcellent for exactly 85', () {
      expect(AppTheme.getScoreColor(85), AppTheme.scoreExcellent);
    });

    test('returns scoreExcellent for 100', () {
      expect(AppTheme.getScoreColor(100), AppTheme.scoreExcellent);
    });

    test('returns scoreExcellent for 90', () {
      expect(AppTheme.getScoreColor(90), AppTheme.scoreExcellent);
    });

    test('returns scoreGood for exactly 70', () {
      expect(AppTheme.getScoreColor(70), AppTheme.scoreGood);
    });

    test('returns scoreGood for 84 (upper boundary of good range)', () {
      expect(AppTheme.getScoreColor(84), AppTheme.scoreGood);
    });

    test('returns scoreGood for 77', () {
      expect(AppTheme.getScoreColor(77), AppTheme.scoreGood);
    });

    test('returns scoreOk for exactly 55', () {
      expect(AppTheme.getScoreColor(55), AppTheme.scoreOk);
    });

    test('returns scoreOk for 69 (upper boundary of ok range)', () {
      expect(AppTheme.getScoreColor(69), AppTheme.scoreOk);
    });

    test('returns scorePoor for 54 (just below ok range)', () {
      expect(AppTheme.getScoreColor(54), AppTheme.scorePoor);
    });

    test('returns scorePoor for 0', () {
      expect(AppTheme.getScoreColor(0), AppTheme.scorePoor);
    });

    test('returns scorePoor for any score below 55', () {
      for (final score in [1.0, 10.0, 30.0, 54.9]) {
        expect(AppTheme.getScoreColor(score), AppTheme.scorePoor,
            reason: 'Expected scorePoor for $score');
      }
    });
  });

  // ── getLetterGrade ───────────────────────────────────────────────────────────

  group('AppTheme.getLetterGrade', () {
    test('S for exactly 95', () => expect(AppTheme.getLetterGrade(95), 'S'));
    test('S for 100', () => expect(AppTheme.getLetterGrade(100), 'S'));

    test('A+ for exactly 90', () => expect(AppTheme.getLetterGrade(90), 'A+'));
    test('A+ for 94 (just below S boundary)', () => expect(AppTheme.getLetterGrade(94), 'A+'));

    test('A for exactly 85', () => expect(AppTheme.getLetterGrade(85), 'A'));
    test('A for 89 (just below A+ boundary)', () => expect(AppTheme.getLetterGrade(89), 'A'));

    test('B+ for exactly 80', () => expect(AppTheme.getLetterGrade(80), 'B+'));
    test('B+ for 84 (just below A boundary)', () => expect(AppTheme.getLetterGrade(84), 'B+'));

    test('B for exactly 75', () => expect(AppTheme.getLetterGrade(75), 'B'));
    test('B for 79 (just below B+ boundary)', () => expect(AppTheme.getLetterGrade(79), 'B'));

    test('C+ for exactly 70', () => expect(AppTheme.getLetterGrade(70), 'C+'));
    test('C+ for 74 (just below B boundary)', () => expect(AppTheme.getLetterGrade(74), 'C+'));

    test('C for exactly 65', () => expect(AppTheme.getLetterGrade(65), 'C'));
    test('C for 69 (just below C+ boundary)', () => expect(AppTheme.getLetterGrade(69), 'C'));

    test('D for exactly 50', () => expect(AppTheme.getLetterGrade(50), 'D'));
    test('D for 64 (just below C boundary)', () => expect(AppTheme.getLetterGrade(64), 'D'));

    test('F for 49 (just below D boundary)', () => expect(AppTheme.getLetterGrade(49), 'F'));
    test('F for 0', () => expect(AppTheme.getLetterGrade(0), 'F'));
    test('F for 1', () => expect(AppTheme.getLetterGrade(1), 'F'));
  });

  // ── Colour constants ─────────────────────────────────────────────────────────

  group('AppTheme colour constants', () {
    test('all core colors are fully opaque', () {
      final colors = {
        'primaryMain': AppTheme.primaryMain,
        'primaryDark': AppTheme.primaryDark,
        'accentMain': AppTheme.accentMain,
        'accentLight': AppTheme.accentLight,
        'coral': AppTheme.coral,
        'amber': AppTheme.amber,
        'light': AppTheme.light,
        'lightGrey': AppTheme.lightGrey,
        'mediumGrey': AppTheme.mediumGrey,
        'darkGrey': AppTheme.darkGrey,
        'dark': AppTheme.dark,
      };
      for (final entry in colors.entries) {
        final alpha = (entry.value.a * 255.0).round().clamp(0, 255);
        expect(alpha, 255, reason: '${entry.key} should be fully opaque');
      }
    });

    test('scoreExcellent equals accentMain', () {
      expect(AppTheme.scoreExcellent, AppTheme.accentMain);
    });

    test('scoreOk equals amber', () {
      expect(AppTheme.scoreOk, AppTheme.amber);
    });

    test('scorePoor equals coral', () {
      expect(AppTheme.scorePoor, AppTheme.coral);
    });

    test('warning equals amber', () {
      expect(AppTheme.warning, AppTheme.amber);
    });

    test('error equals coral', () {
      expect(AppTheme.error, AppTheme.coral);
    });

    test('scaffoldBg is distinct from light', () {
      expect(AppTheme.scaffoldBg, isNot(equals(AppTheme.light)));
    });
  });

  // ── Gradients ────────────────────────────────────────────────────────────────

  group('AppTheme.purpleToTealGradient', () {
    test('is a LinearGradient', () {
      expect(AppTheme.purpleToTealGradient, isA<LinearGradient>());
    });

    test('starts with primaryMain', () {
      expect(AppTheme.purpleToTealGradient.colors.first, AppTheme.primaryMain);
    });

    test('ends with accentMain', () {
      expect(AppTheme.purpleToTealGradient.colors.last, AppTheme.accentMain);
    });
  });

  group('AppTheme.purpleGradient', () {
    test('is a LinearGradient', () {
      expect(AppTheme.purpleGradient, isA<LinearGradient>());
    });

    test('starts with primaryMain', () {
      expect(AppTheme.purpleGradient.colors.first, AppTheme.primaryMain);
    });

    test('ends with primaryDark', () {
      expect(AppTheme.purpleGradient.colors.last, AppTheme.primaryDark);
    });
  });

  // ── lightTheme ───────────────────────────────────────────────────────────────

  group('AppTheme.lightTheme', () {
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses Material 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    testWidgets('primaryColor matches primaryMain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(AppTheme.lightTheme.primaryColor, AppTheme.primaryMain);
    });

    testWidgets('scaffoldBackgroundColor matches light', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(AppTheme.lightTheme.scaffoldBackgroundColor, AppTheme.light);
    });

    testWidgets('colorScheme primary matches primaryMain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(AppTheme.lightTheme.colorScheme.primary, AppTheme.primaryMain);
    });

    testWidgets('colorScheme secondary matches accentMain', (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const SizedBox()),
      );
      expect(AppTheme.lightTheme.colorScheme.secondary, AppTheme.accentMain);
    });
  });
}
