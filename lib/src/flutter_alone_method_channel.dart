import 'package:flutter/services.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'exception.dart';
import 'flutter_alone_platform_interface.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// Method channel for platform communication

  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun(
      {MessageConfig messageConfig = const MessageConfig()}) async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAndRun', {
        'type': messageConfig.type.name,
        'customTitle': messageConfig.customTitle,
        'customMessage': messageConfig.customMessage,
        'showMessageBox': messageConfig.showMessageBox,
      });
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
          details: e.details);
    }
  }
}
