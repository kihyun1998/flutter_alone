class AloneException implements Exception {
  /// Error code
  final String code;

  /// Error message
  final String message;

  /// Additional details
  final dynamic details;

  AloneException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() =>
      'AloneException($code): $message${details != null ? ' [$details]' : ''}';
}
