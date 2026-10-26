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

// Helper mode, started by StartHelper in a separate process: holds the named
// mutex until the process is terminated. Skipped when the variable is unset.
TEST(MutexGuardHelper, HoldsTheNamedMutexUntilTerminated) {
  wchar_t name[256];
  const DWORD length = GetEnvironmentVariableW(kHoldMutexVariable, name, 256);
  if (length == 0 || length >= 256) GTEST_SKIP() << "helper mode only";
  MutexGuard guard;
  if (guard.Acquire(name) != MutexAcquireOutcome::kAcquired) ExitProcess(2);
  Sleep(INFINITE);
}

// A helper process started in helper mode, holding the mutex `name`.
struct HelperProcess {
  PROCESS_INFORMATION process = {};
  bool started = false;
  bool holds = false;  // the helper was seen holding the mutex
};

// Relaunches this test binary in helper mode and waits until it holds `name`.
HelperProcess StartHelper(const std::wstring& name) {
  HelperProcess helper;
  wchar_t exe[MAX_PATH];
  if (GetModuleFileNameW(nullptr, exe, MAX_PATH) == 0) return helper;
  std::wstring command = L"\"" + std::wstring(exe) +
                         L"\" --gtest_filter=MutexGuardHelper.*";
  SetEnvironmentVariableW(kHoldMutexVariable, name.c_str());
  STARTUPINFOW startup = {};
  startup.cb = sizeof(startup);
  helper.started =
      CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE,
                     CREATE_NO_WINDOW, nullptr, nullptr, &startup,
                     &helper.process) != FALSE;
  SetEnvironmentVariableW(kHoldMutexVariable, nullptr);
  for (int i = 0; helper.started && i < 200 && !helper.holds; ++i) {
    helper.holds = MutexGuard::Exists(name);
    if (!helper.holds) Sleep(50);
  }
  return helper;
}

// Terminates the helper; returns whether it exited within 10 seconds.
bool StopHelper(HelperProcess* helper) {
  if (!helper->started) return false;
  TerminateProcess(helper->process.hProcess, 1);
  const bool exited =
      WaitForSingleObject(helper->process.hProcess, 10000) == WAIT_OBJECT_0;
  CloseHandle(helper->process.hThread);
  CloseHandle(helper->process.hProcess);
  helper->started = false;
  return exited;
}

// Behavior 7: a mutex another process holds makes Exists() true and Acquire()
// lose, until that process is terminated.
TEST(MutexGuardTest, AnotherProcessHoldsTheMutexUntilTerminated) {
  const std::wstring name = UniqueName(L"other_process");

  HelperProcess helper = StartHelper(name);
  MutexGuard ours;
  const MutexAcquireOutcome while_held = ours.Acquire(name);
  ours.Release();
  const bool exited = StopHelper(&helper);
  const bool exists_after = MutexGuard::Exists(name);
  MutexGuard after;
  const MutexAcquireOutcome after_kill = after.Acquire(name);

  ASSERT_TRUE(helper.holds);
  ASSERT_TRUE(exited) << "the helper did not exit after terminate";
  EXPECT_EQ(while_held, MutexAcquireOutcome::kAlreadyExists);
  EXPECT_FALSE(exists_after);
  EXPECT_EQ(after_kill, MutexAcquireOutcome::kAcquired);
}

// Behavior 8: when the owner dies while another process still has the mutex
// open, the abandoned mutex is taken over by the next acquire.
TEST(MutexGuardTest, AbandonedMutexKeptOpenByAnotherHandleIsTakenOver) {
  const std::wstring name = UniqueName(L"abandoned");

  HelperProcess helper = StartHelper(name);
  HANDLE outside = OpenMutexW(SYNCHRONIZE, FALSE, name.c_str());
  const bool exited = StopHelper(&helper);
  const bool exists_after = MutexGuard::Exists(name);
  MutexGuard next;
  const MutexAcquireOutcome taken = next.Acquire(name);
  const bool next_holds = next.held();
  next.Release();
  if (outside != nullptr) CloseHandle(outside);

  ASSERT_TRUE(helper.holds);
  ASSERT_NE(outside, nullptr);
  ASSERT_TRUE(exited);
  ASSERT_TRUE(exists_after) << "the open handle should keep the name alive";
  EXPECT_EQ(taken, MutexAcquireOutcome::kAcquired);
  EXPECT_TRUE(next_holds);
}

// Behavior 9: an existing mutex that nobody owns is taken over.
TEST(MutexGuardTest, UnownedMutexIsTakenOver) {
  const std::wstring name = UniqueName(L"unowned");

  HANDLE unowned = CreateMutexW(nullptr, FALSE, name.c_str());
  MutexGuard guard;
  const MutexAcquireOutcome taken = guard.Acquire(name);
  const bool guard_holds = guard.held();
  guard.Release();
  if (unowned != nullptr) CloseHandle(unowned);

  ASSERT_NE(unowned, nullptr);
  EXPECT_EQ(taken, MutexAcquireOutcome::kAcquired);
  EXPECT_TRUE(guard_holds);
}

// Behavior 10: a live owner is never taken over, even while another process
// also has the mutex open.
TEST(MutexGuardTest, LiveOwnerIsNotTakenOverWhileAnotherHandleIsOpen) {
  const std::wstring name = UniqueName(L"live_owner");

  HelperProcess helper = StartHelper(name);
  HANDLE outside = OpenMutexW(SYNCHRONIZE, FALSE, name.c_str());
  MutexGuard ours;
  const MutexAcquireOutcome while_alive = ours.Acquire(name);
  const bool ours_holds = ours.held();
  ours.Release();
  if (outside != nullptr) CloseHandle(outside);
  const bool exited = StopHelper(&helper);

  ASSERT_TRUE(helper.holds);
  ASSERT_NE(outside, nullptr);
  ASSERT_TRUE(exited);
  EXPECT_EQ(while_alive, MutexAcquireOutcome::kAlreadyExists);
  EXPECT_FALSE(ours_holds);
}

}  // namespace
}  // namespace flutter_alone
