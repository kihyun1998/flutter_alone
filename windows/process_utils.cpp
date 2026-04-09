#include "process_utils.h"
#include "window_utils.h"
#include <windows.h>
#include <tlhelp32.h>
#include <memory>

namespace flutter_alone {

ProcessInfo ProcessUtils::GetProcessInfoById(DWORD processId) {
    ProcessInfo info;
    info.processId = processId;

    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (hProcess) {
        info.startTime = GetProcessStartTime(hProcess);
        info.processPath = GetProcessPath(processId);
        CloseHandle(hProcess);
    }

    info.windowHandle = WindowUtils::FindMainWindow(processId);
    return info;
}

std::optional<ProcessInfo> ProcessUtils::FindExistingProcess() {
    DWORD currentPid = GetCurrentProcessId();
    std::wstring currentPath = GetProcessPath(currentPid);

    // If we can't determine our own path, detection is impossible
    if (currentPath.empty()) {
        return std::nullopt;
    }

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        return std::nullopt;
    }

    auto snapshotGuard = std::unique_ptr<void, decltype(&CloseHandle)>(snapshot, CloseHandle);

    PROCESSENTRY32W processEntry;
    processEntry.dwSize = sizeof(processEntry);

    if (Process32FirstW(snapshot, &processEntry)) {
        do {
            if (processEntry.th32ProcessID != currentPid) {
                std::wstring processPath = GetProcessPath(processEntry.th32ProcessID);
                if (IsSameExecutable(currentPath, processPath)) {
                    ProcessInfo info = GetProcessInfoById(processEntry.th32ProcessID);
                    return info;
                }
            }
        } while (Process32NextW(snapshot, &processEntry));
    }

    return std::nullopt;
}

bool ProcessUtils::IsSameExecutable(const std::wstring& path1, const std::wstring& path2) {
    if (path1.empty() || path2.empty()) {
        return false;
    }

    WCHAR fullPath1[MAX_PATH];
    WCHAR fullPath2[MAX_PATH];

    if (GetFullPathNameW(path1.c_str(), MAX_PATH, fullPath1, NULL) == 0 ||
        GetFullPathNameW(path2.c_str(), MAX_PATH, fullPath2, NULL) == 0) {
        return false;
    }

    return _wcsicmp(fullPath1, fullPath2) == 0;
}

std::wstring ProcessUtils::GetProcessPath(DWORD processId) {
    std::wstring path;
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (hProcess) {
        WCHAR buffer[MAX_PATH];
        DWORD size = MAX_PATH;
        if (QueryFullProcessImageNameW(hProcess, 0, buffer, &size)) {
            path = std::wstring(buffer);
        }
        CloseHandle(hProcess);
    }
    return path;
}

FILETIME ProcessUtils::GetProcessStartTime(HANDLE hProcess) {
    FILETIME creation, exit, kernel, user;
    FILETIME empty = {0, 0};

    if (!GetProcessTimes(hProcess, &creation, &exit, &kernel, &user)) {
        return empty;
    }
    return creation;
}

}  // namespace flutter_alone
