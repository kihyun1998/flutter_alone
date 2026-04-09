import 'package:flutter/services.dart';

import 'flutter_alone_platform_interface.dart';
import 'src/models/config.dart';
import 'src/models/exception.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    try {
      final map = config.toMap();

      final result = await _channel.invokeMethod<bool>(
        'checkAndRun',
        map,
      );

      // In debug mode, assert that the platform returned a valid result
      assert(result != null, 'flutter_alone: platform returned null from checkAndRun');

      // In release mode, treat null as "cannot run" (safety-first)
      return result ?? false;
    } on PlatformException catch (e) {
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error checking application instance',
        details: e.details,
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException catch (e) {
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error disposing resources',
        details: e.details,
      );
    }
  }
}
