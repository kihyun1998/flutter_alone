#include "../process_utils.h"

#include <gtest/gtest.h>

// ProcessUtils::IsSameExecutable is a pure path comparison (GetFullPathNameW +
// case-insensitive compare), so it is unit-testable without live processes. The
// rest of ProcessUtils enumerates real processes/windows and is not covered here.

namespace flutter_alone {
namespace {

TEST(ProcessUtilsTest, IdenticalPathsAreSame) {
  EXPECT_TRUE(
      ProcessUtils::IsSameExecutable(L"C:\\dir\\app.exe", L"C:\\dir\\app.exe"));
}

TEST(ProcessUtilsTest, ComparisonIsCaseInsensitive) {
  EXPECT_TRUE(
      ProcessUtils::IsSameExecutable(L"C:\\Dir\\App.EXE", L"c:\\dir\\app.exe"));
}

TEST(ProcessUtilsTest, DifferentPathsAreNotSame) {
  EXPECT_FALSE(ProcessUtils::IsSameExecutable(L"C:\\dir\\app.exe",
                                              L"C:\\dir\\other.exe"));
}

TEST(ProcessUtilsTest, NormalizesDotSegments) {
  EXPECT_TRUE(ProcessUtils::IsSameExecutable(L"C:\\dir\\.\\app.exe",
                                             L"C:\\dir\\app.exe"));
}

TEST(ProcessUtilsTest, EmptyPathIsNeverSame) {
  EXPECT_FALSE(ProcessUtils::IsSameExecutable(L"", L"C:\\dir\\app.exe"));
  EXPECT_FALSE(ProcessUtils::IsSameExecutable(L"C:\\dir\\app.exe", L""));
}

}  // namespace
}  // namespace flutter_alone
