#ifndef FLUTTER_ALONE_LINUX_MESSAGE_TEXT_H_
#define FLUTTER_ALONE_LINUX_MESSAGE_TEXT_H_

#include <string>

namespace flutter_alone {

// Pure selection of the "already running" dialog text for the given message
// type ("ko" / "en" / "custom"). No GTK/glib dependency, so it is unit-testable
// without a display. Mirrors the Windows (message_utils) and macOS
// (DuplicateMessage) string tables. "en" and any unrecognized type fall back to
// English; a "custom" type with an empty custom string also falls back.
std::string TitleForType(const std::string& type, const std::string& custom);
std::string MessageForType(const std::string& type, const std::string& custom);

}  // namespace flutter_alone

#endif  // FLUTTER_ALONE_LINUX_MESSAGE_TEXT_H_
