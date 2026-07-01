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

}  // namespace
}  // namespace flutter_alone
