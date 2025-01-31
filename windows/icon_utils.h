#ifndef FLUTTER_PLUGIN_ICON_UTILS_H_
#define FLUTTER_PLUGIN_ICON_UTILS_H_

#include <windows.h>
#include <string>

namespace flutter_alone {

class IconUtils {
public:
    // Extract icon from executable
    static HICON GetAppIcon();
    
    // Release app icon resources
    static void DestroyAppIcon(HICON hIcon);
    
private:
    // Get executable path
    static std::wstring GetExecutablePath();
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_ICON_UTILS_H_