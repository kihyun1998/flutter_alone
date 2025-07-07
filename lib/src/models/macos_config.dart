import 'config.dart';

/// Configuration for macOS lock file
class MacOSConfig implements AloneConfig {
  /// The absolute path for the lock file. This is required.
  final String lockFilePath;

  /// Constructor
  const MacOSConfig({
    required this.lockFilePath,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFilePath': lockFilePath,
    };
  }
}