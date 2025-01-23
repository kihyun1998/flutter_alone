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

/// Model class for process information
class ProcessInfo {
  /// Domain of the running user (e.g., DESKTOP-123)
  final String domain;

  /// Username of the running user
  final String userName;

  /// Process ID
  final int processId;

  ProcessInfo({
    required this.domain,
    required this.userName,
    required this.processId,
  });

  /// Create ProcessInfo from JSON
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      domain: json[ProcessInfoJsonKey.domain.key] as String,
      userName: json[ProcessInfoJsonKey.userName.key] as String,
      processId: json[ProcessInfoJsonKey.processId.key] as int,
    );
  }

  /// Convert ProcessInfo to JSON
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
