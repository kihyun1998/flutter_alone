#include "message_utils.h"
#include <windows.h>

namespace flutter_alone {

std::wstring MessageUtils::GetTitle(MessageType type, const std::wstring& customTitle) {
    switch (type) {
        case MessageType::Korean:
            return GetKoreanTitle();
        case MessageType::English:
            return GetEnglishTitle();
        case MessageType::Custom:
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
        case MessageType::Korean:
            return GetKoreanMessage();
        case MessageType::English:
            return GetEnglishMessage();
        case MessageType::Custom:
            return customMessage.empty() ?
                L"Application is already running in another account" : customMessage;
        default:
            return L"Application is already running in another account";
    }
}

std::wstring MessageUtils::GetKoreanMessage() {
    return L"\xC774\xBBF8 \xB2E4\xB978 \xACC4\xC815\xC5D0\xC11C \xC571\xC744 \xC2E4\xD589\xC911\xC785\xB2C8\xB2E4.";
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

}  // namespace flutter_alone
