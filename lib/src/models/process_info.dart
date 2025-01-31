enum ProcessInfoJsonKey {
  domain,
  userName,
  processId,
  windowHandle,
  processPath,
  startTime,
  ;

  String get key => toString().split('.').last;
}

/// Model class for process information
class ProcessInfo {
  /// Domain of the running user (e.g., DESKTOP-123)
  final String domain;

  /// Username of the running user
  final String userName;

  /// Process ID
  final int processId;

  /// Window handle
  final int windowHandle;

  /// Process path
  final String processPath;

  /// Process start time (Windows FILETIME)
  final int startTime;

  ProcessInfo({
    required this.domain,
    required this.userName,
    required this.processId,
    required this.windowHandle,
    required this.processPath,
    required this.startTime,
  });

  /// Create ProcessInfo from JSON
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      domain: json[ProcessInfoJsonKey.domain.key] as String,
      userName: json[ProcessInfoJsonKey.userName.key] as String,
      processId: json[ProcessInfoJsonKey.processId.key] as int,
      windowHandle: json[ProcessInfoJsonKey.windowHandle.key] as int,
      processPath: json[ProcessInfoJsonKey.processPath.key] as String,
      startTime: json[ProcessInfoJsonKey.startTime.key] as int,
    );
  }

  /// Convert ProcessInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      ProcessInfoJsonKey.domain.key: domain,
      ProcessInfoJsonKey.userName.key: userName,
      ProcessInfoJsonKey.processId.key: processId,
      ProcessInfoJsonKey.windowHandle.key: windowHandle,
      ProcessInfoJsonKey.processPath.key: processPath,
      ProcessInfoJsonKey.startTime.key: startTime,
    };
  }

  ProcessInfo copyWith({
    String? domain,
    String? userName,
    int? processId,
    int? windowHandle,
    String? processPath,
    int? startTime,
  }) {
    return ProcessInfo(
      domain: domain ?? this.domain,
      userName: userName ?? this.userName,
      processId: processId ?? this.processId,
      windowHandle: windowHandle ?? this.windowHandle,
      processPath: processPath ?? this.processPath,
      startTime: startTime ?? this.startTime,
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
        other.processId == processId &&
        other.windowHandle == windowHandle &&
        other.processPath == processPath &&
        other.startTime == startTime;
  }

  @override
  int get hashCode => Object.hash(
        domain,
        userName,
        processId,
        windowHandle,
        processPath,
        startTime,
      );
}
