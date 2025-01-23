import 'package:flutter/material.dart';

import 'src/flutter_alone_platform_interface.dart';

/// Main class for the Flutter Alone plugin
///
/// Provides functionality to prevent duplicate application instances
class FlutterAlone {
  // Singleton instance
  static final FlutterAlone _instance = FlutterAlone._();

  // Private constructor
  FlutterAlone._();

  /// Plugin instance getter
  static FlutterAlone get instance => _instance;

  /// Check for duplicate instances and initialize the application
  ///
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun() async {
    try {
      final result = await FlutterAlonePlatform.instance.checkAndRun();
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
