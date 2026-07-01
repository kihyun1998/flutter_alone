#ifndef FLUTTER_ALONE_LINUX_LOCK_FILE_H_
#define FLUTTER_ALONE_LINUX_LOCK_FILE_H_

#include <sys/types.h>  // pid_t

#include <string>

namespace flutter_alone {

// Owns a single-instance advisory (flock) lock on a lock file.
//
// Invariant: `path` is non-empty IFF we hold the lock (`fd >= 0`). A handle that
// does not hold the lock owns nothing and therefore cannot unlink any file. This
// invariant is the whole point of the type: it makes the "path set but lock not
// held" state (the root cause of issue #1) unrepresentable.
//
// LockHandle intentionally has NO destructor: ownership is released explicitly
// via ReleaseLock(). Callers may therefore adopt a handle with plain assignment
// (e.g. `*dst = std::move(src)`) and drop the moved-from source without a
// double-close. Do NOT add an RAII destructor without also giving the type move
// operations that zero the moved-from `fd`, or that assignment pattern would
// reintroduce a double-close/double-unlink.
struct LockHandle {
  int fd = -1;
  std::string path;

  bool held() const { return fd >= 0; }
};

enum class LockOutcome {
  kAcquired,     // we now hold the lock
  kHeldByOther,  // another open file description holds it; existing_pid may be set
  kIoError,      // open()/write() failed
};

struct LockResult {
  LockHandle handle;      // held() only when outcome == kAcquired
  LockOutcome outcome;
  pid_t existing_pid;     // holder PID when outcome == kHeldByOther, else -1
};

// Attempts to acquire an exclusive advisory lock on `lock_path`.
//
// On success: outcome == kAcquired, handle.held() == true, handle.path == lock_path,
//   and `current_pid` is written into the file.
// On contention: outcome == kHeldByOther, handle owns nothing, existing_pid holds
//   the PID read from the file (or -1 if unreadable).
// On I/O failure: outcome == kIoError, handle owns nothing.
//
// The returned handle only ever owns the lock on the kAcquired path, so a caller
// that records ownership from `handle` can never adopt a file it does not hold.
LockResult AcquireLock(const std::string& lock_path, pid_t current_pid);

// Releases a held lock: unlocks, closes the fd, and unlinks the lock file (which
// only the owner ever holds). A no-op for a non-holding handle. After return,
// handle->held() == false and handle->path is empty.
void ReleaseLock(LockHandle* handle);

}  // namespace flutter_alone

#endif  // FLUTTER_ALONE_LINUX_LOCK_FILE_H_
