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
    // 현재 프로세스의 사용자 정보 조회
    static ProcessInfo GetCurrentProcessInfo();
    
    // 에러 메시지 생성
    static std::wstring GetLastErrorMessage();

private:
    // Windows 보안 토큰에서 사용자 정보 추출
    static bool GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_