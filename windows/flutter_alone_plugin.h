#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "message_utils.h"

#include <memory>

namespace flutter_alone {

// Method channel constants
constexpr char kChannelName[] = "flutter_alone";
constexpr char kMethodCheckAndRun[] = "checkAndRun";
constexpr char kMethodDispose[] = "dispose";

// Argument key constants
constexpr char kArgWindowTitle[] = "windowTitle";
constexpr char kArgMutexName[] = "mutexName";
constexpr char kArgShowMessageBox[] = "showMessageBox";
constexpr char kArgType[] = "type";
constexpr char kArgCustomTitle[] = "customTitle";
constexpr char kArgCustomMessage[] = "customMessage";

// Mutex name length limit (application-level policy, not a kernel limit)
constexpr size_t kMaxMutexNameLength = 260;

// SDDL: Everyone gets SYNCHRONIZE only, Creator/Owner gets full mutex access
constexpr wchar_t kMutexSecurityDescriptor[] =
    L"D:(A;;0x00100000;;;WD)(A;;0x001F0001;;;CO)";

struct ProcessCheckResult {
  bool canRun;
  HWND existingWindow;

  ProcessCheckResult() : canRun(true), existingWindow(NULL) {}
};

class FlutterAlonePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterAlonePlugin();
  virtual ~FlutterAlonePlugin();

  FlutterAlonePlugin(const FlutterAlonePlugin&) = delete;
  FlutterAlonePlugin& operator=(const FlutterAlonePlugin&) = delete;

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool CheckAndCreateMutex(const std::wstring& mutexName);

  void ShowAlreadyRunningMessage(
      const std::wstring& title,
      const std::wstring& message,
      bool showMessageBox);

  ProcessCheckResult CheckRunningInstance(const std::wstring& mutexName, const std::wstring& windowTitle);

  void CleanupResources();

 private:
  struct MessageBoxInfo {
    std::wstring title;
    std::wstring message;
    bool showMessageBox;
    MessageBoxInfo() : showMessageBox(true) {}
  };

  void ShowMessageBox(const MessageBoxInfo& info);

  bool ParseCheckAndRunArgs(
      const flutter::EncodableMap* arguments,
      std::wstring& windowTitle,
      std::wstring& mutexName,
      bool& showMessageBox,
      MessageType& type,
      std::wstring& customTitle,
      std::wstring& customMessage);

  HANDLE mutex_handle_;
  std::wstring current_mutex_name_;
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
