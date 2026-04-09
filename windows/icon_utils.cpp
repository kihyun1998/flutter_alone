#include "icon_utils.h"

namespace flutter_alone {

HICON IconUtils::GetAppIcon() {
   std::wstring exePath = GetExecutablePath();
   if (exePath.empty()) return NULL;

   return ExtractIconW(
       GetModuleHandleW(NULL),
       exePath.c_str(),
       0
   );
}

std::wstring IconUtils::GetExecutablePath() {
   WCHAR path[MAX_PATH];
   if (GetModuleFileNameW(NULL, path, MAX_PATH) == 0) {
       return std::wstring();
   }
   return std::wstring(path);
}

}  // namespace flutter_alone
