import 'package:flutter/material.dart';
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
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    try {
      debugPrint('[DEBUG] MethodChannel checkAndRun 호출');
      final result = await _channel.invokeMethod<bool>(
        'checkAndRun',
        messageConfig.toMap(),
      );
      debugPrint('[DEBUG] 파라미터: ${messageConfig.toMap()}');
      debugPrint('[DEBUG] MethodChannel 결과: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[DEBUG] MethodChannel 에러:');
      debugPrint('  코드: ${e.code}');
      debugPrint('  메시지: ${e.message}');
      debugPrint('  상세: ${e.details}');

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
