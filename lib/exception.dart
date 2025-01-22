class AloneException implements Exception {
  /// 에러 코드
  final String code;

  /// 에러 메시지
  final String message;

  /// 추가 상세 정보
  final dynamic details;

  AloneException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AloneException($code): $message';
}
