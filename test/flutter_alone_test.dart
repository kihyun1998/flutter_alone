import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {
  // mock 메서드 호출 기록
  bool checkAndRunCalled = false;
  bool disposeCalled = false;
  MessageConfig? lastMessageConfig;

  @override
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    checkAndRunCalled = true;
    lastMessageConfig = messageConfig;
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

  group('메시지 설정 테스트', () {
    test('한국어 메시지 설정이 올바르게 생성되어야 함', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('영어 메시지 설정이 올바르게 생성되어야 함', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('커스텀 메시지가 올바르게 처리되어야 함', () {
      const config =
          CustomMessageConfig(customTitle: '테스트 제목', customMessage: '테스트 메시지');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], '테스트 제목');
      expect(map['customMessage'], '테스트 메시지');
      expect(map['showMessageBox'], true);
    });
  });

  group('플러그인 기본 기능 테스트', () {
    test('checkAndRun이 올바르게 호출되어야 함', () async {
      const messageConfig =
          CustomMessageConfig(customTitle: '테스트', customMessage: '메시지');

      final result =
          await flutterAlone.checkAndRun(messageConfig: messageConfig);

      expect(result, true);
      expect(mockPlatform.checkAndRunCalled, true);
      expect(mockPlatform.lastMessageConfig, messageConfig);
    });

    test('dispose가 올바르게 호출되어야 함', () async {
      await flutterAlone.dispose();
      expect(mockPlatform.disposeCalled, true);
    });
  });
}
