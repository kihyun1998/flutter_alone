import '../method_channel_keys.dart';
import 'config.dart';

/// Base abstract class for message configuration.
///
/// This is the single source of truth for the "already running" dialog text.
/// Each config resolves a [title] and [message] that are sent to the native
/// platforms via [toMap]; the native side only displays them, so the strings
/// live in exactly one place and cannot drift between platforms.
abstract class MessageConfig implements AloneConfig {
  /// Canonical Korean strings.
  static const String koTitle = '알림';
  static const String koMessage = '이미 다른 계정에서 앱을 실행중입니다.';

  /// Canonical English strings (also the fallback for an empty custom value).
  static const String enTitle = 'Notice';
  static const String enMessage =
      'Application is already running in another account.';

  /// Whether to show a message box when a duplicate instance is detected.
  final bool showMessageBox;

  const MessageConfig({
    this.showMessageBox = true,
  });

  /// Subclasses provide their type string ('ko', 'en', 'custom').
  String get typeString;

  /// The resolved dialog title shown by every platform.
  String get title;

  /// The resolved dialog body shown by every platform.
  String get message;

  @override
  Map<String, dynamic> toMap() {
    return {
      MethodChannelKeys.type: typeString,
      MethodChannelKeys.showMessageBox: showMessageBox,
      MethodChannelKeys.title: title,
      MethodChannelKeys.message: message,
    };
  }
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  const KoMessageConfig({
    super.showMessageBox,
  });

  @override
  String get typeString => 'ko';

  @override
  String get title => MessageConfig.koTitle;

  @override
  String get message => MessageConfig.koMessage;
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  const EnMessageConfig({
    super.showMessageBox,
  });

  @override
  String get typeString => 'en';

  @override
  String get title => MessageConfig.enTitle;

  @override
  String get message => MessageConfig.enMessage;
}

/// Custom message configuration
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  final String customMessage;

  const CustomMessageConfig({
    required this.customTitle,
    required this.customMessage,
    super.showMessageBox,
  });

  @override
  String get typeString => 'custom';

  /// Falls back to the English default when the custom value is empty, matching
  /// the previous per-platform behavior.
  @override
  String get title => customTitle.isEmpty ? MessageConfig.enTitle : customTitle;

  @override
  String get message =>
      customMessage.isEmpty ? MessageConfig.enMessage : customMessage;

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      MethodChannelKeys.customTitle: customTitle,
      MethodChannelKeys.customMessage: customMessage,
    };
  }
}
