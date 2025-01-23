// example/integration_test/plugin_integration_test.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Alone Plugin Integration Tests', () {
    late FlutterAlone flutterAlone;
    const channel = MethodChannel('flutter_alone');

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkAndRun':
            return true;
          case 'dispose':
            return null;
          default:
            throw PlatformException(code: 'error');
        }
      });
    });

    setUp(() {
      flutterAlone = FlutterAlone.instance;
    });

    tearDown(() async {
      try {
        await flutterAlone.dispose();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Basic functionality test', () async {
      if (Platform.isWindows) {
        final result = await flutterAlone.checkAndRun();
        expect(result, true);
      }
    });
  });
}
