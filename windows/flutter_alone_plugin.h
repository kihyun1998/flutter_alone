#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_alone {

class FlutterAlonePlugin : public flutter::Plugin {
 public:
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
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
