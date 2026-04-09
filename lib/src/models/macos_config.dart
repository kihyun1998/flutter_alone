import 'config.dart';

/// Configuration for macOS lock file.
///
/// The lock file is placed in the system temporary directory
/// (typically `/var/folders/.../T/` on macOS).
/// Use a unique name per app to avoid collisions with other apps using this plugin.
class MacOSConfig implements AloneConfig {
  /// The name of the lock file.
  /// Must be a simple filename without path separators.
  /// Defaults to '.lockfile'.
  final String lockFileName;

  MacOSConfig({
    this.lockFileName = '.lockfile',
  }) {
    if (lockFileName.isEmpty ||
        lockFileName.contains('/') ||
        lockFileName.contains(r'\') ||
        lockFileName.contains('\x00') ||
        lockFileName == '.' ||
        lockFileName == '..') {
      throw ArgumentError.value(
        lockFileName,
        'lockFileName',
        'Must be a non-empty simple filename without path separators or special names',
      );
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'lockFileName': lockFileName,
    };
  }
}
