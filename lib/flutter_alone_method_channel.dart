import 'package:flutter/services.dart';

import 'flutter_alone_platform_interface.dart';
import 'src/models/config.dart';
import 'src/models/exception.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// Method channel for platform communication
  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    try {
      // Convert config to map
      final map = config.toMap();

      // Remove null values
      map.removeWhere((key, value) => value == null);

      final result = await _channel.invokeMethod<bool>(
        'checkAndRun',
        map,
      );
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
