#ifndef FLUTTER_PLUGIN_MESSAGE_UTILS_H_
#define FLUTTER_PLUGIN_MESSAGE_UTILS_H_

#include <string>

namespace flutter_alone {

class MessageUtils {
public:
    // Converts a UTF-8 std::string (as received over the method channel) to a
    // wide string for the Win32 API. The dialog title/message text itself is
    // resolved on the Dart side (single source of truth) and passed through.
    static std::wstring Utf8ToWide(const std::string& str);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MESSAGE_UTILS_H_
