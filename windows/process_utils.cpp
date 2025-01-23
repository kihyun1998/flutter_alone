#include "process_utils.h"
#include <windows.h>
#include <security.h>
#include <sddl.h>
#include <sspi.h>

namespace flutter_alone {

ProcessInfo ProcessUtils::GetCurrentProcessInfo() {
    ProcessInfo info;
    info.processId = GetCurrentProcessId();
    
    HANDLE hToken = NULL;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        return info;
    }

    // Get user from token
    if (!GetUserFromToken(hToken, info.domain, info.userName)) {
        CloseHandle(hToken);
        return info;
    }

    CloseHandle(hToken);
    return info;
}

bool ProcessUtils::GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName) {
    DWORD dwSize = 0;
    PTOKEN_USER pTokenUser = NULL;
    
    // Get token information
    GetTokenInformation(hToken, TokenUser, NULL, 0, &dwSize);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
        return false;
    }
    
    // Allocate memory
    pTokenUser = (PTOKEN_USER)LocalAlloc(LPTR, dwSize);
    if (!pTokenUser) {
        return false;
    }
    
    // Get token information
    if (!GetTokenInformation(hToken, TokenUser, pTokenUser, dwSize, &dwSize)) {
        LocalFree(pTokenUser);
        return false;
    }
    
    WCHAR szUser[256] = {0};
    WCHAR szDomain[256] = {0};
    DWORD dwUserSize = 256;
    DWORD dwDomainSize = 256;
    SID_NAME_USE snu;
    
    // SID를 사용자 이름과 도메인으로 변환
    if (!LookupAccountSidW(
        NULL,                   // Local computer
        pTokenUser->User.Sid,   // SID
        szUser,                 // User Name
        &dwUserSize,           
        szDomain,              // Domain name
        &dwDomainSize,
        &snu)) {
        LocalFree(pTokenUser);
        return false;
    }
    
    domain = szDomain;
    userName = szUser;
    
    LocalFree(pTokenUser);
    return true;
}

std::wstring ProcessUtils::GetLastErrorMessage() {
    DWORD error = GetLastError();
    LPWSTR messageBuffer = nullptr;
    
    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        error,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&messageBuffer,
        0,
        NULL
    );
    
    std::wstring message = messageBuffer ? messageBuffer : L"Unknown error";
    LocalFree(messageBuffer);
    
    return message;
}

}  // namespace flutter_alone