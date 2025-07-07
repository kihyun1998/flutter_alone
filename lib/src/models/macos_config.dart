import 'config.dart';

/// Configuration for macOS lock file
class MacOSConfig implements AloneConfig {
  /// The name of the lock file. Defaults to '.lockfile'.
  final String lockFileName;

  /// Constructor
  const MacOSConfig({
    this.lockFileName = '.lockfile',
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFileName': lockFileName,
    };
  }
}