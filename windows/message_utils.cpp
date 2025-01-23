#include "message_utils.h"
#include <windows.h>

namespace flutter_alone {

std::wstring MessageUtils::GetTitle(MessageType type, const std::wstring& customTitle) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanTitle();
        case MessageType::en:
            return GetEnglishTitle();
        case MessageType::custom:
            return customTitle.empty() ? L"Error" : customTitle;
    }
    return L"Error";
}

std::wstring MessageUtils::GetMessage(MessageType type, const ProcessInfo& processInfo, const std::wstring& customMessage) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanMessage(processInfo);
        case MessageType::en:
            return GetEnglishMessage(processInfo);
        case MessageType::custom:
            return customMessage.empty() ? L"Another instance is running" : customMessage;
    }
    return L"Another instance is running";
}

std::wstring MessageUtils::GetKoreanMessage(const ProcessInfo& processInfo) {
    return L"이미 다른 사용자가 앱을 실행중입니다.\n실행 중인 사용자: " + processInfo.domain + L"\\" + processInfo.userName;
}

std::wstring MessageUtils::GetEnglishMessage(const ProcessInfo& processInfo) {
    return L"Application is already running by another user.\nRunning user: " + processInfo.domain + L"\\" + processInfo.userName;
}

std::wstring MessageUtils::Utf8ToWide(const std::string& str) {
    if (str.empty()) return std::wstring();
    
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), nullptr, 0);
    
    std::wstring result(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), &result[0], size_needed);
    
    return result;
}

std::string MessageUtils::WideToUtf8(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();
    
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), nullptr, 0, nullptr, nullptr);
    
    std::string result(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), &result[0], size_needed, nullptr, nullptr);
    
    return result;
}

}  // namespace flutter_alone