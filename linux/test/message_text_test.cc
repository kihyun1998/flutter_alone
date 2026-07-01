#include "../message_text.h"

#include <gtest/gtest.h>

// This seam is pure C++ (no POSIX/GTK), so unlike lock_file_test it also builds
// and runs on non-Linux hosts. Korean expectations use \x UTF-8 byte escapes to
// keep the source ASCII.

namespace flutter_alone {
namespace {

const char kEnglishBody[] =
    "Application is already running in another account.";
const char kKoreanTitle[] = "\xEC\x95\x8C\xEB\xA6\xBC";
const char kKoreanBody[] =
    "\xEC\x9D\xB4\xEB\xAF\xB8 \xEB\x8B\xA4\xEB\xA5\xB8 "
    "\xEA\xB3\x84\xEC\xA0\x95\xEC\x97\x90\xEC\x84\x9C \xEC\x95\xB1\xEC\x9D\x84 "
    "\xEC\x8B\xA4\xED\x96\x89\xEC\xA4\x91\xEC\x9E\x85\xEB\x8B\x88\xEB\x8B\xA4.";

TEST(MessageTextTest, English) {
  EXPECT_EQ(TitleForType("en", ""), "Notice");
  EXPECT_EQ(MessageForType("en", ""), kEnglishBody);
}

TEST(MessageTextTest, Korean) {
  EXPECT_EQ(TitleForType("ko", ""), kKoreanTitle);
  EXPECT_EQ(MessageForType("ko", ""), kKoreanBody);
}

TEST(MessageTextTest, CustomUsesProvidedTextOrFallsBack) {
  EXPECT_EQ(TitleForType("custom", "My Title"), "My Title");
  EXPECT_EQ(MessageForType("custom", "My Message"), "My Message");
  // Empty custom falls back to English.
  EXPECT_EQ(TitleForType("custom", ""), "Notice");
  EXPECT_EQ(MessageForType("custom", ""), kEnglishBody);
}

TEST(MessageTextTest, UnknownTypeFallsBackToEnglish) {
  EXPECT_EQ(TitleForType("zz", ""), "Notice");
  EXPECT_EQ(MessageForType("zz", ""), kEnglishBody);
}

}  // namespace
}  // namespace flutter_alone
