﻿#include "flutter_alone_plugin.h"

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
    const ProcessInfo& processInfo,
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox) {
    
    OutputDebugStringW(L"[DEBUG] ShowAlreadyRunningMessage 호출\n");
    OutputDebugStringW((L"[DEBUG] 제목: " + title + L"\n").c_str());
    OutputDebugStringW((L"[DEBUG] 메시지: " + message + L"\n").c_str());
    
    if(!showMessageBox) {
        OutputDebugStringW(L"[DEBUG] showMessageBox가 false라서 메시지 표시 안함\n");
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
    
    OutputDebugStringW(L"[DEBUG] CheckRunningInstance started:\n");
    
    // 전역 뮤텍스 존재 확인
    HANDLE existingMutex = OpenMutexW(MUTEX_ALL_ACCESS, FALSE, L"Global\\FlutterAloneApp_UniqueId");

    if (existingMutex != NULL) {
        OutputDebugStringW(L"[DEBUG] Existing mutex found\n");
        CloseHandle(existingMutex);
        
        // 뮤텍스가 있다는 것 자체가 다른 프로세스가 실행중이라는 의미
        result.canRun = false;  // 여기서 바로 false로 설정
        
        // 현재 프로세스 정보 가져오기
        ProcessInfo currentProcess = ProcessUtils::GetCurrentProcessInfo();
        OutputDebugStringW((L"[DEBUG] Current process info - Domain: " + 
            currentProcess.domain + L", User: " + currentProcess.userName + L"\n").c_str());
        
        // 기존 프로세스 찾기 - 같은 사용자인지 확인용
        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            OutputDebugStringW(L"[DEBUG] Existing process found\n");
            OutputDebugStringW((L"[DEBUG] Existing process info - Domain: " + 
                existingProcess->domain + L", User: " + existingProcess->userName + L"\n").c_str());
            
            result.isSameUser = ProcessUtils::IsSameUser(currentProcess, existingProcess.value());
            
            if (result.isSameUser) {
                result.existingWindow = existingProcess->windowHandle;
            }
        } else {
            OutputDebugStringW(L"[DEBUG] No existing process found - but mutex exists\n");
            // 프로세스를 못찾더라도 뮤텍스가 있으므로 다른 사용자가 실행중인 것으로 간주
            result.isSameUser = false;
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
    auto errorMessage = ProcessUtils::GetLastErrorMessage();
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
        
        std::wstring customTitle, messageTemplate;
        if (type == MessageType::custom) {
            customTitle = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("customTitle"))));
            messageTemplate = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("messageTemplate"))));
        }

        // 실행 중인 인스턴스 확인
        auto checkResult = CheckRunningInstance();
        OutputDebugStringW(L"[DEBUG] CheckRunningInstance 결과:\n");
        OutputDebugStringW((L"canRun: " + std::to_wstring(checkResult.canRun) + L"\n").c_str());
        OutputDebugStringW((L"isSameUser: " + std::to_wstring(checkResult.isSameUser) + L"\n").c_str());
        OutputDebugStringW((L"existingWindow: " + std::to_wstring((UINT_PTR)checkResult.existingWindow) + L"\n").c_str());

        
        if (!checkResult.canRun) {
            if (checkResult.isSameUser) {
                OutputDebugStringW(L"[DEBUG] Same user's process detected\n");
                // 같은 사용자 - 기존 창 활성화
                WindowUtils::RestoreWindow(checkResult.existingWindow);
                WindowUtils::BringWindowToFront(checkResult.existingWindow);
                WindowUtils::FocusWindow(checkResult.existingWindow);
                result->Success(flutter::EncodableValue(false));
            } else {
                OutputDebugStringW(L"[DEBUG] Another user's process detected\n");



                // 다른 사용자 - 메시지 표시
                auto existingProcess = ProcessUtils::FindExistingProcess();
                if (existingProcess.has_value()) {
                    std::wstring title = MessageUtils::GetTitle(type, customTitle);
                    std::wstring message = MessageUtils::GetMessage(type, existingProcess.value(), messageTemplate);
                    
                    // 메시지 박스를 표시하고 결과를 반환
                    ShowAlreadyRunningMessage(existingProcess.value(), title, message, showMessageBox);
                }else{
                  // 기본 ProcessInfo 생성
                  ProcessInfo defaultInfo;
                  defaultInfo.domain = L"Unknown";  // 또는 현재 도메인 사용
                  defaultInfo.userName = L"another user";

                  std::wstring title = MessageUtils::GetTitle(type, customTitle);
                  std::wstring message = MessageUtils::GetMessage(type, defaultInfo, messageTemplate);

                  // 메시지 박스를 표시하고 결과를 반환
                  ShowAlreadyRunningMessage(defaultInfo, title, message, showMessageBox);

                }
                result->Success(flutter::EncodableValue(false));
            }
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