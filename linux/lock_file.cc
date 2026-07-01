#include "lock_file.h"

#include <fcntl.h>
#include <sys/file.h>
#include <unistd.h>

#include <cerrno>
#include <cstdlib>
#include <cstring>

namespace flutter_alone {
namespace {

// Read a decimal PID from an already-open fd. Returns -1 on any problem.
pid_t ReadPidFromFd(int fd) {
  char buf[32];
  if (lseek(fd, 0, SEEK_SET) != 0) return -1;
  ssize_t n = read(fd, buf, sizeof(buf) - 1);
  if (n <= 0) return -1;
  buf[n] = '\0';
  char* end = nullptr;
  long pid = strtol(buf, &end, 10);
  if (end == buf || pid <= 0) return -1;
  return static_cast<pid_t>(pid);
}

// Overwrite the file with the decimal PID. fd must be write-open and locked.
bool WritePidToFd(int fd, pid_t pid) {
  if (ftruncate(fd, 0) != 0) return false;
  if (lseek(fd, 0, SEEK_SET) != 0) return false;

  std::string pid_str = std::to_string(pid);
  ssize_t written = write(fd, pid_str.c_str(), pid_str.length());
  if (written < 0 || static_cast<size_t>(written) != pid_str.length()) {
    return false;
  }

  fdatasync(fd);
  return true;
}

}  // namespace

LockResult AcquireLock(const std::string& lock_path, pid_t current_pid) {
  LockResult result;
  result.outcome = LockOutcome::kIoError;
  result.existing_pid = -1;
  // result.handle default-constructs to a non-holding handle (fd -1, empty path).

  // O_NOFOLLOW prevents a symlink at lock_path from redirecting the open.
  int fd = open(lock_path.c_str(), O_CREAT | O_RDWR | O_NOFOLLOW, 0644);
  if (fd < 0) {
    return result;  // kIoError, owns nothing
  }

  if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    // Another open file description holds the lock.
    result.outcome = LockOutcome::kHeldByOther;
    result.existing_pid = ReadPidFromFd(fd);
    close(fd);
    return result;  // owns nothing; cannot unlink the holder's file
  }

  if (!WritePidToFd(fd, current_pid)) {
    flock(fd, LOCK_UN);
    close(fd);
    return result;  // kIoError, owns nothing
  }

  // Success: take ownership. This is the ONLY place `path` is populated, so a
  // non-acquiring caller can never end up owning the file (issue #1).
  result.outcome = LockOutcome::kAcquired;
  result.handle.fd = fd;
  result.handle.path = lock_path;
  return result;
}

void ReleaseLock(LockHandle* handle) {
  if (handle == nullptr || !handle->held()) return;

  flock(handle->fd, LOCK_UN);
  close(handle->fd);
  handle->fd = -1;

  if (!handle->path.empty()) {
    unlink(handle->path.c_str());
    handle->path.clear();
  }
}

}  // namespace flutter_alone
