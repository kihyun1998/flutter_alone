import 'config.dart';

/// Configuration for Linux lock file
class LinuxConfig implements AloneConfig {
  /// The name of the lock file. Defaults to '.lockfile'.
  final String lockFileName;

  /// Constructor
  const LinuxConfig({
    this.lockFileName = '.lockfile',
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFileName': lockFileName,
    };
  }
}
