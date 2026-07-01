#include "flutter_alone_plugin.h"

#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "window_utils.h"
#include "icon_utils.h"
#include "process_utils.h"

#include <memory>
#include <string>

namespace flutter_alone {

void FlutterAlonePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), kChannelName,
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterAlonePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterAlonePlugin::FlutterAlonePlugin() {}

FlutterAlonePlugin::~FlutterAlonePlugin() {
  CleanupResources();
}

void FlutterAlonePlugin::ShowAlreadyRunningMessage(
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox) {
    MessageBoxInfo info;
    info.title = title;
    info.message = message;
    info.showMessageBox = showMessageBox;
    ShowMessageBox(info);
}

void FlutterAlonePlugin::ShowMessageBox(const MessageBoxInfo& info) {
   if (!info.showMessageBox) {
       return;
   }

   HICON hIcon = IconUtils::GetAppIcon();

   // The CBT hook proc is captureless, so it reaches the icon through
   // thread-local state. thread_local (rather than a plain static) keeps
   // concurrent ShowMessageBox calls on different threads from racing on shared
   // globals; each call blocks on its own MessageBoxW on its own thread.
   thread_local HHOOK s_hook = NULL;
   thread_local HICON s_icon = NULL;
   s_icon = hIcon;

   s_hook = SetWindowsHookEx(
       WH_CBT,
       [](int nCode, WPARAM wParam, LPARAM lParam) -> LRESULT {
           HHOOK hookCopy = s_hook;
           if (nCode == HCBT_ACTIVATE && s_icon) {
               SendMessage((HWND)wParam, WM_SETICON, ICON_SMALL, (LPARAM)s_icon);
               SendMessage((HWND)wParam, WM_SETICON, ICON_BIG, (LPARAM)s_icon);
               UnhookWindowsHookEx(s_hook);
               s_hook = NULL;
           }
           return CallNextHookEx(hookCopy, nCode, wParam, lParam);
       },
       NULL,
       GetCurrentThreadId()
   );

   MessageBoxW(
       NULL,
       info.message.c_str(),
       info.title.c_str(),
       MB_OK | MB_ICONINFORMATION
   );

   // Safety net: unhook if the hook was never triggered
   if (s_hook != NULL) {
       UnhookWindowsHookEx(s_hook);
       s_hook = NULL;
   }

   if (hIcon) {
       DestroyIcon(hIcon);
   }
}

ProcessCheckResult FlutterAlonePlugin::CheckRunningInstance(const std::wstring& mutexName, const std::wstring& windowTitle) {
    ProcessCheckResult result;
    result.canRun = true;

    if (MutexGuard::Exists(mutexName)) {
#ifdef _DEBUG
        OutputDebugStringW((L"[DEBUG] Existing mutex found: " + mutexName + L"\n").c_str());
#endif
        result.canRun = false;

        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            // Look up the window here (rather than inside ProcessUtils) so
            // process_utils has no dependency on window_utils.
            result.existingWindow =
                WindowUtils::FindMainWindow(existingProcess->processId);
        }

        // Fallback: iterate all top-level windows with matching title and pick the
        // one whose owning process matches our executable path. Using EnumWindows
        // (instead of FindWindowW, which only returns the first title match) keeps
        // this correct when a portable build and an installed build share the same
        // window title: we skip same-title windows belonging to a different exe.
        if (result.existingWindow == NULL && !windowTitle.empty()) {
            std::wstring currentPath = ProcessUtils::GetProcessPath(GetCurrentProcessId());
            if (!currentPath.empty()) {
                result.existingWindow = WindowUtils::FindWindowByTitleAndPath(
                    windowTitle, currentPath);
            }
        }
    }

    return result;
}

bool FlutterAlonePlugin::CheckAndCreateMutex(const std::wstring& mutexName) {
    return mutex_.Acquire(mutexName) == MutexAcquireOutcome::kAcquired;
}

void FlutterAlonePlugin::CleanupResources() {
    mutex_.Release();
}

void FlutterAlonePlugin::ParseCheckAndRunArgs(
    const flutter::EncodableMap* arguments,
    std::wstring& windowTitle,
    std::wstring& mutexName,
    bool& showMessageBox,
    std::wstring& title,
    std::wstring& message) {

    auto windowTitleIt = arguments->find(flutter::EncodableValue(kArgWindowTitle));
    if (windowTitleIt != arguments->end() && !windowTitleIt->second.IsNull()) {
        auto* str = std::get_if<std::string>(&windowTitleIt->second);
        if (str) windowTitle = MessageUtils::Utf8ToWide(*str);
    }

    auto mutexNameIt = arguments->find(flutter::EncodableValue(kArgMutexName));
    if (mutexNameIt != arguments->end() && !mutexNameIt->second.IsNull()) {
        auto* str = std::get_if<std::string>(&mutexNameIt->second);
        if (str) mutexName = MessageUtils::Utf8ToWide(*str);
    }

    auto showMsgIt = arguments->find(flutter::EncodableValue(kArgShowMessageBox));
    if (showMsgIt != arguments->end() && !showMsgIt->second.IsNull()) {
        auto* val = std::get_if<bool>(&showMsgIt->second);
        if (val) showMessageBox = *val;
    }

    // Title and message are resolved on the Dart side (single source of truth).
    auto titleIt = arguments->find(flutter::EncodableValue(kArgTitle));
    if (titleIt != arguments->end() && !titleIt->second.IsNull()) {
        auto* str = std::get_if<std::string>(&titleIt->second);
        if (str) title = MessageUtils::Utf8ToWide(*str);
    }

    auto msgIt = arguments->find(flutter::EncodableValue(kArgMessage));
    if (msgIt != arguments->end() && !msgIt->second.IsNull()) {
        auto* str = std::get_if<std::string>(&msgIt->second);
        if (str) message = MessageUtils::Utf8ToWide(*str);
    }
}

void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

    if (method_call.method_name().compare(kMethodCheckAndRun) == 0) {
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        if (!arguments) {
            result->Error("BAD_ARGS", "Missing or invalid arguments");
            return;
        }

        std::wstring windowTitle, mutexName, title, message;
        bool showMessageBox = true;

        ParseCheckAndRunArgs(arguments, windowTitle, mutexName,
                             showMessageBox, title, message);

        auto checkResult = CheckRunningInstance(mutexName, windowTitle);

        if (!checkResult.canRun) {
            if (checkResult.existingWindow != NULL) {
                WindowUtils::RestoreWindow(checkResult.existingWindow);
                WindowUtils::BringWindowToFront(checkResult.existingWindow);
                WindowUtils::FocusWindow(checkResult.existingWindow);
            } else {
                ShowAlreadyRunningMessage(title, message, showMessageBox);
            }

            result->Success(flutter::EncodableValue(false));
            return;
        }

        bool success = CheckAndCreateMutex(mutexName);
        result->Success(flutter::EncodableValue(success));
    }
    else if (method_call.method_name().compare(kMethodDispose) == 0) {
        CleanupResources();
        result->Success();
    }
    else {
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
