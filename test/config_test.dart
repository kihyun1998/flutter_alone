import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

// These tests deliberately cover only platform-independent config pieces.
// FlutterAloneConfig.toMap() branches on the runtime OS (dart:io Platform) and
// throws for the "wrong" platform, so it cannot be unit-tested off its native
// OS until that coupling is removed (tracked separately). Everything here is
// pure and runs identically on any CI runner.

void main() {
  group('WindowsMutexConfig', () {
    test('DefaultWindowsMutexConfig builds a Global-prefixed name', () {
      const config = DefaultWindowsMutexConfig(
        packageId: 'com.test.app',
        appName: 'TestApp',
      );
      expect(config.getMutexName(), r'Global\com.test.app_TestApp');
      expect(config.toMap()['mutexName'], r'Global\com.test.app_TestApp');
    });

    test('DefaultWindowsMutexConfig appends the suffix when provided', () {
      const config = DefaultWindowsMutexConfig(
        packageId: 'com.test.app',
        appName: 'TestApp',
        mutexSuffix: 'production',
      );
      expect(config.getMutexName(), r'Global\com.test.app_TestApp_production');
    });

    test('CustomWindowsMutexConfig adds the Global prefix when missing', () {
      final config = CustomWindowsMutexConfig(customMutexName: 'MyMutex');
      expect(config.getMutexName(), r'Global\MyMutex');
    });

    test('CustomWindowsMutexConfig preserves an existing Global prefix', () {
      final config =
          CustomWindowsMutexConfig(customMutexName: r'Global\MyMutex');
      expect(config.getMutexName(), r'Global\MyMutex');
    });

    test('CustomWindowsMutexConfig rejects an empty name', () {
      expect(
        () => CustomWindowsMutexConfig(customMutexName: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MessageConfig', () {
    test('EnMessageConfig serializes type "en"', () {
      const config = EnMessageConfig();
      expect(config.toMap()['type'], 'en');
      expect(config.toMap()['showMessageBox'], true);
    });

    test('EnMessageConfig resolves the English title and message', () {
      const config = EnMessageConfig();
      expect(config.toMap()['title'], 'Notice');
      expect(config.toMap()['message'],
          'Application is already running in another account.');
    });

    test('KoMessageConfig serializes type "ko" and honors showMessageBox', () {
      const config = KoMessageConfig(showMessageBox: false);
      expect(config.toMap()['type'], 'ko');
      expect(config.toMap()['showMessageBox'], false);
    });

    test('KoMessageConfig resolves the Korean title and message', () {
      const config = KoMessageConfig();
      expect(config.toMap()['title'], '알림');
      expect(
        config.toMap()['message'],
        '이미 다른 계정에서 앱을 실행중입니다.',
      );
    });

    test('CustomMessageConfig serializes custom title and message', () {
      const config = CustomMessageConfig(
        customTitle: 'Notice',
        customMessage: 'Already running',
      );
      final map = config.toMap();
      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Notice');
      expect(map['customMessage'], 'Already running');
      expect(map['showMessageBox'], true);
    });

    test('CustomMessageConfig resolves title/message from the custom values',
        () {
      const config = CustomMessageConfig(
        customTitle: 'My Title',
        customMessage: 'My Message',
      );
      expect(config.toMap()['title'], 'My Title');
      expect(config.toMap()['message'], 'My Message');
    });

    test(
        'CustomMessageConfig falls back to English when a custom value is empty',
        () {
      const config = CustomMessageConfig(customTitle: '', customMessage: '');
      expect(config.toMap()['title'], 'Notice');
      expect(config.toMap()['message'],
          'Application is already running in another account.');
    });
  });

  group('DuplicateCheckConfig', () {
    test('defaults enableInDebugMode to false', () {
      expect(
          const DuplicateCheckConfig().toMap(), {'enableInDebugMode': false});
    });

    test('honors enableInDebugMode true', () {
      expect(const DuplicateCheckConfig(enableInDebugMode: true).toMap(),
          {'enableInDebugMode': true});
    });
  });

  group('WindowConfig', () {
    test('includes windowTitle when set', () {
      expect(const WindowConfig(windowTitle: 'Main').toMap(),
          {'windowTitle': 'Main'});
    });

    test('omits windowTitle when null', () {
      expect(const WindowConfig().toMap(), <String, dynamic>{});
    });
  });

  group('lock file name validation', () {
    test('MacOSConfig accepts a simple filename', () {
      expect(MacOSConfig(lockFileName: 'app.lock').lockFileName, 'app.lock');
    });

    test('MacOSConfig rejects path separators', () {
      expect(() => MacOSConfig(lockFileName: 'a/b'),
          throwsA(isA<ArgumentError>()));
    });

    test('LinuxConfig rejects ".."', () {
      expect(
          () => LinuxConfig(lockFileName: '..'), throwsA(isA<ArgumentError>()));
    });

    test('LinuxConfig rejects an empty name', () {
      expect(
          () => LinuxConfig(lockFileName: ''), throwsA(isA<ArgumentError>()));
    });
  });
}
