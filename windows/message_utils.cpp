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
        default:
            return L"Error";
    }
}

std::wstring MessageUtils::GetMessage(
    MessageType type,
    const std::wstring& customMessage
) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanMessage();
        case MessageType::en:
            return GetEnglishMessage();
        case MessageType::custom:
            return customMessage.empty() ? 
                L"Application is already running in another account" : customMessage;
        default:
            return L"Application is already running in another account";
    }
}

std::wstring MessageUtils::GetKoreanMessage() {
    return L"이미 다른 계정에서 앱을 실행중입니다.";
}

std::wstring MessageUtils::GetEnglishMessage() {
    return L"Application is already running in another account.";
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