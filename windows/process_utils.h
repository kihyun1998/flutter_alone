#ifndef FLUTTER_PLUGIN_PROCESS_UTILS_H_
#define FLUTTER_PLUGIN_PROCESS_UTILS_H_

#include <windows.h>
#include <string>
#include <optional>

namespace flutter_alone {

struct ProcessInfo {
    DWORD processId;
    std::wstring processPath;
    FILETIME startTime;

    ProcessInfo() : processId(0) {
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

    // Public so it can be unit-tested; it is a pure, normalized path comparison.
    static bool IsSameExecutable(const std::wstring& path1, const std::wstring& path2);

    // True if `a` is a known start time earlier than `b`. A zero start time
    // (one that could not be read) is never earlier.
    static bool StartedBefore(const FILETIME& a, const FILETIME& b);

    // True if another process of this executable, started before this one,
    // is running. Processes whose path or start time cannot be read (another
    // user's), and ones that have exited but are still open, are not counted.
    static bool OlderInstanceRunning();

    // True if the process has not exited (exit code STILL_ACTIVE).
    static bool IsStillActive(DWORD processId);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_
