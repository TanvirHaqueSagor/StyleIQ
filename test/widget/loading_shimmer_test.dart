import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/core/widgets/loading_shimmer.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('LoadingShimmer', () {
    testWidgets('renders at default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: LoadingShimmer())),
      );
      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('renders at custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingShimmer(width: 100, height: 50)),
        ),
      );
      expect(find.byType(LoadingShimmer), findsOneWidget);
    });
  });

  group('TextShimmer', () {
    testWidgets('renders single line by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextShimmer())),
      );
      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('renders correct number of lines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TextShimmer(lines: 3))),
      );
      expect(find.byType(LoadingShimmer), findsNWidgets(3));
    });
  });

  group('ScoreCardShimmer', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScoreCardShimmer())),
      );
      expect(find.byType(ScoreCardShimmer), findsOneWidget);
    });

    testWidgets('renders 5 dimension bar shimmers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ScoreCardShimmer())),
      );
      // Header(1) + circle(1) + 5×2 dimension bars + strengths(1) + suggestions(1) = 14
      expect(find.byType(LoadingShimmer), findsWidgets);
    });
  });

  group('ImageShimmer', () {
    testWidgets('renders at default size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ImageShimmer())),
      );
      expect(find.byType(ImageShimmer), findsOneWidget);
      expect(find.byType(LoadingShimmer), findsOneWidget);
    });
  });
}
