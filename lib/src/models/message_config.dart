// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_alone/src/models/message_type.dart';

class MessageConfig {
  /// Message type (ko, en, custom)
  final MessageType type;

  /// Custom title (type이 custom일 때 사용)
  final String? customTitle;

  /// Custom message (type이 custom일 때 사용)
  final String? customMessage;

  /// is show message box?
  final bool showMessageBox;
  const MessageConfig({
    this.type = MessageType.en,
    this.customTitle,
    this.customMessage,
    this.showMessageBox = true,
  });

  MessageConfig copyWith({
    MessageType? type,
    String? customTitle,
    String? customMessage,
    bool? showMessageBox,
  }) {
    return MessageConfig(
      type: type ?? this.type,
      customTitle: customTitle ?? this.customTitle,
      customMessage: customMessage ?? this.customMessage,
      showMessageBox: showMessageBox ?? this.showMessageBox,
    );
  }
}
