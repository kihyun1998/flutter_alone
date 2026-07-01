#include "../message_utils.h"

#include <gtest/gtest.h>

// The dialog string table now lives in Dart (single source of truth); the only
// pure Windows message helper left is the UTF-8 to wide conversion.

namespace flutter_alone {
namespace {

TEST(MessageUtilsTest, Utf8ToWideConvertsCorrectly) {
  EXPECT_EQ(MessageUtils::Utf8ToWide("hello"), L"hello");
  EXPECT_EQ(MessageUtils::Utf8ToWide(""), L"");
  // UTF-8 bytes EC 8B A4 encode U+C2E4 (Korean syllable), an independent check
  // of the multibyte-to-wide conversion.
  EXPECT_EQ(MessageUtils::Utf8ToWide("\xEC\x8B\xA4"), L"\xC2E4");
}

}  // namespace
}  // namespace flutter_alone
