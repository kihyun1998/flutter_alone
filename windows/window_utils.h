#ifndef FLUTTER_PLUGIN_WINDOW_UTILS_H_
#define FLUTTER_PLUGIN_WINDOW_UTILS_H_

#include <windows.h>

#include <string>

namespace flutter_alone {

class WindowUtils {
public:
    static HWND FindMainWindow(DWORD processId);
    // Iterate all top-level windows whose title matches and whose owning process
    // resolves to the same executable path. Returns the first valid match, or NULL.
    static HWND FindWindowByTitleAndPath(const std::wstring& title,
                                         const std::wstring& exePath);
    static bool BringWindowToFront(HWND hwnd);
    static bool RestoreWindow(HWND hwnd);
    static bool FocusWindow(HWND hwnd);
    static bool IsValidWindow(HWND hwnd);

private:
    struct EnumWindowsCallbackArgs {
        DWORD processId;
        HWND resultHandle;
    };

    struct EnumByTitleAndPathArgs {
        const std::wstring* title;
        const std::wstring* exePath;
        HWND resultHandle;
    };

    static BOOL CALLBACK EnumWindowsCallback(HWND handle, LPARAM lParam);
    static BOOL CALLBACK EnumByTitleAndPathCallback(HWND handle, LPARAM lParam);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_WINDOW_UTILS_H_
