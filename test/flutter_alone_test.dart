// test/flutter_alone_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {
  // Record mock method calls
  bool checkAndRunCalled = false;
  bool disposeCalled = false;
  Map<String, dynamic>? lastArguments;

  @override
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    checkAndRunCalled = true;
    lastArguments = config.toMap();

    // Skip duplicate check in debug mode unless explicitly enabled
    if (kDebugMode && !config.duplicateCheckConfig.enableInDebugMode) {
      return true;
    }

    // Return true for the test
    return true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

void main() {
  late FlutterAlone flutterAlone;
  late MockFlutterAlonePlatform mockPlatform;

  setUp(() {
    mockPlatform = MockFlutterAlonePlatform();
    FlutterAlonePlatform.instance = mockPlatform;
    flutterAlone = FlutterAlone.instance;
  });

  group('Configuration tests', () {
    test('Basic MutexConfig should be created correctly', () {
      const config = MutexConfig(
        packageId: 'com.test.app',
        appName: 'TestApp',
      );
      final map = config.toMap();

      expect(map[ConfigJsonKey.packageId.key], 'com.test.app');
      expect(map['appName'], 'TestApp');
      expect(map.containsKey('mutexSuffix'), false);
    });

    test('MutexConfig with suffix should be created correctly', () {
      const config = MutexConfig(
        packageId: 'com.test.app',
        appName: 'TestApp',
        mutexSuffix: 'production',
      );
      final map = config.toMap();

      expect(map['packageId'], 'com.test.app');
      expect(map['appName'], 'TestApp');
      expect(map['mutexSuffix'], 'production');
    });

    test('WindowConfig should be created correctly', () {
      const config = WindowConfig(
        windowTitle: 'Test Window',
      );
      final map = config.toMap();

      expect(map['windowTitle'], 'Test Window');
    });

    test('DuplicateCheckConfig should be created correctly', () {
      const config = DuplicateCheckConfig(
        enableInDebugMode: true,
      );
      final map = config.toMap();

      expect(map['enableInDebugMode'], true);
    });

    test('Default DuplicateCheckConfig should have enableInDebugMode=false',
        () {
      const config = DuplicateCheckConfig();
      final map = config.toMap();

      expect(map['enableInDebugMode'], false);
    });

    test('EnMessageConfig should be created correctly', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('KoMessageConfig should be created correctly', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('CustomMessageConfig should be created correctly', () {
      const config = CustomMessageConfig(
        customTitle: 'Test Title',
        customMessage: 'Test Message',
        showMessageBox: false,
      );
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['customMessage'], 'Test Message');
      expect(map['showMessageBox'], false);
    });
  });

  group('FlutterAloneConfig tests', () {
    test('Combined config should include all components', () {
      const config = FlutterAloneConfig(
        mutexConfig: MutexConfig(
          packageId: 'com.test.app',
          appName: 'TestApp',
          mutexSuffix: 'test',
        ),
        windowConfig: WindowConfig(
          windowTitle: 'Test Window',
        ),
        duplicateCheckConfig: DuplicateCheckConfig(
          enableInDebugMode: true,
        ),
        messageConfig: CustomMessageConfig(
          customTitle: 'Test Title',
          customMessage: 'Test Message',
          showMessageBox: false,
        ),
      );

      final map = config.toMap();

      // Check mutex config
      expect(map['packageId'], 'com.test.app');
      expect(map['appName'], 'TestApp');
      expect(map['mutexSuffix'], 'test');

      // Check window config
      expect(map['windowTitle'], 'Test Window');

      // Check duplicate check config
      expect(map['enableInDebugMode'], true);

      // Check message config
      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['customMessage'], 'Test Message');
      expect(map['showMessageBox'], false);
    });
  });

  group('Plugin functionality tests', () {
    test('checkAndRun should pass correct config to platform', () async {
      const config = FlutterAloneConfig(
        mutexConfig: MutexConfig(
          packageId: 'com.test.app',
          appName: 'TestApp',
        ),
        duplicateCheckConfig: DuplicateCheckConfig(
          enableInDebugMode: true,
        ),
        messageConfig: EnMessageConfig(),
      );

      final result = await flutterAlone.checkAndRun(config: config);

      expect(result, true);
      expect(mockPlatform.checkAndRunCalled, true);

      final args = mockPlatform.lastArguments;
      expect(args, isNotNull);
      expect(args!['packageId'], 'com.test.app');
      expect(args['appName'], 'TestApp');
      expect(args['type'], 'en');
    });

    test('dispose should be called correctly', () async {
      await flutterAlone.dispose();
      expect(mockPlatform.disposeCalled, true);
    });
  });

  group('Integration tests', () {
    test('Full configuration with all options', () async {
      const config = FlutterAloneConfig(
        mutexConfig: MutexConfig(
          packageId: 'com.test.app',
          appName: 'TestApp',
          mutexSuffix: 'production',
        ),
        windowConfig: WindowConfig(
          windowTitle: 'Test Window',
        ),
        duplicateCheckConfig: DuplicateCheckConfig(
          enableInDebugMode: true,
        ),
        messageConfig: CustomMessageConfig(
          customTitle: 'Test Title',
          customMessage: 'Test Message',
          showMessageBox: true,
        ),
      );

      await flutterAlone.checkAndRun(config: config);

      final args = mockPlatform.lastArguments;
      expect(args, isNotNull);
      expect(args!['packageId'], 'com.test.app');
      expect(args['appName'], 'TestApp');
      expect(args['mutexSuffix'], 'production');
      expect(args['windowTitle'], 'Test Window');
      expect(args['enableInDebugMode'], true);
      expect(args['type'], 'custom');
      expect(args['customTitle'], 'Test Title');
      expect(args['customMessage'], 'Test Message');
      expect(args['showMessageBox'], true);
    });
  });
}
