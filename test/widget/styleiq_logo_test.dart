import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/core/widgets/styleiq_logo.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('StyleIQLogo widget', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StyleIQLogo())),
      );
      expect(find.byType(StyleIQLogo), findsOneWidget);
    });

    testWidgets('respects size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StyleIQLogo(size: 120))),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StyleIQLogo),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.constraints?.maxWidth, 120);
    });

    testWidgets('shows fashion and sparkle icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: StyleIQLogo())),
      );
      expect(find.byIcon(Icons.checkroom), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('withShadow false renders without boxShadow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StyleIQLogo(withShadow: false)),
        ),
      );
      expect(find.byType(StyleIQLogo), findsOneWidget);
    });
  });
}
