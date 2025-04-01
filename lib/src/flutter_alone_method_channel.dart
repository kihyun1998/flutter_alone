import 'package:flutter/services.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'exception.dart';
import 'flutter_alone_platform_interface.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// Method channel for platform communication
  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun({
    required MessageConfig messageConfig,
  }) async {
    try {
      // Convert message config to map including the mutex name properties
      final map = messageConfig.toMap();

      // Ensure null values are properly handled
      if (map.containsKey(MessageConfigJsonKey.mutexSuffix.key) &&
          map[MessageConfigJsonKey.mutexSuffix.key] == null) {
        map.remove(MessageConfigJsonKey.mutexSuffix.key);
      }

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
