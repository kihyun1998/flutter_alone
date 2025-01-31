#include "flutter_alone_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "window_utils.h"

#include <memory>
#include <sstream>

namespace flutter_alone {

// Global mutex handle
static HANDLE g_hMutex = NULL;

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
FlutterAlonePlugin::FlutterAlonePlugin() {}

// destructor
FlutterAlonePlugin::~FlutterAlonePlugin() {
  CleanupResources();
}

// Display running process information in MessageBox
void FlutterAlonePlugin::ShowAlreadyRunningMessage(
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox) {
    if(!showMessageBox) {
        OutputDebugStringW(L"[DEBUG] showMessageBox is false, skipping message display\n");
        return;
    }
    
    MessageBoxW(
        NULL,
        message.c_str(),
        title.c_str(),
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL
    );
}
ProcessCheckResult FlutterAlonePlugin::CheckRunningInstance() {
    ProcessCheckResult result;
    result.canRun = true;
    
    // Check for global mutex
    HANDLE existingMutex = OpenMutexW(MUTEX_ALL_ACCESS, FALSE, L"Global\\FlutterAloneApp_UniqueId");

    if (existingMutex != NULL) {
        OutputDebugStringW(L"[DEBUG] Existing mutex found\n");
        CloseHandle(existingMutex);
        result.canRun = false;
        
        // 기존 프로세스 찾기 - 같은 사용자인지 확인용
        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            result.existingWindow = existingProcess->windowHandle;
            OutputDebugStringW(L"[DEBUG] Existing process window found\n");
        }
    }

    return result;
}

// Check for duplicate instance function
bool FlutterAlonePlugin::CheckAndCreateMutex() {
  if (g_hMutex != NULL) {
    return false;
  }

  // Set security attributes - Allow access all user
  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = TRUE;
  
  SECURITY_DESCRIPTOR sd;
  InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
  sa.lpSecurityDescriptor = &sd;

  // Try to create global mutex
  g_hMutex = CreateMutexW(
      &sa,     // security attribute
      TRUE,    // request init
      L"Global\\FlutterAloneApp_UniqueId"  // uniqe mutex name
  );

  if (g_hMutex == NULL) {
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
  if (g_hMutex != NULL) {
    ReleaseMutex(g_hMutex);  // release mutex
    CloseHandle(g_hMutex);   // close handle
    g_hMutex = NULL;
  }
}

// Method call handler function
void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name().compare("checkAndRun") == 0) {
        OutputDebugStringW(L"[DEBUG] HandleMethodCall: checkAndRun 시작\n");
        
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        
        // 메시지 설정 가져오기
        std::string typeStr = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
        bool showMessageBox = std::get<bool>(arguments->at(flutter::EncodableValue("showMessageBox")));
        
        MessageType type;
        if(typeStr == "ko") type = MessageType::ko;
        else if(typeStr == "en") type = MessageType::en;
        else type = MessageType::custom;
        
        std::wstring customTitle, customMessage;
        if (type == MessageType::custom) {
            customTitle = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("customTitle"))));
            customMessage = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("customMessage"))));
        }

        // 실행 중인 인스턴스 확인
        auto checkResult = CheckRunningInstance();

        
          if (!checkResult.canRun) {
            // 같은 창인 경우 - 창 활성화
            if (checkResult.existingWindow != NULL) {
                OutputDebugStringW(L"[DEBUG] Existing window found - activating window\n");
                WindowUtils::RestoreWindow(checkResult.existingWindow);
                WindowUtils::BringWindowToFront(checkResult.existingWindow);
                WindowUtils::FocusWindow(checkResult.existingWindow);
            } 
            // 다른 계정에서 실행 중인 경우 - 메시지 표시
            else {
                OutputDebugStringW(L"[DEBUG] No existing window - showing message\n");
                std::wstring title = MessageUtils::GetTitle(type, customTitle);
                std::wstring message = MessageUtils::GetMessage(type, customMessage);
                ShowAlreadyRunningMessage(title, message, showMessageBox);
            }
            
            result->Success(flutter::EncodableValue(false));
            return;
        }

        // 새로운 뮤텍스 생성
        bool success = CheckAndCreateMutex();
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