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

  /// Checks for duplicate instances and initializes the application
  ///
  /// This method ensures only one instance of the application runs by creating a system mutex.
  /// When a duplicate instance is detected, it either activates the existing window
  /// or displays a message to the user.
  ///
  /// Parameters:
  /// - messageConfig: Configuration object containing all settings including:
  ///   * Message display settings (title, content, language)
  ///   * Mutex configuration (packageId, appName, mutexSuffix)
  ///   * Debug mode settings (enableInDebugMode)
  ///   * Window management settings (windowTitle)
  ///
  /// In debug mode, duplicate check is skipped unless enableInDebugMode is set to true
  /// in the messageConfig.
  ///
  /// Returns:
  /// - true: Application can start (no duplicate instance found)
  /// - false: Another instance is already running
  Future<bool> checkAndRun({required MessageConfig messageConfig}) async {
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
