import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/core/theme/app_theme.dart';
import 'package:styleiq/features/wardrobe/screens/wardrobe_screen.dart';

Widget buildApp(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('WardrobeScreen', () {
    testWidgets('renders header with title', (tester) async {
      await tester.pumpWidget(buildApp(const WardrobeScreen()));
      await tester.pump();
      expect(find.text('Your Wardrobe'), findsOneWidget);
    });

    testWidgets('shows category filter chips', (tester) async {
      await tester.pumpWidget(buildApp(const WardrobeScreen()));
      await tester.pump();
      // _catLabels uses uppercase abbreviated labels
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('TOPS'), findsOneWidget);
      expect(find.text('BOTTOMS'), findsOneWidget);
      expect(find.text('DRESSES'), findsOneWidget);
      expect(find.text('SHOES'), findsOneWidget);
      expect(find.text('ACCESSORIES'), findsOneWidget);
    });

    testWidgets('shows FAB with add icon', (tester) async {
      await tester.pumpWidget(buildApp(const WardrobeScreen()));
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no items loaded', (tester) async {
      await tester.pumpWidget(buildApp(const WardrobeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Your wardrobe is empty'), findsOneWidget);
    });

    testWidgets('tapping a category chip shows category empty state',
        (tester) async {
      await tester.pumpWidget(buildApp(const WardrobeScreen()));
      await tester.pumpAndSettle();
      // Tap the 'TOPS' chip — _categories[1] = 'Top' → selectedCat = 'Top'
      await tester.tap(find.text('TOPS'));
      await tester.pump();
      // Empty state shows 'No tops added yet' (selectedCat.toLowerCase() + 's')
      expect(find.textContaining('tops'), findsOneWidget);
    });
  });
}
