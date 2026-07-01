import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

// Windows mutex names have constraints the native layer enforces (non-empty,
// <= 260 chars, no backslash after the namespace prefix). Previously the native
// side rejected a bad name by returning false, which checkAndRun reports as
// "already running" -- so the app silently exits. Validating in Dart surfaces
// the misconfiguration as an ArgumentError instead.

void main() {
  group('WindowsMutexConfig name validation', () {
    test('rejects a name longer than the 260-char Windows limit', () {
      final config = DefaultWindowsMutexConfig(
        packageId: 'com.test.app',
        appName: 'a' * 300, // pushes the full mutex name well past 260
      );

      expect(() => config.getMutexName(), throwsA(isA<ArgumentError>()));
    });

    test('rejects a backslash after the Global prefix (Default)', () {
      // A backslash embedded in appName lands after the Global\ prefix.
      const config = DefaultWindowsMutexConfig(
        packageId: 'com.test.app',
        appName: r'Team\App',
      );

      expect(() => config.getMutexName(), throwsA(isA<ArgumentError>()));
    });

    test('rejects a backslash after the Global prefix (Custom)', () {
      final config = CustomWindowsMutexConfig(customMutexName: r'Team\App');

      expect(() => config.getMutexName(), throwsA(isA<ArgumentError>()));
    });

    test('accepts a normal name and returns it unchanged', () {
      const config = DefaultWindowsMutexConfig(
        packageId: 'com.example.app',
        appName: 'MyApp',
      );

      expect(config.getMutexName(), r'Global\com.example.app_MyApp');
    });

    test('accepts a name at the 260 limit but rejects one over it', () {
      // 'Global\'(7) + packageId 'p'(1) + '_'(1) => 9 chars of overhead,
      // so an appName of 251 makes the full name exactly 260.
      String nameFor(int appLen) => DefaultWindowsMutexConfig(
            packageId: 'p',
            appName: 'a' * appLen,
          ).getMutexName();

      expect(nameFor(251).length, 260); // at the limit: allowed
      expect(
          () => nameFor(252), throwsA(isA<ArgumentError>())); // 261: rejected
    });

    test('an invalid name surfaces through FlutterAloneConfig serialization',
        () {
      // This is the real checkAndRun path: a bad name now throws instead of
      // producing a map the native side would silently reject (issue #2).
      final config = FlutterAloneConfig.forWindows(
        windowsConfig: DefaultWindowsMutexConfig(
          packageId: 'com.test.app',
          appName: 'a' * 300,
        ),
        messageConfig: const EnMessageConfig(),
      );

      expect(
        () => config.toMapFor(AlonePlatform.windows),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
