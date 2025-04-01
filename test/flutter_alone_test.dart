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
  Map<String, dynamic>? lastArguments; // 변경: 객체 대신 Map 저장

  @override
  Future<bool> checkAndRun({required MessageConfig messageConfig}) async {
    checkAndRunCalled = true;
    lastArguments = messageConfig.toMap(); // 객체가 아닌 Map을 저장
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
      const config =
          KoMessageConfig(packageId: 'com.test.app', appName: 'TestApp');
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('English message config should be created correctly', () {
      const config =
          EnMessageConfig(packageId: 'com.test.app', appName: 'TestApp');
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('Custom message should be handled correctly', () {
      const config = CustomMessageConfig(
          customTitle: 'Test Title',
          customMessage: 'Test Message',
          packageId: 'com.test.app',
          appName: 'TestApp');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['customMessage'], 'Test Message');
      expect(map['showMessageBox'], true);
    });
  });

  group('Plugin basic functionality tests', () {
    // test('checkAndRun should pass correct data to platform', () async {
    //   const messageConfig =
    //       CustomMessageConfig(customTitle: 'Test', customMessage: 'Message');

    //   final result =
    //       await flutterAlone.checkAndRun(messageConfig: messageConfig);

    //   expect(result, true);
    //   expect(mockPlatform.checkAndRunCalled, true);

    //   // Map을 사용한 검증
    //   final args = mockPlatform.lastArguments;
    //   expect(args, isNotNull);
    //   expect(args!['type'], 'custom');
    //   expect(args['customTitle'], 'Test');
    //   expect(args['customMessage'], 'Message');
    // });

    test('dispose should be called correctly', () async {
      await flutterAlone.dispose();
      expect(mockPlatform.disposeCalled, true);
    });
  });

  test('Window title should be handled correctly in config', () {
    const windowTitle = 'My Application Window';
    const config = CustomMessageConfig(
      customTitle: 'Test',
      customMessage: 'Message',
      packageId: 'com.test.app',
      appName: 'TestApp',
      windowTitle: windowTitle,
    );
    final map = config.toMap();

    expect(map['windowTitle'], windowTitle);
  });

  // test('Window title should be passed to platform correctly', () async {
  //   const windowTitle = 'My Application Window';
  //   const messageConfig = CustomMessageConfig(
  //     customTitle: 'Test',
  //     customMessage: 'Message',
  //     windowTitle: windowTitle,
  //   );

  //   await flutterAlone.checkAndRun(messageConfig: messageConfig);

  //   expect(mockPlatform.checkAndRunCalled, true);

  //   // Map을 사용한 검증
  //   final args = mockPlatform.lastArguments;
  //   expect(args, isNotNull);
  //   expect(args!['windowTitle'], windowTitle);
  // });
}
