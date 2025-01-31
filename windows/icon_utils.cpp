#include "icon_utils.h"

namespace flutter_alone {

HICON IconUtils::GetAppIcon() {
   std::wstring exePath = GetExecutablePath();

   // Extract icon
   HICON hIcon = ExtractIconW(
       GetModuleHandleW(NULL),  // Current process
       exePath.c_str(),         // Executable path
       0                        // First icon
   );

   return hIcon;
}

void IconUtils::DestroyAppIcon(HICON hIcon) {
   if (hIcon) {
       DestroyIcon(hIcon);
   }
}

std::wstring IconUtils::GetExecutablePath() {
   WCHAR path[MAX_PATH];
   GetModuleFileNameW(NULL, path, MAX_PATH);
   return std::wstring(path);
}

}  // namespace flutter_alone