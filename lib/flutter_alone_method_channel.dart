import 'package:flutter/foundation.dart'; // Add this import for VoidCallback
import 'package:flutter/services.dart';

import 'flutter_alone_platform_interface.dart';
import 'src/models/config.dart';
import 'src/models/exception.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// Method channel for platform communication
  final MethodChannel _channel = const MethodChannel('flutter_alone');

  // Store the onDuplicateLaunch callback
  VoidCallback? _onDuplicateLaunchCallback;

  MethodChannelFlutterAlone() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  Future<bool> checkAndRun({
    required FlutterAloneConfig config,
    VoidCallback? onDuplicateLaunch,
  }) async {
    debugPrint('MethodChannelFlutterAlone: checkAndRun called');
    _onDuplicateLaunchCallback = onDuplicateLaunch; // Store the callback

    try {
      // Convert config to map
      final map = config.toMap();

      // Remove null values
      map.removeWhere((key, value) => value == null);

      final result = await _channel.invokeMethod<bool>(
        'checkAndRun',
        map,
      );
      debugPrint('MethodChannelFlutterAlone: checkAndRun result: \(result)');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('MethodChannelFlutterAlone: Error in checkAndRun: \(e.message)');
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error checking application instance',
        details: e.details,
      );
    }
  }

  @override
  Future<void> dispose() async {
    debugPrint('MethodChannelFlutterAlone: dispose called');
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException catch (e) {
      debugPrint('MethodChannelFlutterAlone: Error in dispose: \(e.message)');
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error disposing resources',
        details: e.details,
      );
    }
  }

  // Handle method calls from native side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('MethodChannelFlutterAlone: _handleMethodCall received: \(call.method)');
    switch (call.method) {
      case 'onDuplicateLaunch':
        debugPrint('MethodChannelFlutterAlone: Invoking onDuplicateLaunch callback');
        _onDuplicateLaunchCallback?.call(); // Invoke the stored callback
        return null;
      default:
        debugPrint('MethodChannelFlutterAlone: Unimplemented method: \(call.method)');
        throw PlatformException(
          code: 'Unimplemented',
          message: 'Method ${call.method} not implemented on MethodChannelFlutterAlone',
        );
    }
  }
}
