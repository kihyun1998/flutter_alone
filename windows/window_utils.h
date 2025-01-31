#ifndef FLUTTER_PLUGIN_WINDOW_UTILS_H_
#define FLUTTER_PLUGIN_WINDOW_UTILS_H_

#include <windows.h>
#include <string>

namespace flutter_alone {

class WindowUtils {
public:
    // Find main window
    static HWND FindMainWindow(DWORD processId);
    
    // Bring window to front
    static bool BringWindowToFront(HWND hwnd);
    
    // Restore window
    static bool RestoreWindow(HWND hwnd);
    
    // Focus Window
    static bool FocusWindow(HWND hwnd);
    
    // Check is valid window
    static bool IsValidWindow(HWND hwnd);

private:
    // EnumWindows struct
    struct EnumWindowsCallbackArgs {
        DWORD processId;
        HWND resultHandle;
    };

    // EnumWindows Callback
    static BOOL CALLBACK EnumWindowsCallback(HWND handle, LPARAM lParam);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_WINDOW_UTILS_H_