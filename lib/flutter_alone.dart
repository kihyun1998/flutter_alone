import 'package:flutter/foundation.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'src/flutter_alone_platform_interface.dart';

export 'src/exception.dart';
export 'src/models/message_config.dart';

/// Main class for the Flutter Alone plugin
class FlutterAlone {
  static final FlutterAlone _instance = FlutterAlone._();
  FlutterAlone._();

  static FlutterAlone get instance => _instance;

  /// Check for duplicate instances and initialize the application
  ///
  /// In debug mode, duplicate check is skipped unless enableInDebugMode is true
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    try {
      // Skip duplicate check in debug mode unless explicitly enabled
      if (kDebugMode && !messageConfig.enableInDebugMode) {
        return true;
      }

      final result = await FlutterAlonePlatform.instance.checkAndRun(
        messageConfig: messageConfig,
      );
      return result;
    } catch (e) {
      debugPrint('Error checking application instance: $e');
      rethrow;
    }
  }

  /// Clean up resources when application closes
  Future<void> dispose() async {
    try {
      await FlutterAlonePlatform.instance.dispose();
    } catch (e) {
      debugPrint('Error cleaning up resources: $e');
      rethrow;
    }
  }
}
