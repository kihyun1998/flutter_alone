enum ProcessInfoJsonKey {
  domain,
  userName,
  processId,
  ;

  String get key {
    switch (this) {
      case ProcessInfoJsonKey.domain:
        return 'domain';
      case ProcessInfoJsonKey.userName:
        return 'userName';
      case ProcessInfoJsonKey.processId:
        return 'processId';
    }
  }
}

class ProcessInfo {
  /// 실행 중인 사용자의 도메인 (예: DESKTOP-123)
  final String domain;

  /// 실행 중인 사용자의 이름
  final String userName;

  /// 프로세스 ID
  final int processId;

  ProcessInfo({
    required this.domain,
    required this.userName,
    required this.processId,
  });

  /// JSON으로부터 ProcessInfo 객체 생성
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      domain: json[ProcessInfoJsonKey.domain.key] as String,
      userName: json[ProcessInfoJsonKey.userName.key] as String,
      processId: json[ProcessInfoJsonKey.processId.key] as int,
    );
  }

  /// ProcessInfo 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      ProcessInfoJsonKey.domain.key: domain,
      ProcessInfoJsonKey.userName.key: userName,
      ProcessInfoJsonKey.processId.key: processId,
    };
  }

  ProcessInfo copyWith({
    String? domain,
    String? userName,
    int? processId,
  }) {
    return ProcessInfo(
      domain: domain ?? this.domain,
      userName: userName ?? this.userName,
      processId: processId ?? this.processId,
    );
  }

  @override
  String toString() {
    return '$domain\\$userName (PID: $processId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessInfo &&
        other.domain == domain &&
        other.userName == userName &&
        other.processId == processId;
  }

  @override
  int get hashCode => Object.hash(domain, userName, processId);
}
