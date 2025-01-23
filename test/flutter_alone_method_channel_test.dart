import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFlutterAlone', () {
    const MethodChannel channel = MethodChannel('flutter_alone');
    final MethodChannelFlutterAlone platform = MethodChannelFlutterAlone();
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      // 메서드 채널 핸들러 설정
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'checkAndRun':
            return true;
          case 'dispose':
            return null;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      // 테스트 후 로그 초기화
      log.clear();
    });

    test('checkAndRun', () async {
      await platform.checkAndRun();
      expect(
        log,
        <Matcher>[isMethodCall('checkAndRun', arguments: null)],
      );
    });

    test('dispose', () async {
      await platform.dispose();
      expect(
        log,
        <Matcher>[isMethodCall('dispose', arguments: null)],
      );
    });
  });
}
