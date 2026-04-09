#ifndef FLUTTER_PLUGIN_ICON_UTILS_H_
#define FLUTTER_PLUGIN_ICON_UTILS_H_

#include <windows.h>
#include <string>

namespace flutter_alone {

class IconUtils {
public:
    static HICON GetAppIcon();

private:
    static std::wstring GetExecutablePath();
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_ICON_UTILS_H_
