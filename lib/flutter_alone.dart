import 'package:flutter/foundation.dart';
import 'src/models/config.dart';

import 'flutter_alone_platform_interface.dart';

export 'src/models/config.dart';
export 'src/models/exception.dart';
export 'src/models/linux_config.dart';
export 'src/models/macos_config.dart';
export 'src/models/message_config.dart';
export 'src/models/windows_config.dart';

/// Main class for the Flutter Alone plugin.
///
/// Use [FlutterAlone.instance] to access the singleton, then call
/// [checkAndRun] to ensure only one instance of the application runs.
/// Instances must be created via platform-specific factory constructors
/// on [FlutterAloneConfig] (e.g., [FlutterAloneConfig.forWindows]).
class FlutterAlone {
  static final FlutterAlone _instance = FlutterAlone._();
  FlutterAlone._();

  static FlutterAlone get instance => _instance;

  /// Checks for duplicate instances and initializes the application.
  ///
  /// In debug mode, duplicate check is skipped unless [DuplicateCheckConfig.enableInDebugMode] is true.
  ///
  /// Returns:
  /// - true: Application can start (no duplicate instance found)
  /// - false: Another instance is already running
  Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
    if (kDebugMode && !config.duplicateCheckConfig.enableInDebugMode) {
      return true;
    }

    return FlutterAlonePlatform.instance.checkAndRun(config: config);
  }

  /// Clean up resources when application closes.
  Future<void> dispose() async {
    await FlutterAlonePlatform.instance.dispose();
  }
}
