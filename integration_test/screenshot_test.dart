import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cherry_reader/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await binding.takeScreenshot('01_launch');

    final Finder skipButton = find.text('跳过');
    if (skipButton.evaluate().isNotEmpty) {
      await binding.takeScreenshot('02_onboarding');
      await tester.tap(skipButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    await binding.takeScreenshot('03_home');

    final Finder settingsButton = find.byIcon(Icons.settings_outlined);
    if (settingsButton.evaluate().isNotEmpty) {
      await tester.tap(settingsButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await binding.takeScreenshot('04_settings');
    }

    final Finder onboardingTile = find.text('新手引导');
    if (onboardingTile.evaluate().isNotEmpty) {
      await tester.ensureVisible(onboardingTile);
      await tester.tap(onboardingTile);
      await tester.pumpAndSettle();

      final Finder confirmButton = find.text('确定');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      await binding.takeScreenshot('05_onboarding');

      final Finder nextButton = find.text('下一步');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await binding.takeScreenshot('06_onboarding_next');
      }
    }
  });
}
