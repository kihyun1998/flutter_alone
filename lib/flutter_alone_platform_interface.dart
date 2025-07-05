import 'package:flutter/foundation.dart'; // Add this import for VoidCallback
import 'package:flutter_alone/src/models/config.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alone_method_channel.dart';

/// Platform interface for the plugin
/// Defines the interface that all platform implementations must follow
abstract class FlutterAlonePlatform extends PlatformInterface {
  /// Constructs a FlutterAlonePlatform
  FlutterAlonePlatform() : super(token: _token);

  static final Object _token = Object();

  /// Current platform implementation instance
  static FlutterAlonePlatform _instance = MethodChannelFlutterAlone();

  /// Platform implementation instance getter
  static FlutterAlonePlatform get instance => _instance;

  /// Platform implementation setter
  static set instance(FlutterAlonePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check if application can run and perform initialization
  ///
  /// Parameters:
  /// - config: Combined configuration object
  /// - onDuplicateLaunch: Optional callback function invoked when a duplicate instance is detected.
  ///   This allows custom handling of the event, e.g., showing the main window or focusing it.
  ///
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun({
    required FlutterAloneConfig config,
    VoidCallback? onDuplicateLaunch,
  }) {
    throw UnimplementedError('checkAndRun() has not been implemented.');
  }

  /// Clean up resources
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
