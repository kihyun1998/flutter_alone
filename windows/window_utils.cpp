#include "window_utils.h"

#include "process_utils.h"

namespace flutter_alone {

constexpr int kMaxWindowTitleLength = 256;

HWND WindowUtils::FindMainWindow(DWORD processId) {
    EnumWindowsCallbackArgs args = {0};
    args.processId = processId;
    args.resultHandle = NULL;

    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&args));
    return args.resultHandle;
}

HWND WindowUtils::FindWindowByTitleAndPath(const std::wstring& title,
                                            const std::wstring& exePath) {
    if (title.empty() || exePath.empty()) return NULL;

    EnumByTitleAndPathArgs args = {};
    args.title = &title;
    args.exePath = &exePath;
    args.resultHandle = NULL;

    EnumWindows(EnumByTitleAndPathCallback, reinterpret_cast<LPARAM>(&args));
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
        // Top-level only (exclude tooltip/popup helpers) with a non-empty title.
        // Do NOT filter by IsWindowVisible — a hidden main window (e.g. tray-minimized)
        // must still be findable so it can be restored.
        if (GetWindow(handle, GW_OWNER) == NULL) {
            WCHAR title[kMaxWindowTitleLength];
            if (GetWindowTextW(handle, title, kMaxWindowTitleLength) > 0) {
                args->resultHandle = handle;
                return FALSE;
            }
        }
    }
    return TRUE;
}

BOOL CALLBACK WindowUtils::EnumByTitleAndPathCallback(HWND handle, LPARAM lParam) {
    EnumByTitleAndPathArgs* args = reinterpret_cast<EnumByTitleAndPathArgs*>(lParam);

    if (GetWindow(handle, GW_OWNER) != NULL) return TRUE;

    WCHAR title[kMaxWindowTitleLength];
    int len = GetWindowTextW(handle, title, kMaxWindowTitleLength);
    if (len <= 0) return TRUE;

    if (args->title->compare(title) != 0) return TRUE;

    DWORD windowPid = 0;
    GetWindowThreadProcessId(handle, &windowPid);
    if (windowPid == 0) return TRUE;

    std::wstring windowPath = ProcessUtils::GetProcessPath(windowPid);
    if (windowPath.empty()) return TRUE;

    if (_wcsicmp(windowPath.c_str(), args->exePath->c_str()) == 0) {
        args->resultHandle = handle;
        return FALSE;
    }
    return TRUE;
}

}  // namespace flutter_alone
