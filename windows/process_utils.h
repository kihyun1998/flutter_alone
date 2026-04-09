#ifndef FLUTTER_PLUGIN_PROCESS_UTILS_H_
#define FLUTTER_PLUGIN_PROCESS_UTILS_H_

#include <windows.h>
#include <string>
#include <optional>

namespace flutter_alone {

struct ProcessInfo {
    DWORD processId;
    HWND windowHandle;
    std::wstring processPath;
    FILETIME startTime;

    ProcessInfo() : processId(0), windowHandle(NULL) {
        startTime.dwLowDateTime = 0;
        startTime.dwHighDateTime = 0;
    }
};

class ProcessUtils {
public:
    static ProcessInfo GetProcessInfoById(DWORD processId);
    static std::optional<ProcessInfo> FindExistingProcess();
    static std::wstring GetProcessPath(DWORD processId);
    static FILETIME GetProcessStartTime(HANDLE hProcess);

private:
    static bool IsSameExecutable(const std::wstring& path1, const std::wstring& path2);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_
