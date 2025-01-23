import 'package:flutter/services.dart';
import 'package:flutter_alone/exception.dart';

import 'flutter_alone_platform_interface.dart';

/// MethodChannel을 사용한 플랫폼 구현체
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// 플랫폼과의 통신을 위한 메서드 채널

  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkAndRun');
      return result ?? false;
    } on PlatformException catch (e) {
      throw AloneException(
          code: e.code,
          message: e.message ?? 'Unknown error occurred',
          details: e.details);
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
