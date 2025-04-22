#include "flutter_alone_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "window_utils.h"
#include "icon_utils.h"

#include <memory>
#include <sstream>
#include <string>
#include <codecvt>
#include <locale>

namespace flutter_alone {

// static
void FlutterAlonePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // create method channel
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_alone",
          &flutter::StandardMethodCodec::GetInstance());
  // create plugin
  auto plugin = std::make_unique<FlutterAlonePlugin>();
  // set method call handler
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  // add plugin
  registrar->AddPlugin(std::move(plugin));
}
// constructor
FlutterAlonePlugin::FlutterAlonePlugin() : mutex_handle_(NULL) {}

// destructor
FlutterAlonePlugin::~FlutterAlonePlugin() {
  CleanupResources();
}

// Display running process information in MessageBox
void FlutterAlonePlugin::ShowAlreadyRunningMessage(
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox) {
    
    MessageBoxInfo info;
    info.title = title;
    info.message = message;
    info.showMessageBox = showMessageBox;
    info.hIcon = IconUtils::GetAppIcon();

    ShowMessageBox(info);
}

void FlutterAlonePlugin::ShowMessageBox(const MessageBoxInfo& info) {
   if(!info.showMessageBox) {
       return;
   }
   
   HICON hIcon = ProcessUtils::GetExecutableIcon();
   
   static HHOOK g_hook = NULL;
   static HICON g_icon = hIcon;

   // Hook when creating message box window
   g_hook = SetWindowsHookEx(
       WH_CBT, 
       [](int nCode, WPARAM wParam, LPARAM lParam) -> LRESULT {
           if (nCode == HCBT_ACTIVATE && g_icon) {
               // Set window icon
               SendMessage((HWND)wParam, WM_SETICON, ICON_SMALL, (LPARAM)g_icon);
               SendMessage((HWND)wParam, WM_SETICON, ICON_BIG, (LPARAM)g_icon);
               UnhookWindowsHookEx(g_hook);
           }
           return CallNextHookEx(g_hook, nCode, wParam, lParam);
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

   if (hIcon) {
       DestroyIcon(hIcon);
   }
}


// std::wstring FlutterAlonePlugin::GetMutexName(const MutexConfig& config) {
//     // Use MutexUtils to generate mutex name
//     return MutexUtils::GenerateMutexName(
//         config.packageId,
//         config.appName,
//         config.suffix
//     );
// }

ProcessCheckResult FlutterAlonePlugin::CheckRunningInstance(const std::wstring& mutexName, const std::wstring& windowTitle) {
    ProcessCheckResult result;
    result.canRun = true;
    
    // Check for global mutex using the provided name
    HANDLE existingMutex = OpenMutexW(MUTEX_ALL_ACCESS, FALSE, mutexName.c_str());

    if (existingMutex != NULL) {
        OutputDebugStringW((L"[DEBUG] Existing mutex found: " + mutexName + L"\n").c_str());
        CloseHandle(existingMutex);
        result.canRun = false;
        
        // Find existing process - To check if it's the same user
        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            OutputDebugStringW(L"[DEBUG] Existing process window found\n");
            result.existingWindow = existingProcess->windowHandle;
        }
        
        // Try finding by window title if the existing window is not found
        if (result.existingWindow == NULL && !windowTitle.empty()) {
            OutputDebugStringW((L"[DEBUG] Attempting to find window by title: " + windowTitle + L"\n").c_str());
            
            HWND hwnd = FindWindowW(NULL, windowTitle.c_str());
            if (hwnd != NULL) {
                OutputDebugStringW(L"[DEBUG] Window found by title\n");
                result.existingWindow = hwnd;
            } else {
                OutputDebugStringW(L"[DEBUG] Window NOT found by title\n");
            }
        }
    }

    return result;
}


std::wstring StringToWideString(const std::string& str) {
    if (str.empty()) {
        return std::wstring();
    }
    
    // UTF-8 to UTF-16
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), NULL, 0);
    
    std::wstring result(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), &result[0], size_needed);
    
    return result;
}

std::string WideStringToString(const std::wstring& wstr) {
    if (wstr.empty()) {
        return std::string();
    }
    
    // UTF-16 to UTF-8
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), NULL, 0, NULL, NULL);
    
    std::string result(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), &result[0], size_needed, NULL, NULL);
    
    return result;
}

// Check for duplicate instance function with custom mutex name
bool FlutterAlonePlugin::CheckAndCreateMutex(const std::wstring& mutexName) {
    if (mutex_handle_ != NULL) {
        // Mutex already created
        return false;
    }

    current_mutex_name_ = mutexName;
    
    OutputDebugStringW((L"[DEBUG] Creating mutex with name: " + current_mutex_name_ + L"\n").c_str());

    // Set security attributes - Allow access all user
    SECURITY_ATTRIBUTES sa;
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = TRUE;
    
    SECURITY_DESCRIPTOR sd;
    InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
    SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
    sa.lpSecurityDescriptor = &sd;

    // Try to create global mutex with the given name
    mutex_handle_ = CreateMutexW(
        &sa,     // security attribute
        TRUE,    // request init
        current_mutex_name_.c_str()  // mutex name
    );

    if (mutex_handle_ == NULL) {
        return false;
    }

    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        CleanupResources();
        return false;
    }

    return true;
}

// Resource cleanup function
void FlutterAlonePlugin::CleanupResources() {
    if (mutex_handle_ != NULL) {
        ReleaseMutex(mutex_handle_);  // release mutex
        CloseHandle(mutex_handle_);   // close handle
        mutex_handle_ = NULL;
    }
}

// Method call handler function
void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name().compare("checkAndRun") == 0) {  
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());

        // Get Window title
        std::wstring windowTitle;
        auto windowTitleIt = arguments->find(flutter::EncodableValue("windowTitle"));
        if (windowTitleIt != arguments->end() && !windowTitleIt->second.IsNull()) {
            windowTitle = MessageUtils::Utf8ToWide(
                std::get<std::string>(windowTitleIt->second));
        }

        // Get mutex name directly from arguments
        std::wstring mutexName;
        auto mutexNameIt = arguments->find(flutter::EncodableValue("mutexName"));
        if (mutexNameIt != arguments->end() && !mutexNameIt->second.IsNull()) {
            mutexName = MessageUtils::Utf8ToWide(
                std::get<std::string>(mutexNameIt->second));
        }
        
        // get showmessage box
        bool showMessageBox = true;
        auto showMessageBoxIt = arguments->find(flutter::EncodableValue("showMessageBox"));
        if (showMessageBoxIt != arguments->end() && !showMessageBoxIt->second.IsNull()) {
            showMessageBox = std::get<bool>(showMessageBoxIt->second);
        }

        // get message tpye
        std::string typeStr = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
        MessageType type;
        if(typeStr == "ko") type = MessageType::ko;
        else if(typeStr == "en") type = MessageType::en;
        else type = MessageType::custom;
        
        std::wstring customTitle, customMessage;
        if (type == MessageType::custom) {
            auto customTitleIt = arguments->find(flutter::EncodableValue("customTitle"));
            if (customTitleIt != arguments->end() && !customTitleIt->second.IsNull()) {
                customTitle = MessageUtils::Utf8ToWide(
                    std::get<std::string>(customTitleIt->second));
            }
            
            auto customMessageIt = arguments->find(flutter::EncodableValue("customMessage"));
            if (customMessageIt != arguments->end() && !customMessageIt->second.IsNull()) {
                customMessage = MessageUtils::Utf8ToWide(
                    std::get<std::string>(customMessageIt->second));
            }
        }

        // Check for running instance
        auto checkResult = CheckRunningInstance(mutexName,windowTitle);

        
        if (!checkResult.canRun) {
            // If same window - Activate window
            if (checkResult.existingWindow != NULL) {
                OutputDebugStringW(L"[DEBUG] Existing window found - activating window\n");

                BOOL isVisible = IsWindowVisible(checkResult.existingWindow);
                BOOL isIconic = IsIconic(checkResult.existingWindow);
                OutputDebugStringW((L"[DEBUG] Window state - Visible: " + std::to_wstring(isVisible) + 
                                    L", Minimized: " + std::to_wstring(isIconic) + L"\n").c_str());

                OutputDebugStringW(L"[DEBUG] Attempting to restore window\n");
                BOOL restoreResult = WindowUtils::RestoreWindow(checkResult.existingWindow);
                OutputDebugStringW((L"[DEBUG] Restore result: " + std::to_wstring(restoreResult) + L"\n").c_str());

                OutputDebugStringW(L"[DEBUG] Attempting to bring window to front\n");
                BOOL bringToFrontResult = WindowUtils::BringWindowToFront(checkResult.existingWindow);
                OutputDebugStringW((L"[DEBUG] Bring to front result: " + std::to_wstring(bringToFrontResult) + L"\n").c_str());
                
                OutputDebugStringW(L"[DEBUG] Attempting to focus window\n");
                BOOL focusResult = WindowUtils::FocusWindow(checkResult.existingWindow);
                OutputDebugStringW((L"[DEBUG] Focus result: " + std::to_wstring(focusResult) + L"\n").c_str());

            } 
            // If running in different account - Show message
            else {
                OutputDebugStringW(L"[DEBUG] No existing window - showing message\n");
                std::wstring title = MessageUtils::GetTitle(type, customTitle);
                std::wstring message = MessageUtils::GetMessage(type, customMessage);
                ShowAlreadyRunningMessage(title, message, showMessageBox);
            }
            
            result->Success(flutter::EncodableValue(false));
            return;
        }

        // Create new mutex
        bool success = CheckAndCreateMutex(mutexName);
        result->Success(flutter::EncodableValue(success));
    } 
    else if (method_call.method_name().compare("dispose") == 0) {
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