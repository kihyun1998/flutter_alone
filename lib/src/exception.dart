class AloneException implements Exception {
  /// error code
  final String code;

  /// error message
  final String message;

  /// additional details
  final dynamic details;

  AloneException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AloneException($code): $message';
}
