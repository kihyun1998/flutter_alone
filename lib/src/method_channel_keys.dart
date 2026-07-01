/// Method-channel argument keys shared across the `AloneConfig` serializations.
///
/// Centralizing these here keeps the Dart-side protocol keys in one place so a
/// rename cannot silently diverge between config classes. The native platforms
/// carry their own copies of these strings (they cannot share a Dart source), so
/// any change here must be mirrored in `windows/`, `macos/`, and `linux/`.
abstract final class MethodChannelKeys {
  static const String enableInDebugMode = 'enableInDebugMode';
  static const String windowTitle = 'windowTitle';
  static const String mutexName = 'mutexName';
  static const String lockFileName = 'lockFileName';
  static const String type = 'type';
  static const String showMessageBox = 'showMessageBox';
  static const String title = 'title';
  static const String message = 'message';
  static const String customTitle = 'customTitle';
  static const String customMessage = 'customMessage';
}
