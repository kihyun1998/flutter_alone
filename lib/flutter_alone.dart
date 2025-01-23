import 'package:flutter/material.dart';

import 'src/flutter_alone_platform_interface.dart';

/// Flutter Alone 플러그인의 메인 클래스
///
/// 앱의 중복 실행을 방지하기 위한 기능을 제공합니다.
class FlutterAlone {
  // 싱글톤 인스턴스
  static final FlutterAlone _instance = FlutterAlone._();

  // private 생성자
  FlutterAlone._();

  /// 플러그인 인스턴스 getter
  static FlutterAlone get instance => _instance;

  /// 앱의 중복 실행 여부를 확인하고 초기화를 수행
  ///
  /// 반환값:
  /// - true: 앱을 실행할 수 있음
  /// - false: 이미 다른 인스턴스가 실행 중
  Future<bool> checkAndRun() async {
    try {
      final result = await FlutterAlonePlatform.instance.checkAndRun();
      return result;
    } catch (e) {
      debugPrint('앱 인스턴스 확인 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 앱 종료 시 리소스 정리
  Future<void> dispose() async {
    try {
      await FlutterAlonePlatform.instance.dispose();
    } catch (e) {
      debugPrint('리소스 정리 중 오류 발생: $e');
      rethrow;
    }
  }
}
