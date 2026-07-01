import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Records delegations so we can assert whether FlutterAlone consulted the
// platform. The config is passed straight through (toMap is never called here),
// so a Windows config is fine on any runner.
class _MockPlatform extends FlutterAlonePlatform
    with MockPlatformInterfaceMixin {
  int checkAndRunCalls = 0;
  int disposeCalls = 0;
  bool checkAndRunReturn = false;
  FlutterAloneConfig? lastConfig;

  @override
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    checkAndRunCalls++;
    lastConfig = config;
    return checkAndRunReturn;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

FlutterAloneConfig _config({required bool enableInDebugMode}) {
  return FlutterAloneConfig.forWindows(
    windowsConfig:
        const DefaultWindowsMutexConfig(packageId: 'com.test', appName: 'App'),
    duplicateCheckConfig:
        DuplicateCheckConfig(enableInDebugMode: enableInDebugMode),
    messageConfig: const EnMessageConfig(),
  );
}

void main() {
  group('FlutterAlone', () {
    late _MockPlatform mock;

    setUp(() {
      mock = _MockPlatform();
      FlutterAlonePlatform.instance = mock;
    });

    // Tests run with kDebugMode == true, so this exercises the debug skip.
    test('checkAndRun returns true and skips the platform in debug mode',
        () async {
      final result = await FlutterAlone.instance
          .checkAndRun(config: _config(enableInDebugMode: false));

      expect(result, isTrue);
      expect(mock.checkAndRunCalls, 0);
    });

    test('checkAndRun delegates to the platform when enabled in debug mode',
        () async {
      mock.checkAndRunReturn = false; // distinct from the skip's `true`
      final config = _config(enableInDebugMode: true);

      final result = await FlutterAlone.instance.checkAndRun(config: config);

      expect(mock.checkAndRunCalls, 1);
      expect(mock.lastConfig, same(config));
      expect(result, isFalse);
    });

    test('dispose delegates to the platform', () async {
      await FlutterAlone.instance.dispose();

      expect(mock.disposeCalls, 1);
    });
  });

  group('AloneException', () {
    test('toString includes the code, message, and details', () {
      final e = AloneException(code: 'X', message: 'boom', details: 'extra');

      expect(e.toString(), 'AloneException(X): boom [extra]');
    });

    test('toString omits the details when null', () {
      final e = AloneException(code: 'Y', message: 'oops');

      expect(e.toString(), 'AloneException(Y): oops');
    });
  });
}
