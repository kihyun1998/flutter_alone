import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/flutter_alone_platform_interface.dart';
import 'package:flutter_alone/flutter_alone_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterAlonePlatform initialPlatform = FlutterAlonePlatform.instance;

  test('$MethodChannelFlutterAlone is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAlone>());
  });

  test('getPlatformVersion', () async {
    FlutterAlone flutterAlonePlugin = FlutterAlone();
    MockFlutterAlonePlatform fakePlatform = MockFlutterAlonePlatform();
    FlutterAlonePlatform.instance = fakePlatform;

    expect(await flutterAlonePlugin.getPlatformVersion(), '42');
  });
}
