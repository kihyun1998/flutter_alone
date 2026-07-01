import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

// FlutterAloneConfig.toMapFor(platform) is the pure, platform-explicit
// serialization used by toMap(). Because the platform is a parameter (not read
// from dart:io Platform), every platform branch is testable on any OS/runner.

void main() {
  group('toMapFor', () {
    test('windows serializes the mutex name and common config', () {
      final config = FlutterAloneConfig.forWindows(
        windowsConfig: const DefaultWindowsMutexConfig(
          packageId: 'com.test.app',
          appName: 'TestApp',
        ),
        windowConfig: const WindowConfig(windowTitle: 'Main'),
        duplicateCheckConfig:
            const DuplicateCheckConfig(enableInDebugMode: true),
        messageConfig: const EnMessageConfig(),
      );

      final map = config.toMapFor(AlonePlatform.windows);

      expect(map['mutexName'], r'Global\com.test.app_TestApp');
      expect(map['enableInDebugMode'], true);
      expect(map['windowTitle'], 'Main');
      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('macOS serializes the lock file name and common config', () {
      final config = FlutterAloneConfig.forMacOS(
        macOSConfig: MacOSConfig(lockFileName: 'app.lock'),
        messageConfig: const EnMessageConfig(),
      );

      final map = config.toMapFor(AlonePlatform.macOS);

      expect(map['lockFileName'], 'app.lock');
      expect(map['type'], 'en');
    });

    test('linux serializes the lock file name and common config', () {
      final config = FlutterAloneConfig.forLinux(
        linuxConfig: LinuxConfig(lockFileName: 'app.lock'),
        messageConfig: const KoMessageConfig(),
      );

      final map = config.toMapFor(AlonePlatform.linux);

      expect(map['lockFileName'], 'app.lock');
      expect(map['type'], 'ko');
    });

    test('throws when serialized for a platform its config lacks', () {
      // Built for macOS (windowsConfig is null) but serialized for windows.
      final config = FlutterAloneConfig.forMacOS(
        macOSConfig: MacOSConfig(lockFileName: 'app.lock'),
        messageConfig: const EnMessageConfig(),
      );

      expect(
        () => config.toMapFor(AlonePlatform.windows),
        throwsA(isA<StateError>()),
      );
    });

    test('other includes only common config and no platform section', () {
      final config = FlutterAloneConfig.forLinux(
        linuxConfig: LinuxConfig(lockFileName: 'app.lock'),
        windowConfig: const WindowConfig(windowTitle: 'Main'),
        duplicateCheckConfig:
            const DuplicateCheckConfig(enableInDebugMode: true),
        messageConfig: const EnMessageConfig(),
      );

      final map = config.toMapFor(AlonePlatform.other);

      expect(map['enableInDebugMode'], true);
      expect(map['windowTitle'], 'Main');
      expect(map['type'], 'en');
      expect(map.containsKey('lockFileName'), isFalse);
      expect(map.containsKey('mutexName'), isFalse);
    });
  });
}
