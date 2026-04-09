#ifndef FLUTTER_PLUGIN_WINDOW_UTILS_H_
#define FLUTTER_PLUGIN_WINDOW_UTILS_H_

#include <windows.h>

namespace flutter_alone {

class WindowUtils {
public:
    static HWND FindMainWindow(DWORD processId);
    static bool BringWindowToFront(HWND hwnd);
    static bool RestoreWindow(HWND hwnd);
    static bool FocusWindow(HWND hwnd);
    static bool IsValidWindow(HWND hwnd);

private:
    struct EnumWindowsCallbackArgs {
        DWORD processId;
        HWND resultHandle;
    };

    static BOOL CALLBACK EnumWindowsCallback(HWND handle, LPARAM lParam);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_WINDOW_UTILS_H_
