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

// 전역 뮤텍스 핸들
static HANDLE g_hMutex = NULL;

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
  // 이미 뮤텍스가 생성되어 있다면 중복 실행으로 처리
  if (g_hMutex != NULL) {
    return false;
  }

  // 보안 속성 설정 - 모든 사용자가 접근 가능하도록
  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = FALSE;
  
  SECURITY_DESCRIPTOR sd;
  InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
  sa.lpSecurityDescriptor = &sd;

  // 전역 뮤텍스 생성 시도
  g_hMutex = CreateMutexW(
      &sa,     // 보안 속성
      TRUE,    // 초기 소유권 요청
      L"Global\\FlutterAloneApp_UniqueId"  // 고유한 뮤텍스 이름
  );

  if (g_hMutex == NULL) {
    // 뮤텍스 생성 실패
    return false;
  }

  // 이미 존재하는지 확인
  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    CleanupResources();
    return false;
  }

  return true;
}

// 리소스 정리 함수
void FlutterAlonePlugin::CleanupResources() {
  if (g_hMutex != NULL) {
    ReleaseMutex(g_hMutex);  // 뮤텍스 해제
    CloseHandle(g_hMutex);   // 핸들 닫기
    g_hMutex = NULL;
  }
}

// 메소드 콜 처리 함수
void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("checkAndRun") == 0) {
    bool canRun = CheckAndCreateMutex();
    result->Success(flutter::EncodableValue(canRun));
  } else if (method_call.method_name().compare("dispose") == 0) {
    CleanupResources();
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace flutter_alone

void FlutterAlonePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_alone::FlutterAlonePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}