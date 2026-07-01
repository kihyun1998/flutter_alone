import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

// Characterization tests for the method-channel layer: result passthrough and
// the PlatformException -> AloneException error contract. The mock handler
// ignores the arguments, so a config valid on the current runner OS is enough.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_alone');
  final platform = MethodChannelFlutterAlone();
  final log = <MethodCall>[];

  // A config whose toMap() succeeds on whichever OS the test runs on (toMap
  // branches on the runtime platform and throws for a mismatched config).
  FlutterAloneConfig config() {
    if (Platform.isWindows) {
      return FlutterAloneConfig.forWindows(
        windowsConfig: const DefaultWindowsMutexConfig(
          packageId: 'com.test.app',
          appName: 'TestApp',
        ),
        messageConfig: const EnMessageConfig(),
      );
    }
    if (Platform.isMacOS) {
      return FlutterAloneConfig.forMacOS(
        macOSConfig: MacOSConfig(lockFileName: 'test.lock'),
        messageConfig: const EnMessageConfig(),
      );
    }
    return FlutterAloneConfig.forLinux(
      linuxConfig: LinuxConfig(lockFileName: 'test.lock'),
      messageConfig: const EnMessageConfig(),
    );
  }

  void setHandler(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
      log.add(call);
      return handler(call);
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    log.clear();
  });

  test('checkAndRun returns true when the platform returns true', () async {
    setHandler((_) async => true);

    expect(await platform.checkAndRun(config: config()), isTrue);
  });

  test('checkAndRun returns false when the platform returns false', () async {
    setHandler((_) async => false);

    expect(await platform.checkAndRun(config: config()), isFalse);
  });

  test('checkAndRun invokes "checkAndRun" with the serialized config',
      () async {
    setHandler((_) async => true);

    await platform.checkAndRun(config: config());

    expect(log, hasLength(1));
    expect(log.single.method, 'checkAndRun');
    expect(log.single.arguments, isA<Map>());
    // The message config is serialized on every platform.
    expect((log.single.arguments as Map)['type'], 'en');
  });

  test('checkAndRun maps a PlatformException to AloneException', () async {
    setHandler((_) async => throw PlatformException(
          code: 'MUTEX_ERROR',
          message: 'boom',
          details: 'extra',
        ));

    await expectLater(
      () => platform.checkAndRun(config: config()),
      throwsA(isA<AloneException>()
          .having((e) => e.code, 'code', 'MUTEX_ERROR')
          .having((e) => e.message, 'message', 'boom')
          .having((e) => e.details, 'details', 'extra')),
    );
  });

  test('checkAndRun uses a default message when the exception has none',
      () async {
    setHandler((_) async => throw PlatformException(code: 'X'));

    await expectLater(
      () => platform.checkAndRun(config: config()),
      throwsA(isA<AloneException>().having(
        (e) => e.message,
        'message',
        'Error checking application instance',
      )),
    );
  });

  test('checkAndRun asserts on a null platform result (debug safety guard)',
      () async {
    setHandler((_) async => null);

    await expectLater(
      () => platform.checkAndRun(config: config()),
      throwsA(isA<AssertionError>()),
    );
  });

  test('dispose invokes "dispose"', () async {
    setHandler((_) async => null);

    await platform.dispose();

    expect(log.single.method, 'dispose');
  });

  test('dispose maps a PlatformException to AloneException', () async {
    setHandler((_) async => throw PlatformException(code: 'DISPOSE_ERR'));

    await expectLater(
      () => platform.dispose(),
      throwsA(isA<AloneException>()
          .having((e) => e.code, 'code', 'DISPOSE_ERR')
          .having((e) => e.message, 'message', 'Error disposing resources')),
    );
  });
}
