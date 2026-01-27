import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cherry_reader/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {
    // Start the app
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Screenshot 1: Home Screen
    await binding.takeScreenshot('01_home_screen');

    // TODO: Add interactions to take more screenshots
    // e.g. tap a list item
    // final Finder firstItem = find.byType(ListTile).first;
    // await tester.tap(firstItem);
    // await tester.pumpAndSettle();
    // await binding.takeScreenshot('02_detail_screen');
  });
}
