#include "../process_utils.h"

#include <gtest/gtest.h>

#include <string>

// ProcessUtils::IsSameExecutable and StartedBefore are pure comparisons.
// OlderInstanceRunning is covered with a second copy of this test binary.

namespace flutter_alone {
namespace {

// Selects the helper mode below; unset in normal runs.
constexpr wchar_t kHelperModeVariable[] = L"FLUTTER_ALONE_TEST_PROCESS_HELPER";
constexpr DWORD kSawOlderInstance = 10;
constexpr DWORD kSawNoOlderInstance = 11;

FILETIME At(DWORD high, DWORD low) {
  FILETIME time;
  time.dwHighDateTime = high;
  time.dwLowDateTime = low;
  return time;
}

// Starts this test binary in helper mode `mode`; returns its process info.
bool StartHelper(const wchar_t* mode, PROCESS_INFORMATION* process) {
  wchar_t exe[MAX_PATH];
  if (GetModuleFileNameW(nullptr, exe, MAX_PATH) == 0) return false;
  std::wstring command =
      L"\"" + std::wstring(exe) + L"\" --gtest_filter=ProcessUtilsHelper.*";
  SetEnvironmentVariableW(kHelperModeVariable, mode);
  STARTUPINFOW startup = {};
  startup.cb = sizeof(startup);
  const BOOL started =
      CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE,
                     CREATE_NO_WINDOW, nullptr, nullptr, &startup, process);
  SetEnvironmentVariableW(kHelperModeVariable, nullptr);
  return started != FALSE;
}

// Helper mode, started by the tests below in a separate process:
// "check" exits with whether an older copy of this binary runs; "sleep" stays
// alive until terminated. Skipped when the variable is unset.
TEST(ProcessUtilsHelper, ReportsOrSleeps) {
  wchar_t mode[16];
  const DWORD length = GetEnvironmentVariableW(kHelperModeVariable, mode, 16);
  if (length == 0 || length >= 16) GTEST_SKIP() << "helper mode only";
  if (std::wstring(mode) == L"check") {
    ExitProcess(ProcessUtils::OlderInstanceRunning() ? kSawOlderInstance
                                                     : kSawNoOlderInstance);
  }
  Sleep(INFINITE);
}

TEST(ProcessUtilsTest, StartedBeforeComparesStartTimes) {
  EXPECT_TRUE(ProcessUtils::StartedBefore(At(1, 5), At(1, 6)));
  EXPECT_TRUE(ProcessUtils::StartedBefore(At(1, 0xFFFFFFFF), At(2, 0)));
  EXPECT_FALSE(ProcessUtils::StartedBefore(At(1, 6), At(1, 5)));
  EXPECT_FALSE(ProcessUtils::StartedBefore(At(1, 5), At(1, 5)));
}

TEST(ProcessUtilsTest, UnknownStartTimeIsNeverBefore) {
  EXPECT_FALSE(ProcessUtils::StartedBefore(At(0, 0), At(1, 5)));
}

// A younger copy of the same executable sees this older one as running.
TEST(ProcessUtilsTest, YoungerCopySeesTheOlderOne) {
  PROCESS_INFORMATION helper = {};
  ASSERT_TRUE(StartHelper(L"check", &helper));
  const DWORD waited = WaitForSingleObject(helper.hProcess, 10000);
  DWORD code = 0;
  GetExitCodeProcess(helper.hProcess, &code);
  if (waited != WAIT_OBJECT_0) TerminateProcess(helper.hProcess, 1);
  CloseHandle(helper.hThread);
  CloseHandle(helper.hProcess);

  ASSERT_EQ(waited, WAIT_OBJECT_0);
  EXPECT_EQ(code, kSawOlderInstance);
}

// An older process does not count a younger copy of itself.
TEST(ProcessUtilsTest, OlderCopyIgnoresTheYoungerOne) {
  PROCESS_INFORMATION helper = {};
  ASSERT_TRUE(StartHelper(L"sleep", &helper));
  Sleep(200);
  const bool sees_older = ProcessUtils::OlderInstanceRunning();
  TerminateProcess(helper.hProcess, 1);
  WaitForSingleObject(helper.hProcess, 10000);
  CloseHandle(helper.hThread);
  CloseHandle(helper.hProcess);

  EXPECT_FALSE(sees_older);
}

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
