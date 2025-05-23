﻿#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "process_utils.h"
#include "message_utils.h"



#include <memory>

namespace flutter_alone {

struct ProcessCheckResult {
  bool canRun;        
  bool isSameUser;    
  HWND existingWindow;

  ProcessCheckResult() : canRun(true), isSameUser(false), existingWindow(NULL) {}
};

class FlutterAlonePlugin : public flutter::Plugin {
 public:
  struct MessageBoxInfo {
    std::wstring title;
    std::wstring message;
    bool showMessageBox;
    HICON hIcon;  // Added: App icon handle

    MessageBoxInfo() : showMessageBox(true), hIcon(NULL) {}
  };

  struct MutexConfig {
    std::wstring packageId;
    std::wstring appName;
    std::wstring suffix;

    MutexConfig() {}
    
    MutexConfig(const std::wstring& pkgId, const std::wstring& app, const std::wstring& sfx = L"")
        : packageId(pkgId), appName(app), suffix(sfx) {}
  };

  void ShowMessageBox(const MessageBoxInfo& info);

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
	
  // Check and create mutex with specified name
  bool CheckAndCreateMutex(const std::wstring& mutexName);
  

  // Get mutex name for the application
  std::wstring GetMutexName(const MutexConfig& config);

  // show process info
  void ShowAlreadyRunningMessage(
  const std::wstring& title,
  const std::wstring& message,
  bool showMessageBox);

  // Check for duplicate instance with specified mutex name
  ProcessCheckResult CheckRunningInstance(const std::wstring& mutexName, const std::wstring& windowTitle);


  std::wstring StringToWideString(const std::string& str);
  std::string WideStringToString(const std::wstring& wstr);
  
  // cleanup resources
  void CleanupResources();


 private:
  // Store mutex handle
  HANDLE mutex_handle_;

  // Current mutex name
  std::wstring current_mutex_name_;
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_