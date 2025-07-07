import 'package:flutter/foundation.dart';
import 'package:flutter_alone/src/models/config.dart';

import 'flutter_alone_platform_interface.dart';

export 'src/models/config.dart';
export 'src/models/exception.dart';
export 'src/models/macos_config.dart';
export 'src/models/message_config.dart';
export 'src/models/windows_config.dart';

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
  /// - config: Configuration object containing all settings including:
  ///   * Message display settings (messageConfig)
  ///   * Mutex configuration (mutexConfig)
  ///   * Debug mode settings (duplicateCheckConfig)
  ///   * Window management settings (windowConfig)
  ///
  /// In debug mode, duplicate check is skipped unless enableInDebugMode is set to true
  /// in the duplicateCheckConfig.
  ///
  /// Returns:
  /// - true: Application can start (no duplicate instance found)
  /// - false: Another instance is already running
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    try {
      // Skip duplicate check in debug mode unless explicitly enabled
      if (kDebugMode && !config.duplicateCheckConfig.enableInDebugMode) {
        return true;
      }

      final result = await FlutterAlonePlatform.instance.checkAndRun(
        config: config,
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
