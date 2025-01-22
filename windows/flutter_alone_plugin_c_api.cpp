#include "include/flutter_alone/flutter_alone_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_alone_plugin.h"

void FlutterAlonePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_alone::FlutterAlonePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
