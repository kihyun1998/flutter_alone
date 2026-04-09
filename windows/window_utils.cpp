#include "window_utils.h"

namespace flutter_alone {

constexpr int kMaxWindowTitleLength = 256;

HWND WindowUtils::FindMainWindow(DWORD processId) {
    EnumWindowsCallbackArgs args = {0};
    args.processId = processId;
    args.resultHandle = NULL;

    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&args));
    return args.resultHandle;
}

bool WindowUtils::BringWindowToFront(HWND hwnd) {
    return SetForegroundWindow(hwnd) != 0;
}

bool WindowUtils::RestoreWindow(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;

    if (!IsWindowVisible(hwnd)) {
        return ShowWindow(hwnd, SW_SHOW) != 0;
    }

    if (IsIconic(hwnd)) {
        return ShowWindow(hwnd, SW_RESTORE) != 0;
    }

    return true;
}

bool WindowUtils::FocusWindow(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;

    SetForegroundWindow(hwnd);
    SetFocus(hwnd);
    return true;
}

bool WindowUtils::IsValidWindow(HWND hwnd) {
    return hwnd != NULL && IsWindow(hwnd);
}

BOOL CALLBACK WindowUtils::EnumWindowsCallback(HWND handle, LPARAM lParam) {
    EnumWindowsCallbackArgs* args = reinterpret_cast<EnumWindowsCallbackArgs*>(lParam);

    DWORD processId = 0;
    GetWindowThreadProcessId(handle, &processId);

    if (processId == args->processId) {
        if (IsWindowVisible(handle)) {
            WCHAR title[kMaxWindowTitleLength];
            if (GetWindowTextW(handle, title, kMaxWindowTitleLength) > 0) {
                args->resultHandle = handle;
                return FALSE;
            }
        }
    }
    return TRUE;
}

}  // namespace flutter_alone
