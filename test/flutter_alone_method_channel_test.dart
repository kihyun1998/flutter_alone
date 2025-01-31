import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Method Channel Tests', () {
    late MethodChannelFlutterAlone platform;
    final channel = MethodChannel('flutter_alone');
    final List<MethodCall> log = <MethodCall>[];

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
              code: 'not_implemented',
              message: 'Method not implemented',
              details: 'No implementation found for ${methodCall.method}',
            );
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkAndRun should handle message configurations correctly',
        () async {
      final messageConfig = CustomMessageConfig(
        customTitle: 'Custom Title',
        customMessage: 'App running as {domain}\\{userName}',
        showMessageBox: true,
      );

      final result = await platform.checkAndRun(messageConfig: messageConfig);

      // Verify method call
      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'custom',
          'customTitle': 'Custom Title',
          'messageTemplate': 'App running as {domain}\\{userName}',
          'showMessageBox': true,
        }),
      );

      // Verify result
      expect(result, isTrue);
    });

    test('dispose should clean up resources properly', () async {
      await platform.dispose();

      // Verify method call
      expect(log, hasLength(1));
      expect(log.first, isMethodCall('dispose', arguments: null));
    });

    test('checkAndRun should throw AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Test error message',
          details: 'Error details',
        );
      });

      expect(
        () => platform.checkAndRun(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having((e) => e.message, 'message', 'Test error message')
              .having((e) => e.details, 'details', 'Error details'),
        ),
      );
    });

    test('dispose should throw AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Failed to dispose resources',
          details: 'Cleanup error details',
        );
      });

      expect(
        () => platform.dispose(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having(
                  (e) => e.message, 'message', 'Failed to dispose resources')
              .having((e) => e.details, 'details', 'Cleanup error details'),
        ),
      );
    });
  });
}
