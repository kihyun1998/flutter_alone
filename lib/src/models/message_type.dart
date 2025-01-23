enum MessageType {
  ko,
  en,
  custom;

  String getTitle(String? customTitle) {
    switch (this) {
      case MessageType.ko:
        return '실행 오류';
      case MessageType.en:
        return 'Execution Error';
      case MessageType.custom:
        return customTitle ?? 'Error';
    }
  }

  String getMessage(String domain, String userName, String? customMessage) {
    switch (this) {
      case MessageType.ko:
        return '이미 다른 사용자가 앱을 실행중입니다.\n실행 중인 사용자: $domain\\$userName';
      case MessageType.en:
        return 'Application is already running by another user.\nRunning user: $domain\\$userName';
      case MessageType.custom:
        return customMessage ?? 'Another instance is running';
    }
  }
}
