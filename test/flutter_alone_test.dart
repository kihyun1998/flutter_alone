import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {
  // Record mock method calls
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

  group('Message configuration tests', () {
    test('Korean message config should be created correctly', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('English message config should be created correctly', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('Custom message should be handled correctly', () {
      const config = CustomMessageConfig(
          customTitle: 'Test Title', customMessage: 'Test Message');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['customMessage'], 'Test Message');
      expect(map['showMessageBox'], true);
    });
  });

  group('Plugin basic functionality tests', () {
    test('checkAndRun should be called correctly', () async {
      const messageConfig =
          CustomMessageConfig(customTitle: 'Test', customMessage: 'Message');

      final result =
          await flutterAlone.checkAndRun(messageConfig: messageConfig);

      expect(result, true);
      expect(mockPlatform.checkAndRunCalled, true);
      expect(mockPlatform.lastMessageConfig, messageConfig);
    });

    test('dispose should be called correctly', () async {
      await flutterAlone.dispose();
      expect(mockPlatform.disposeCalled, true);
    });
  });
}
