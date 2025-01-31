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
    /**
     * Get process info for given process ID
     */
    static ProcessInfo GetProcessInfoById(DWORD processId);
    
    /**
     * Get current process information
     */
    static ProcessInfo GetCurrentProcessInfo();
    
    /**
     * Find existing instance of our application
     */
    static std::optional<ProcessInfo> FindExistingProcess();
    
    /**
     * Get process executable path
     */
    static std::wstring GetProcessPath(DWORD processId);
    
    /**
     * Get process start time
     */
    static FILETIME GetProcessStartTime(HANDLE hProcess);
    
    /**
     * Get last error message
     */
    static std::wstring GetLastErrorMessage();

private:
    /**
     * Check if two paths point to same executable
     */
    static bool IsSameExecutable(const std::wstring& path1, const std::wstring& path2);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_