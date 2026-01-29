import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();

  final String locale = Platform.environment['FASTLANE_LOCALE'] ?? 'en-US';
  final String deviceName = Platform.environment['FASTLANE_DEVICE_NAME'] ?? 'iPhone';
  final Directory outputDir = Directory('ios/fastlane/screenshots/$locale');

  await integrationDriver(
    driver: driver,
    onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
      await outputDir.create(recursive: true);
      final File outputFile = File('${outputDir.path}/$deviceName-$name.png');
      await outputFile.writeAsBytes(image, flush: true);
      return true;
    },
  );
}

