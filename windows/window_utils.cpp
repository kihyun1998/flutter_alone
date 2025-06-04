#include "window_utils.h"


namespace flutter_alone {

HWND WindowUtils::FindMainWindow(DWORD processId) {
    EnumWindowsCallbackArgs args = {0};
    args.processId = processId;
    args.resultHandle = NULL;
    
    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&args));
    return args.resultHandle;
}

bool WindowUtils::BringWindowToFront(HWND hwnd) {
    // if (!IsValidWindow(hwnd)) return false;
    
    // // get top
    // DWORD foregroundThreadId = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
    // DWORD currentThreadId = GetCurrentThreadId();
    
    // if (foregroundThreadId != currentThreadId) {
    //     AttachThreadInput(currentThreadId, foregroundThreadId, TRUE);
    //     BringWindowToTop(hwnd);
    //     AttachThreadInput(currentThreadId, foregroundThreadId, FALSE);
    // } else {
    //     BringWindowToTop(hwnd);
    // }
    
    // return true;
    return SetForegroundWindow(hwnd) != 0;
}

bool WindowUtils::RestoreWindow(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;
    
    // If the window is not visible, display it
    if (!IsWindowVisible(hwnd)) {
        OutputDebugStringW(L"[DEBUG] Window is hidden, showing it\n");
        BOOL result = ShowWindow(hwnd, SW_SHOW);
        OutputDebugStringW((L"[DEBUG] Restore result: " + std::to_wstring(result) + L"\n").c_str());
        
        // 복원 후 상태 확인 추가
        BOOL visibleAfter = IsWindowVisible(hwnd);
        BOOL iconicAfter = IsIconic(hwnd);
        OutputDebugStringW((L"[DEBUG] After restore - Visible: " + std::to_wstring(visibleAfter) + 
                           L", Minimized: " + std::to_wstring(iconicAfter) + L"\n").c_str());
        
        return result;
    }
    
    // If the window is minimized, restore it to original size
    if (IsIconic(hwnd)) {
        OutputDebugStringW(L"[DEBUG] Window is minimized, restoring it\n");
        BOOL result = ShowWindow(hwnd, SW_RESTORE);
        OutputDebugStringW((L"[DEBUG] Restore result: " + std::to_wstring(result) + L"\n").c_str());
        
        // 복원 후 상태 확인 추가
        BOOL visibleAfter = IsWindowVisible(hwnd);
        BOOL iconicAfter = IsIconic(hwnd);
        OutputDebugStringW((L"[DEBUG] After restore - Visible: " + std::to_wstring(visibleAfter) + 
                           L", Minimized: " + std::to_wstring(iconicAfter) + L"\n").c_str());
        
        return result;
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
            WCHAR title[256];
            if (GetWindowTextW(handle, title, 256) > 0) {
                args->resultHandle = handle;
                return FALSE;
            }
        }
    }
    return TRUE;
}

}  // namespace flutter_alone