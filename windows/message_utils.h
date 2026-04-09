#ifndef FLUTTER_PLUGIN_MESSAGE_UTILS_H_
#define FLUTTER_PLUGIN_MESSAGE_UTILS_H_

#include <string>

namespace flutter_alone {

enum class MessageType {
    Korean,
    English,
    Custom
};

class MessageUtils {
public:
    static std::wstring GetTitle(MessageType type, const std::wstring& customTitle = L"");
    static std::wstring GetMessage(MessageType type, const std::wstring& customMessage = L"");
    static std::wstring Utf8ToWide(const std::string& str);

private:
    static std::wstring GetKoreanTitle() { return L"\xC2E4\xD589 \xC624\xB958"; }
    static std::wstring GetEnglishTitle() { return L"Execution Error"; }
    static std::wstring GetKoreanMessage();
    static std::wstring GetEnglishMessage();
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MESSAGE_UTILS_H_
