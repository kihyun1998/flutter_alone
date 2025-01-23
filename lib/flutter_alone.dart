import 'package:flutter/material.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'src/flutter_alone_platform_interface.dart';

export 'src/models/message_config.dart';
export 'src/models/message_type.dart';

/// Main class for the Flutter Alone plugin
///
/// Provides functionality to prevent duplicate application instances
class FlutterAlone {
  static final FlutterAlone _instance = FlutterAlone._();
  FlutterAlone._();

  static FlutterAlone get instance => _instance;

  /// Check for duplicate instances and initialize the application
  ///
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun(
      {MessageConfig messageConfig = const MessageConfig()}) async {
    try {
      final result = await FlutterAlonePlatform.instance
          .checkAndRun(messageConfig: messageConfig);
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
