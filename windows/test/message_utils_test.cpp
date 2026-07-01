#include "../message_utils.h"

#include <gtest/gtest.h>

// Characterization tests for the pure MessageUtils string table and the UTF-8 to
// wide conversion. All Korean literals use \x escapes so this source stays ASCII
// (MSVC reads source as the system codepage; non-ASCII would break the build).

namespace flutter_alone {
namespace {

TEST(MessageUtilsTest, EnglishTitleAndMessage) {
  EXPECT_EQ(MessageUtils::GetTitleText(MessageType::English),
            L"Execution Error");
  EXPECT_EQ(MessageUtils::GetMessageText(MessageType::English),
            L"Application is already running in another account.");
}

TEST(MessageUtilsTest, KoreanTitleAndMessage) {
  // L"\xC2E4\xD589 \xC624\xB958" == "실행 오류" (Korean "Execution Error").
  EXPECT_EQ(MessageUtils::GetTitleText(MessageType::Korean),
            L"\xC2E4\xD589 \xC624\xB958");
  // Korean "Application is already running in another account."
  EXPECT_EQ(MessageUtils::GetMessageText(MessageType::Korean),
            L"\xC774\xBBF8 \xB2E4\xB978 \xACC4\xC815\xC5D0\xC11C \xC571\xC744 "
            L"\xC2E4\xD589\xC911\xC785\xB2C8\xB2E4.");
}

TEST(MessageUtilsTest, CustomUsesProvidedTextOrFallsBack) {
  EXPECT_EQ(MessageUtils::GetTitleText(MessageType::Custom, L"My Title"),
            L"My Title");
  EXPECT_EQ(MessageUtils::GetTitleText(MessageType::Custom, L""), L"Error");

  EXPECT_EQ(MessageUtils::GetMessageText(MessageType::Custom, L"My Message"),
            L"My Message");
  // Note: the custom empty fallback has no trailing period, unlike the English
  // message above. Captured as-is.
  EXPECT_EQ(MessageUtils::GetMessageText(MessageType::Custom, L""),
            L"Application is already running in another account");
}

TEST(MessageUtilsTest, Utf8ToWideConvertsCorrectly) {
  EXPECT_EQ(MessageUtils::Utf8ToWide("hello"), L"hello");
  EXPECT_EQ(MessageUtils::Utf8ToWide(""), L"");
  // UTF-8 bytes EC 8B A4 encode U+C2E4 (Korean syllable), an independent check
  // of the multibyte-to-wide conversion.
  EXPECT_EQ(MessageUtils::Utf8ToWide("\xEC\x8B\xA4"), L"\xC2E4");
}

}  // namespace
}  // namespace flutter_alone
