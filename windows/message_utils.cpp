#include "message_utils.h"
#include <windows.h>

namespace flutter_alone {

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
