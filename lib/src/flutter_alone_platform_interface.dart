import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alone_method_channel.dart';

/// 플러그인의 플랫폼 인터페이스
/// 모든 플랫폼 구현체가 따라야 할 인터페이스를 정의합니다.
abstract class FlutterAlonePlatform extends PlatformInterface {
  /// Constructs a FlutterAlonePlatform.
  FlutterAlonePlatform() : super(token: _token);

  static final Object _token = Object();

  /// 현재 플랫폼 구현체의 인스턴스
  static FlutterAlonePlatform _instance = MethodChannelFlutterAlone();

  /// 플랫폼 구현체 인스턴스 getter
  static FlutterAlonePlatform get instance => _instance;

  /// 플랫폼 구현체 설정 메서드
  static set instance(FlutterAlonePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// 앱이 실행 가능한지 확인하고 필요한 초기화를 수행
  ///
  /// Returns:
  /// - true: 앱을 실행할 수 있음
  /// - false: 이미 다른 인스턴스가 실행 중
  Future<bool> checkAndRun() {
    throw UnimplementedError('checkAndRun() has not been implemented.');
  }

  /// 사용된 리소스 정리
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
