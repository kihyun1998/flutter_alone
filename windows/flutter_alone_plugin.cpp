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
void FlutterAlonePlugin::ShowAlreadyRunningMessage(const ProcessInfo& processInfo) {
    std::wstring message = L"이미 다른 사용자가 앱을 실행중입니다.\n";
    message += L"실행 중인 사용자: " + processInfo.domain + L"\\" + processInfo.userName;
    message += L"\n프로세스 ID: " + std::to_wstring(processInfo.processId);

    MessageBoxW(
        NULL,
        message.c_str(),
        L"실행 오류",
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL
    );
}

// Check for duplicate instance function
bool FlutterAlonePlugin::CheckAndCreateMutex() {
  if (g_hMutex != NULL) {
    // get current process info
    ProcessInfo currentProcess = ProcessUtils::GetCurrentProcessInfo();
    ShowAlreadyRunningMessage(currentProcess);
    return false;
  }

  // Set security attributes - Allow access all user
  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = FALSE;
  
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
    ProcessInfo currentProcess = ProcessUtils::GetCurrentProcessInfo();
    ShowAlreadyRunningMessage(currentProcess);
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