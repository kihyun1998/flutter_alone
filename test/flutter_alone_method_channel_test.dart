import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFlutterAlone', () {
    late MethodChannelFlutterAlone platform;
    final channel = MethodChannel('flutter_alone');
    final log = <MethodCall>[];

    setUp(() {
      platform = MethodChannelFlutterAlone();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'checkAndRun':
            return true;
          case 'dispose':
            return null;
          default:
            throw PlatformException(
              code: 'notImplemented',
              message: 'Method not implemented',
            );
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkAndRun sends correct parameters', () async {
      final messageConfig = MessageConfig(
        type: MessageType.custom,
        customTitle: 'Test Title',
        customMessage: 'Test Message',
        showMessageBox: true,
      );

      await platform.checkAndRun(messageConfig: messageConfig);

      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'custom',
          'customTitle': 'Test Title',
          'customMessage': 'Test Message',
          'showMessageBox': true,
        }),
      );
    });

    test('dispose sends correct method call', () async {
      await platform.dispose();

      expect(log, hasLength(1));
      expect(log.first, isMethodCall('dispose', arguments: null));
    });

    test('checkAndRun throws AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Test error message',
        );
      });

      expect(
        () => platform.checkAndRun(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having((e) => e.message, 'message', 'Test error message'),
        ),
      );
    });

    test('dispose throws AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Dispose error',
        );
      });

      expect(
        () => platform.dispose(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having((e) => e.message, 'message', 'Dispose error'),
        ),
      );
    });
  });
}
