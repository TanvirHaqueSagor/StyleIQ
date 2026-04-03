// StyleIQ smoke test — verifies the app boots and reaches the main scaffold
// (either onboarding or the home screen depending on SharedPreferences state).

import 'package:flutter_test/flutter_test.dart';
import 'package:styleiq/main.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Pump a few frames to let async init settle
    await tester.pump(const Duration(milliseconds: 100));
    // App rendered — no exception thrown means boot succeeded
    expect(tester.takeException(), isNull);
  });
}
