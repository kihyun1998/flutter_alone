import 'config.dart';

/// Base abstract class for macOS lock file configuration
abstract class MacOSLockConfig implements AloneConfig {
  /// Constructor
  const MacOSLockConfig();

  /// Get the lock file path to be used
  String getLockFilePath();
}

/// Configuration for lock file path using app name
class DefaultMacOSLockConfig extends MacOSLockConfig {
  /// Application name for lock file path generation
  final String appName;

  /// Constructor
  const DefaultMacOSLockConfig({
    required this.appName,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFilePath': getLockFilePath(),
    };
  }

  @override
  String getLockFilePath() {
    // This is a placeholder. In a real implementation, 
    // you would use path_provider to get the application support directory.
    return '/tmp/$appName.lock';
  }
}

/// Configuration for lock file using a custom path
class CustomMacOSLockConfig extends MacOSLockConfig {
  /// Custom lock file path to use directly
  final String customLockFilePath;

  /// Constructor
  const CustomMacOSLockConfig({
    required this.customLockFilePath,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFilePath': getLockFilePath(),
    };
  }

  @override
  String getLockFilePath() {
    return customLockFilePath;
  }
}