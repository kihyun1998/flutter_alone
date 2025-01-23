#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "process_utils.h"

#include <memory>

namespace flutter_alone {

class FlutterAlonePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterAlonePlugin();

  virtual ~FlutterAlonePlugin();

  // Disallow copy and assign.
  FlutterAlonePlugin(const FlutterAlonePlugin&) = delete;
  FlutterAlonePlugin& operator=(const FlutterAlonePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	
	// 중복 실행 체크 및 뮤텍스 생성
  bool CheckAndCreateMutex();
  
  // 리소스 정리
  void CleanupResources();

  // 실행 중인 프로세스 정보를 MessageBox로 표시
  void ShowAlreadyRunningMessage(const ProcessInfo& processInfo);

  // 뮤텍스 핸들 저장
  HANDLE mutex_handle_;
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
