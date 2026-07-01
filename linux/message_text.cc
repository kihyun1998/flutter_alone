#include "message_text.h"

namespace flutter_alone {
namespace {

// "ko" -> Korean; "custom" with a non-empty custom string -> custom; everything
// else (including "en" and unknown types) -> English.
std::string Localized(const std::string& type, const std::string& ko,
                      const std::string& en, const std::string& custom) {
  if (type == "ko") return ko;
  if (type == "custom" && !custom.empty()) return custom;
  return en;
}

}  // namespace

std::string TitleForType(const std::string& type, const std::string& custom) {
  // Korean "\xEC\x95\x8C\xEB\xA6\xBC" == the word for "Notice".
  return Localized(type, "\xEC\x95\x8C\xEB\xA6\xBC", "Notice", custom);
}

std::string MessageForType(const std::string& type, const std::string& custom) {
  return Localized(
      type,
      "\xEC\x9D\xB4\xEB\xAF\xB8 \xEB\x8B\xA4\xEB\xA5\xB8 "
      "\xEA\xB3\x84\xEC\xA0\x95\xEC\x97\x90\xEC\x84\x9C \xEC\x95\xB1\xEC\x9D\x84 "
      "\xEC\x8B\xA4\xED\x96\x89\xEC\xA4\x91\xEC\x9E\x85\xEB\x8B\x88\xEB\x8B\xA4.",
      "Application is already running in another account.", custom);
}

}  // namespace flutter_alone
