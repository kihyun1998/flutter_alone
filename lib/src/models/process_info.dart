// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ProcessInfoJsonKey {
  processId,
  windowHandle,
  processPath,
  startTime,
  ;

  String get key => toString().split('.').last;
}

/// Model class for process information
class ProcessInfo {
  /// Process ID
  final int processId;

  /// Window handle
  final int windowHandle;

  /// Process path
  final String processPath;

  /// Process start time (Windows FILETIME)
  final int startTime;

  ProcessInfo({
    required this.processId,
    required this.windowHandle,
    required this.processPath,
    required this.startTime,
  });

  /// Create ProcessInfo from JSON
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      processId: json[ProcessInfoJsonKey.processId.key] as int,
      windowHandle: json[ProcessInfoJsonKey.windowHandle.key] as int,
      processPath: json[ProcessInfoJsonKey.processPath.key] as String,
      startTime: json[ProcessInfoJsonKey.startTime.key] as int,
    );
  }

  /// Convert ProcessInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      ProcessInfoJsonKey.processId.key: processId,
      ProcessInfoJsonKey.windowHandle.key: windowHandle,
      ProcessInfoJsonKey.processPath.key: processPath,
      ProcessInfoJsonKey.startTime.key: startTime,
    };
  }

  ProcessInfo copyWith({
    int? processId,
    int? windowHandle,
    String? processPath,
    int? startTime,
  }) {
    return ProcessInfo(
      processId: processId ?? this.processId,
      windowHandle: windowHandle ?? this.windowHandle,
      processPath: processPath ?? this.processPath,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessInfo &&
        other.processId == processId &&
        other.windowHandle == windowHandle &&
        other.processPath == processPath &&
        other.startTime == startTime;
  }

  @override
  int get hashCode => Object.hash(
        processId,
        windowHandle,
        processPath,
        startTime,
      );
}
