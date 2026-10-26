#include "../lock_file.h"

#include <gtest/gtest.h>

#include <fcntl.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/wait.h>
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

// A lock owner running in a forked child process.
struct HolderProcess {
  pid_t pid = -1;
  int release_fd = -1;  // a byte written here makes the holder release and exit
  bool acquired = false;
};

// Forks a child that acquires `path`, reports whether it did, then waits on
// the release pipe; EOF on that pipe ends it without releasing.
HolderProcess StartHolder(const std::string& path) {
  HolderProcess holder;
  int report[2];
  int release[2];
  if (pipe2(report, O_CLOEXEC) != 0) return holder;
  if (pipe2(release, O_CLOEXEC) != 0) {
    close(report[0]);
    close(report[1]);
    return holder;
  }
  pid_t pid = fork();
  if (pid == 0) {
    close(report[0]);
    close(release[1]);
    LockResult held = AcquireLock(path, getpid());
    char acquired = held.outcome == LockOutcome::kAcquired ? 1 : 0;
    ssize_t sent = write(report[1], &acquired, 1);
    (void)sent;
    char command;
    if (read(release[0], &command, 1) == 1) ReleaseLock(&held.handle);
    _exit(0);
  }
  close(report[1]);
  close(release[0]);
  if (pid < 0) {
    close(report[0]);
    close(release[1]);
    return holder;
  }
  holder.pid = pid;
  holder.release_fd = release[1];
  char acquired = 0;
  holder.acquired = read(report[0], &acquired, 1) == 1 && acquired == 1;
  close(report[0]);
  return holder;
}

// Ends the holder: kills it if `kill_it`, otherwise asks it to release.
void StopHolder(HolderProcess* holder, bool kill_it) {
  if (holder->pid <= 0) return;
  if (kill_it) {
    kill(holder->pid, SIGKILL);
  } else {
    char command = 1;
    ssize_t sent = write(holder->release_fd, &command, 1);
    (void)sent;
  }
  waitpid(holder->pid, nullptr, 0);
  close(holder->release_fd);
  holder->pid = -1;
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

// Behavior 5: a launch that opened the file before the owner released it must
// not lock the unlinked file, or it and the next launch would both run.
TEST(LockFileTest, LockingAFileTheOwnerUnlinkedIsRefused) {
  const std::string path = MakeTempLockPath("unlinked");
  unlink(path.c_str());

  LockResult owner = AcquireLock(path, 111);
  ASSERT_EQ(owner.outcome, LockOutcome::kAcquired);

  // A second launch has opened the file but not yet locked it...
  int late_fd = open(path.c_str(), O_RDWR | O_NOFOLLOW);
  ASSERT_GE(late_fd, 0);

  // ...when the owner exits: unlock, close, unlink.
  ReleaseLock(&owner.handle);

  LockResult late = LockOpenedFile(late_fd, path, 222);
  EXPECT_EQ(late.outcome, LockOutcome::kStale);
  EXPECT_FALSE(late.handle.held());

  // The next launch creates a fresh file and is the only instance.
  LockResult next = AcquireLock(path, 333);
  EXPECT_EQ(next.outcome, LockOutcome::kAcquired);
  ReleaseLock(&next.handle);
}

// Behavior 6: a child the owner exec'd must not inherit the lock, or it keeps
// the lock after the owner dies and every new launch is refused.
TEST(LockFileTest, ChildOfAKilledOwnerDoesNotKeepTheLock) {
  const std::string path = MakeTempLockPath("inherited");
  unlink(path.c_str());

  int report[2];
  ASSERT_EQ(pipe2(report, O_CLOEXEC), 0);

  pid_t owner = fork();
  ASSERT_GE(owner, 0);
  if (owner == 0) {
    // The owner acquires, then execs a long-running helper without closing
    // any descriptor.
    pid_t helper = -1;
    int execd[2];
    if (AcquireLock(path, getpid()).outcome == LockOutcome::kAcquired &&
        pipe2(execd, O_CLOEXEC) == 0) {
      helper = fork();
      if (helper == 0) {
        execlp("sleep", "sleep", "30", static_cast<char*>(nullptr));
        char failed = 1;
        ssize_t ignored = write(execd[1], &failed, 1);
        (void)ignored;
        _exit(127);
      }
      // EOF on the close-on-exec pipe: the helper has exec'd.
      close(execd[1]);
      char failed;
      if (read(execd[0], &failed, 1) != 0) helper = -1;
      close(execd[0]);
    }
    ssize_t sent = write(report[1], &helper, sizeof(helper));
    (void)sent;
    pause();
    _exit(0);
  }

  close(report[1]);
  pid_t helper = -1;
  ssize_t got = read(report[0], &helper, sizeof(helper));
  close(report[0]);
  kill(owner, SIGKILL);
  waitpid(owner, nullptr, 0);
  ASSERT_EQ(got, static_cast<ssize_t>(sizeof(helper)));
  ASSERT_GT(helper, 0) << "the owner did not acquire the lock";
  const bool helper_outlived_owner = kill(helper, 0) == 0;

  LockResult next = AcquireLock(path, 444);
  kill(helper, SIGKILL);
  ReleaseLock(&next.handle);
  unlink(path.c_str());

  ASSERT_TRUE(helper_outlived_owner);
  EXPECT_EQ(next.outcome, LockOutcome::kAcquired);
}

// Behavior 7: a lock another process holds refuses this process and names
// that process as the holder, until the holder is killed.
TEST(LockFileTest, AnotherProcessHoldsTheLockUntilItIsKilled) {
  const std::string path = MakeTempLockPath("other_process");
  unlink(path.c_str());

  HolderProcess holder = StartHolder(path);
  const pid_t holder_pid = holder.pid;
  LockResult while_held = AcquireLock(path, 555);
  ReleaseLock(&while_held.handle);
  StopHolder(&holder, /*kill_it=*/true);
  LockResult after_kill = AcquireLock(path, 556);
  ReleaseLock(&after_kill.handle);
  unlink(path.c_str());

  ASSERT_TRUE(holder.acquired);
  EXPECT_EQ(while_held.outcome, LockOutcome::kHeldByOther);
  EXPECT_EQ(while_held.existing_pid, holder_pid);
  EXPECT_EQ(after_kill.outcome, LockOutcome::kAcquired);
}

// Behavior 8: Behavior 5 holds when the owner that releases and unlinks the
// file is another process.
TEST(LockFileTest, LockingAFileAnotherProcessUnlinkedIsRefused) {
  const std::string path = MakeTempLockPath("other_unlinked");
  unlink(path.c_str());

  HolderProcess holder = StartHolder(path);
  int late_fd = open(path.c_str(), O_RDWR | O_NOFOLLOW | O_CLOEXEC);
  StopHolder(&holder, /*kill_it=*/false);
  LockResult late;
  late.outcome = LockOutcome::kIoError;
  if (late_fd >= 0) late = LockOpenedFile(late_fd, path, 222);
  ReleaseLock(&late.handle);
  LockResult next = AcquireLock(path, 333);
  ReleaseLock(&next.handle);
  unlink(path.c_str());

  ASSERT_TRUE(holder.acquired);
  ASSERT_GE(late_fd, 0);
  EXPECT_EQ(late.outcome, LockOutcome::kStale);
  EXPECT_EQ(next.outcome, LockOutcome::kAcquired);
}

}  // namespace
}  // namespace flutter_alone
