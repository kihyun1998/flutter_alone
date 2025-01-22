import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_alone_platform_interface.dart';

/// An implementation of [FlutterAlonePlatform] that uses method channels.
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_alone');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
