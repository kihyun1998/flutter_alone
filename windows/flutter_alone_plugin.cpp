#include "flutter_alone_plugin.h"

#include <windows.h>
#include <sddl.h>

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

FlutterAlonePlugin::FlutterAlonePlugin() : mutex_handle_(NULL) {}

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

   // Use non-static locals + capture via static pointer for the CBT hook.
   // This is safe because ShowMessageBox blocks on MessageBoxW (single-threaded).
   static HHOOK s_hook = NULL;
   static HICON s_icon = NULL;
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

    HANDLE existingMutex = OpenMutexW(SYNCHRONIZE, FALSE, mutexName.c_str());

    if (existingMutex != NULL) {
#ifdef _DEBUG
        OutputDebugStringW((L"[DEBUG] Existing mutex found: " + mutexName + L"\n").c_str());
#endif
        CloseHandle(existingMutex);
        result.canRun = false;

        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            result.existingWindow = existingProcess->windowHandle;
        }

        // Fallback: iterate all top-level windows with matching title and pick the
        // one whose owning process matches our executable path. Using EnumWindows
        // (instead of FindWindowW, which only returns the first title match) keeps
        // this correct when a portable build and an installed build share the same
        // window title — we skip same-title windows belonging to a different exe.
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
    // Guard: mutex already held by this plugin instance
    if (mutex_handle_ != NULL) {
        return false;
    }

    if (mutexName.empty() || mutexName.length() > kMaxMutexNameLength) {
        return false;
    }

    // Validate no embedded backslash after the Global\ or Local\ prefix
    auto backslashPos = mutexName.find(L'\\', 7);
    if (backslashPos != std::wstring::npos) {
        return false;
    }

    current_mutex_name_ = mutexName;

#ifdef _DEBUG
    OutputDebugStringW((L"[DEBUG] Creating mutex with name: " + current_mutex_name_ + L"\n").c_str());
#endif

    SECURITY_ATTRIBUTES sa;
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = FALSE;

    PSECURITY_DESCRIPTOR pSD = nullptr;
    if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(
            kMutexSecurityDescriptor,
            SDDL_REVISION_1, &pSD, nullptr)) {
#ifdef _DEBUG
        OutputDebugStringW((L"[DEBUG] SDDL conversion failed, error: " +
            std::to_wstring(GetLastError()) + L"\n").c_str());
#endif
        pSD = nullptr;
    }
    sa.lpSecurityDescriptor = pSD;

    mutex_handle_ = CreateMutexW(
        &sa,
        TRUE,
        current_mutex_name_.c_str()
    );

    DWORD lastErr = GetLastError();

    if (pSD) {
        LocalFree(pSD);
    }

    if (mutex_handle_ == NULL) {
        return false;
    }

    if (lastErr == ERROR_ALREADY_EXISTS) {
        CleanupResources();
        return false;
    }

    return true;
}

void FlutterAlonePlugin::CleanupResources() {
    if (mutex_handle_ != NULL) {
        ReleaseMutex(mutex_handle_);
        CloseHandle(mutex_handle_);
        mutex_handle_ = NULL;
    }
}

bool FlutterAlonePlugin::ParseCheckAndRunArgs(
    const flutter::EncodableMap* arguments,
    std::wstring& windowTitle,
    std::wstring& mutexName,
    bool& showMessageBox,
    MessageType& type,
    std::wstring& customTitle,
    std::wstring& customMessage) {

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

    auto typeIt = arguments->find(flutter::EncodableValue(kArgType));
    if (typeIt != arguments->end() && !typeIt->second.IsNull()) {
        auto* typeStr = std::get_if<std::string>(&typeIt->second);
        if (typeStr) {
            if (*typeStr == "ko") type = MessageType::Korean;
            else if (*typeStr == "en") type = MessageType::English;
            else type = MessageType::Custom;
        }
    } else {
        return false;
    }

    if (type == MessageType::Custom) {
        auto titleIt = arguments->find(flutter::EncodableValue(kArgCustomTitle));
        if (titleIt != arguments->end() && !titleIt->second.IsNull()) {
            auto* str = std::get_if<std::string>(&titleIt->second);
            if (str) customTitle = MessageUtils::Utf8ToWide(*str);
        }

        auto msgIt = arguments->find(flutter::EncodableValue(kArgCustomMessage));
        if (msgIt != arguments->end() && !msgIt->second.IsNull()) {
            auto* str = std::get_if<std::string>(&msgIt->second);
            if (str) customMessage = MessageUtils::Utf8ToWide(*str);
        }
    }

    return true;
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

        std::wstring windowTitle, mutexName, customTitle, customMessage;
        bool showMessageBox = true;
        MessageType type = MessageType::English;

        if (!ParseCheckAndRunArgs(arguments, windowTitle, mutexName,
                                   showMessageBox, type, customTitle, customMessage)) {
            result->Error("BAD_ARGS", "Required argument 'type' is missing");
            return;
        }

        auto checkResult = CheckRunningInstance(mutexName, windowTitle);

        if (!checkResult.canRun) {
            if (checkResult.existingWindow != NULL) {
                WindowUtils::RestoreWindow(checkResult.existingWindow);
                WindowUtils::BringWindowToFront(checkResult.existingWindow);
                WindowUtils::FocusWindow(checkResult.existingWindow);
            } else {
                std::wstring title = MessageUtils::GetTitleText(type, customTitle);
                std::wstring message = MessageUtils::GetMessageText(type, customMessage);
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
