#include "../lock_file.h"

#include <gtest/gtest.h>

#include <sys/stat.h>
#include <unistd.h>

#include <cstdlib>
#include <string>

namespace flutter_alone {
namespace {

// A unique lock path per test name, in the temp dir, scoped to this pid so
// parallel CI runs don't collide.
std::string MakeTempLockPath(const char* name) {
  const char* tmp = getenv("TMPDIR");
  if (tmp == nullptr || tmp[0] == '\0') tmp = "/tmp";
  return std::string(tmp) + "/flutter_alone_test_" + name + "_" +
         std::to_string(getpid()) + ".lock";
}

bool FileExists(const std::string& path) {
  struct stat st;
  return stat(path.c_str(), &st) == 0;
}

// Behavior 1 (tracer): acquiring a fresh path succeeds and creates the file.
TEST(LockFileTest, AcquiringFreshPathSucceedsAndCreatesFile) {
  const std::string path = MakeTempLockPath("fresh");
  unlink(path.c_str());

  LockResult r = AcquireLock(path, 4242);

  EXPECT_EQ(r.outcome, LockOutcome::kAcquired);
  EXPECT_TRUE(r.handle.held());
  EXPECT_EQ(r.handle.path, path);
  EXPECT_TRUE(FileExists(path));

  ReleaseLock(&r.handle);
}

// Behavior 2: while a lock is held, a second acquire owns nothing and reports
// the holder's PID (the value the holder wrote, verified against a literal).
TEST(LockFileTest, SecondAcquireReportsHolderPidAndOwnsNothing) {
  const std::string path = MakeTempLockPath("holder");
  unlink(path.c_str());

  LockResult primary = AcquireLock(path, 5150);
  ASSERT_EQ(primary.outcome, LockOutcome::kAcquired);

  LockResult second = AcquireLock(path, 9999);
  EXPECT_EQ(second.outcome, LockOutcome::kHeldByOther);
  EXPECT_FALSE(second.handle.held());
  EXPECT_TRUE(second.handle.path.empty());
  EXPECT_EQ(second.existing_pid, 5150);  // the PID the primary wrote

  ReleaseLock(&primary.handle);
}

// Behavior 3 (REGRESSION for issue #1): releasing a failed (non-owning)
// duplicate handle must NOT delete the primary's lock file, and the primary
// must still hold the lock afterwards.
TEST(LockFileTest, ReleasingAFailedDuplicateDoesNotDeleteOwnersLockFile) {
  const std::string path = MakeTempLockPath("regression");
  unlink(path.c_str());

  LockResult primary = AcquireLock(path, 1111);
  ASSERT_EQ(primary.outcome, LockOutcome::kAcquired);
  ASSERT_TRUE(FileExists(path));

  LockResult duplicate = AcquireLock(path, 2222);
  ASSERT_EQ(duplicate.outcome, LockOutcome::kHeldByOther);
  ASSERT_FALSE(duplicate.handle.held());

  // The duplicate owns nothing, so releasing it must be inert.
  ReleaseLock(&duplicate.handle);

  EXPECT_TRUE(FileExists(path))
      << "duplicate release deleted the primary's lock file (issue #1)";

  // Primary still holds: a third acquire still loses the race.
  LockResult third = AcquireLock(path, 3333);
  EXPECT_EQ(third.outcome, LockOutcome::kHeldByOther);
  EXPECT_FALSE(third.handle.held());

  ReleaseLock(&primary.handle);
}

// Behavior 4: the owner's release removes the file and frees it for reacquire.
TEST(LockFileTest, OwnerReleaseRemovesFileAndAllowsReacquire) {
  const std::string path = MakeTempLockPath("reacquire");
  unlink(path.c_str());

  LockResult first = AcquireLock(path, 111);
  ASSERT_EQ(first.outcome, LockOutcome::kAcquired);

  ReleaseLock(&first.handle);
  EXPECT_FALSE(FileExists(path));
  EXPECT_FALSE(first.handle.held());
  EXPECT_TRUE(first.handle.path.empty());

  LockResult again = AcquireLock(path, 222);
  EXPECT_EQ(again.outcome, LockOutcome::kAcquired);
  ReleaseLock(&again.handle);
}

}  // namespace
}  // namespace flutter_alone
