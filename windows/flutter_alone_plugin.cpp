#include "flutter_alone_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter_alone {

// static
void FlutterAlonePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // 메소드 채널 생성
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_alone",
          &flutter::StandardMethodCodec::GetInstance());
  // 플러그인 인스턴스 생성
  auto plugin = std::make_unique<FlutterAlonePlugin>();
  // 메소드 콜 핸들러 설정
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  // 플러그인 등록
  registrar->AddPlugin(std::move(plugin));
}
// 생성자
FlutterAlonePlugin::FlutterAlonePlugin() {}

// 소멸자
FlutterAlonePlugin::~FlutterAlonePlugin() {
  CleanupResources();
}

// 중복 실행 체크 함수
bool FlutterAlonePlugin::CheckAndCreateMutex() {
  // 이미 뮤텍스가 생성되어 있다면 true 반환
  if (mutex_handle_ != NULL) {
    return true;
  }

  // 전역 뮤텍스 생성
  mutex_handle_ = CreateMutexW(
      NULL,    // 기본 보안 설정
      FALSE,   // 초기 소유권 요청하지 않음
      L"Global\\FlutterAloneApp_Mutex"  // 전역 네임스페이스 사용
  );

  if (mutex_handle_ == NULL) {
    // 뮤텍스 생성 실패
    return false;
  }

  // ERROR_ALREADY_EXISTS 체크
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    CleanupResources();
    return false;
  }

  return true;
}

// 리소스 정리 함수
void FlutterAlonePlugin::CleanupResources() {
  if (mutex_handle_ != NULL) {
    CloseHandle(mutex_handle_);
    mutex_handle_ = NULL;
  }
}

// 메소드 콜 처리 함수
void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("checkAndRun")==0) {
    bool canRun = CheckAndCreateMutex();
    result->Success(flutter::EncodableValue(canRun));
  } else if (method_call.method_name().compare("dispose")==0) {
    CleanupResources();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_alone
