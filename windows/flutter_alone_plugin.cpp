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
void FlutterAlonePlugin::ShowAlreadyRunningMessage(
  const ProcessInfo& processInfo,
  const std::wstring& title,
  const std::wstring& message,
  bool showMessageBox) {

    if(!showMessageBox) return;
    
    MessageBoxW(
        NULL,
        message.c_str(),
        title.c_str(),
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL
    );
}

// Check for duplicate instance function
bool FlutterAlonePlugin::CheckAndCreateMutex() {
  if (g_hMutex != NULL) {
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
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());

    // Get basic parameters
    std::string typeStr = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
    bool showMessageBox = std::get<bool>(arguments->at(flutter::EncodableValue("showMessageBox")));

    // Convert MessageType
    MessageType type;
    if(typeStr == "ko") type = MessageType::ko;
    else if(typeStr == "en") type = MessageType::en;
    else type = MessageType::custom;

    // Get custom parameters if needed
    std::wstring customTitle, messageTemplate;
    if (type == MessageType::custom) {
        customTitle = MessageUtils::Utf8ToWide(
            std::get<std::string>(arguments->at(flutter::EncodableValue("customTitle"))));
        messageTemplate = MessageUtils::Utf8ToWide(
            std::get<std::string>(arguments->at(flutter::EncodableValue("messageTemplate"))));
    }
    
    // Check duplicate instance
    bool canRun = CheckAndCreateMutex();
    if(!canRun && showMessageBox){
      ProcessInfo processInfo = ProcessUtils::GetCurrentProcessInfo();

      // Create message
      std::wstring title = MessageUtils::GetTitle(type, customTitle);
      std::wstring message = MessageUtils::GetMessage(type, processInfo, messageTemplate);

      ShowAlreadyRunningMessage(processInfo, title, message, showMessageBox);
    }

    result->Success(flutter::EncodableValue(canRun));
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