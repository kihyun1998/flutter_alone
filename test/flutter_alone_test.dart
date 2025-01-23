import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {
  bool checkAndRunResult = true;
  bool disposeCalled = false;

  @override
  Future<bool> checkAndRun() async => checkAndRunResult;
  @override
  Future<void> dispose() async => disposeCalled = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FlutterAlone', () {
    late MockFlutterAlonePlatform fakePlatform;

    setUp(() {
      fakePlatform = MockFlutterAlonePlatform();
      FlutterAlonePlatform.instance = fakePlatform;
    });

    test('checkAndRun returns true when no instance is running', () async {
      expect(await FlutterAlone.instance.checkAndRun(), true);
    });

    test('checkAndRun returns false when instance is already running',
        () async {
      fakePlatform.checkAndRunResult = false;
      expect(await FlutterAlone.instance.checkAndRun(), false);
    });

    test('dispose calls platform dispose', () async {
      await FlutterAlone.instance.dispose();
      expect(fakePlatform.disposeCalled, true);
    });
  });
}
