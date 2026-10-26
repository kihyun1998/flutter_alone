#include "../mutex_guard.h"

#include <gtest/gtest.h>

#include <string>

namespace flutter_alone {
namespace {

// A unique Local\ mutex name per test, scoped to this process so parallel CI
// runs do not collide. Local\ (session) namespace avoids needing privileges.
std::wstring UniqueName(const wchar_t* tag) {
  return L"Local\\flutter_alone_test_" + std::wstring(tag) + L"_" +
         std::to_wstring(GetCurrentProcessId());
}

// Behavior 1 (tracer): acquiring a fresh name succeeds and is held.
TEST(MutexGuardTest, AcquiringFreshNameSucceeds) {
  const std::wstring name = UniqueName(L"fresh");

  MutexGuard guard;
  EXPECT_EQ(guard.Acquire(name), MutexAcquireOutcome::kAcquired);
  EXPECT_TRUE(guard.held());
}

// Behavior 2: while one guard holds a name, a second acquire loses the race and
// owns nothing.
TEST(MutexGuardTest, SecondAcquireOfHeldNameReportsAlreadyExists) {
  const std::wstring name = UniqueName(L"contended");

  MutexGuard first;
  ASSERT_EQ(first.Acquire(name), MutexAcquireOutcome::kAcquired);

  MutexGuard second;
  EXPECT_EQ(second.Acquire(name), MutexAcquireOutcome::kAlreadyExists);
  EXPECT_FALSE(second.held());
}

// Behavior 3: Exists() reflects whether the named mutex is currently held.
TEST(MutexGuardTest, ExistsReflectsWhetherTheMutexIsHeld) {
  const std::wstring name = UniqueName(L"exists");
  EXPECT_FALSE(MutexGuard::Exists(name));

  MutexGuard guard;
  ASSERT_EQ(guard.Acquire(name), MutexAcquireOutcome::kAcquired);
  EXPECT_TRUE(MutexGuard::Exists(name));

  guard.Release();
  EXPECT_FALSE(MutexGuard::Exists(name));
}

// Behavior 4: releasing frees the name so it can be acquired again.
TEST(MutexGuardTest, ReleaseFreesTheNameForReacquisition) {
  const std::wstring name = UniqueName(L"reacquire");

  MutexGuard guard;
  ASSERT_EQ(guard.Acquire(name), MutexAcquireOutcome::kAcquired);
  guard.Release();
  EXPECT_FALSE(guard.held());

  MutexGuard again;
  EXPECT_EQ(again.Acquire(name), MutexAcquireOutcome::kAcquired);
}

// Behavior 5: name validation mirrors the native constraints.
TEST(MutexGuardTest, ValidatesMutexNames) {
  EXPECT_TRUE(IsValidMutexName(L"Global\\com.example.app_MyApp"));
  EXPECT_FALSE(IsValidMutexName(L""));                     // empty
  EXPECT_FALSE(IsValidMutexName(std::wstring(261, L'a')));  // over 260 chars
  EXPECT_FALSE(IsValidMutexName(L"Global\\Team\\App"));    // embedded backslash
}

// Behavior 6: Acquire rejects an invalid name without taking ownership.
TEST(MutexGuardTest, AcquireRejectsAnInvalidName) {
  MutexGuard guard;
  EXPECT_EQ(guard.Acquire(L""), MutexAcquireOutcome::kInvalidName);
  EXPECT_FALSE(guard.held());
}

// Names the mutex the helper below holds; unset in normal runs.
constexpr wchar_t kHoldMutexVariable[] = L"FLUTTER_ALONE_TEST_HOLD_MUTEX";

// Helper mode, started by Behavior 7 in a separate process: holds the named
// mutex until the process is terminated. Skipped when the variable is unset.
TEST(MutexGuardHelper, HoldsTheNamedMutexUntilTerminated) {
  wchar_t name[256];
  const DWORD length = GetEnvironmentVariableW(kHoldMutexVariable, name, 256);
  if (length == 0 || length >= 256) GTEST_SKIP() << "helper mode only";
  MutexGuard guard;
  if (guard.Acquire(name) != MutexAcquireOutcome::kAcquired) ExitProcess(2);
  Sleep(INFINITE);
}

// Behavior 7: a mutex another process holds makes Exists() true and Acquire()
// lose, until that process is terminated.
TEST(MutexGuardTest, AnotherProcessHoldsTheMutexUntilTerminated) {
  const std::wstring name = UniqueName(L"other_process");

  wchar_t exe[MAX_PATH];
  ASSERT_GT(GetModuleFileNameW(nullptr, exe, MAX_PATH), 0u);
  std::wstring command = L"\"" + std::wstring(exe) +
                         L"\" --gtest_filter=MutexGuardHelper.*";
  SetEnvironmentVariableW(kHoldMutexVariable, name.c_str());
  STARTUPINFOW startup = {};
  startup.cb = sizeof(startup);
  PROCESS_INFORMATION helper = {};
  const BOOL started =
      CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE,
                     CREATE_NO_WINDOW, nullptr, nullptr, &startup, &helper);
  SetEnvironmentVariableW(kHoldMutexVariable, nullptr);
  ASSERT_TRUE(started);

  bool held_by_helper = false;
  for (int i = 0; i < 200 && !held_by_helper; ++i) {
    held_by_helper = MutexGuard::Exists(name);
    if (!held_by_helper) Sleep(50);
  }
  MutexGuard ours;
  const MutexAcquireOutcome while_held = ours.Acquire(name);
  ours.Release();

  TerminateProcess(helper.hProcess, 1);
  WaitForSingleObject(helper.hProcess, 10000);
  CloseHandle(helper.hThread);
  CloseHandle(helper.hProcess);
  const bool exists_after = MutexGuard::Exists(name);
  MutexGuard after;
  const MutexAcquireOutcome after_kill = after.Acquire(name);

  ASSERT_TRUE(held_by_helper);
  EXPECT_EQ(while_held, MutexAcquireOutcome::kAlreadyExists);
  EXPECT_FALSE(exists_after);
  EXPECT_EQ(after_kill, MutexAcquireOutcome::kAcquired);
}

}  // namespace
}  // namespace flutter_alone
