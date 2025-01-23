#ifndef FLUTTER_PLUGIN_MESSAGE_UTILS_H_
#define FLUTTER_PLUGIN_MESSAGE_UTILS_H_

#include <string>
#include "process_utils.h"

namespace flutter_alone {

enum class MessageType {
    ko,
    en,
    custom
};

class MessageUtils {
public:
    static std::wstring GetTitle(MessageType type, const std::wstring& customTitle);
    static std::wstring GetMessage(MessageType type, const ProcessInfo& processInfo, const std::wstring& customMessage);
    
    // 문자열 인코딩 변환 유틸리티
    static std::wstring Utf8ToWide(const std::string& str);
    static std::string WideToUtf8(const std::wstring& wstr);
    
private:
    static std::wstring GetKoreanTitle() { return L"실행 오류"; }
    static std::wstring GetEnglishTitle() { return L"Execution Error"; }
    
    static std::wstring GetKoreanMessage(const ProcessInfo& processInfo);
    static std::wstring GetEnglishMessage(const ProcessInfo& processInfo);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MESSAGE_UTILS_H_