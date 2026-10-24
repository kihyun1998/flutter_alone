# plugin-registration

## What it is
How the Flutter tool finds and wires the native side of each platform: the `flutter.plugin.platforms` block in `pubspec.yaml` names a class per platform, and each platform's registrar opens the `flutter_alone` method channel and routes calls to the plugin instance.

## Governing decisions
**None.** The shape follows the Flutter plugin template (see Reference behaviour); no record decides it.

## Design model
From the source:
- `pubspec.yaml` maps `windows → FlutterAlonePluginCApi`, `macos → FlutterAlonePlugin`, `linux → FlutterAlonePlugin`. The Flutter tool derives the C symbol names from these (`FlutterAlonePluginCApiRegisterWithRegistrar`, `flutter_alone_plugin_register_with_registrar`) — renaming a class without the symbol breaks consumers' generated registrants.
- Windows: `FlutterAlonePluginCApiRegisterWithRegistrar` → `FlutterAlonePlugin::RegisterWithRegistrar`; the plugin is owned by the registrar and releases the mutex in its destructor.
- Linux: `flutter_alone_plugin_register_with_registrar` creates a GObject; `flutter_alone_plugin_dispose` releases the lock and frees the `LockHandle`.
- macOS: `FlutterAlonePlugin.register(with:)`; there is no deinit release — the kernel drops the flock at process exit and the file is left behind.
- The `PLUGIN_NAME` `flutter_alone_plugin` in both CMake files must not change (template comment).

## Code
- `pubspec.yaml — flutter.plugin.platforms`
- `windows/flutter_alone_plugin_c_api.cpp — FlutterAlonePluginCApiRegisterWithRegistrar`; `windows/include/flutter_alone/flutter_alone_plugin_c_api.h`; `windows/flutter_alone_plugin.cpp — FlutterAlonePlugin::RegisterWithRegistrar`, `~FlutterAlonePlugin`
- `linux/include/flutter_alone/flutter_alone_plugin.h`; `linux/flutter_alone_plugin.cc — flutter_alone_plugin_register_with_registrar`, `flutter_alone_plugin_init`, `flutter_alone_plugin_dispose`, `method_call_cb`
- `macos/Classes/FlutterAlonePlugin.swift — register(with:)`
- `windows/CMakeLists.txt`, `linux/CMakeLists.txt` — `PLUGIN_SOURCES`, link libraries

## Reference behaviour
- Flutter plugin docs (docs.flutter.dev, summarized — binding): pubspec `pluginClass`, registrar naming, CMake template. Not compared line by line.

## Cross-cutting invariants
- [method-channel-contract](../invariant/method-channel-contract.md)

## Blast radius
- [dart-api](dart-api.md) — the channel name must match.
- [shipping](shipping.md) — a new native source must be listed in `PLUGIN_SOURCES` or consumers fail to link; a new macOS file must match the podspec's `source_files`.
- [instance-lock-windows](instance-lock-windows.md), [instance-lock-linux](instance-lock-linux.md) — the plugin lifetime is when the lock is released if `dispose` was never called.

## Known holes / open
**None.** (An unreferenced `FlutterAlonePluginRegisterWithRegistrar` export in `flutter_alone_plugin.cpp` was removed on 2026-10-24.)
