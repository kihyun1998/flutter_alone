#ifndef FLUTTER_PLUGIN_PROCESS_UTILS_H_
#define FLUTTER_PLUGIN_PROCESS_UTILS_H_

#include <windows.h>
#include <string>

namespace flutter_alone {

struct ProcessInfo {
    std::wstring domain;
    std::wstring userName;
    DWORD processId;
};

class ProcessUtils {
public:
    // Get current process user information
    static ProcessInfo GetCurrentProcessInfo();
    
    // Generate error message
    static std::wstring GetLastErrorMessage();

private:
    // Extract user information from Windows security token
    static bool GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_