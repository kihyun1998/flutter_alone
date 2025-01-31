#include "process_utils.h"
#include "window_utils.h"
#include <windows.h>
#include <security.h>
#include <sddl.h>
#include <sspi.h>
#include <tlhelp32.h>
#include <vector>

namespace flutter_alone {

ProcessInfo ProcessUtils::GetProcessInfoById(DWORD processId) {
    ProcessInfo info;
    info.processId = processId;
    
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, TRUE, processId);
    if (hProcess) {
        HANDLE hToken = NULL;
        if (OpenProcessToken(hProcess, TOKEN_QUERY, &hToken)) {
            GetUserFromToken(hToken, info.domain, info.userName);
            CloseHandle(hToken);
        }
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
    
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        return std::nullopt;
    }

    PROCESSENTRY32W processEntry;
    processEntry.dwSize = sizeof(processEntry);

    if (Process32FirstW(snapshot, &processEntry)) {
        do {
            if (processEntry.th32ProcessID != currentPid) {
                std::wstring processPath = GetProcessPath(processEntry.th32ProcessID);
                if (IsSameExecutable(currentPath, processPath)) {
                    CloseHandle(snapshot);
                    return GetProcessInfoById(processEntry.th32ProcessID);
                }
            }
        } while (Process32NextW(snapshot, &processEntry));
    }

    CloseHandle(snapshot);
    return std::nullopt;
}

bool ProcessUtils::IsSameExecutable(const std::wstring& path1, const std::wstring& path2) {
    if (path1.empty() || path2.empty()) {
        return false;
    }
    
    // Normalize paths and compare
    WCHAR fullPath1[MAX_PATH];
    WCHAR fullPath2[MAX_PATH];
    
    if (GetFullPathNameW(path1.c_str(), MAX_PATH, fullPath1, NULL) == 0 ||
        GetFullPathNameW(path2.c_str(), MAX_PATH, fullPath2, NULL) == 0) {
        return false;
    }
    
    return _wcsicmp(fullPath1, fullPath2) == 0;
}

ProcessInfo ProcessUtils::GetCurrentProcessInfo() {
    return GetProcessInfoById(GetCurrentProcessId());
}

bool ProcessUtils::IsSameUser(const ProcessInfo& p1, const ProcessInfo& p2) {
    return (p1.domain == p2.domain && p1.userName == p2.userName);
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


bool ProcessUtils::GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName) {
    // Set Security attributes
    SECURITY_ATTRIBUTES sa;
    sa.nLength = sizeof(SECURITY_ATTRIBUTES);
    sa.bInheritHandle = TRUE;

    SECURITY_DESCRIPTOR sd;
    InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
    SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
    sa.lpSecurityDescriptor = &sd;
    
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