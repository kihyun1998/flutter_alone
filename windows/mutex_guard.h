#ifndef FLUTTER_ALONE_WINDOWS_MUTEX_GUARD_H_
#define FLUTTER_ALONE_WINDOWS_MUTEX_GUARD_H_

#include <windows.h>

#include <string>

namespace flutter_alone {

// Maximum mutex name length. Application-level policy (not a kernel limit),
// mirrored by the Dart-side WindowsMutexConfig validation.
constexpr size_t kMaxMutexNameLength = 260;

enum class MutexAcquireOutcome {
  kAcquired,       // this guard created and now owns the mutex
  kAlreadyExists,  // another owner already holds a mutex with this name
  kInvalidName,    // name failed validation (empty / too long / embedded '\')
  kError,          // CreateMutexW failed for another reason
};

// Validates a fully-qualified mutex name against the Win32 constraints enforced
// by the plugin: non-empty, <= kMaxMutexNameLength, and no backslash after the
// namespace prefix (a single Global\ or Local\ prefix is expected).
bool IsValidMutexName(const std::wstring& name);

// Owns a named Win32 mutex. RAII: the destructor releases and closes a held
// mutex. Move-only, so ownership is unique; a moved-from guard is left empty.
class MutexGuard {
 public:
  MutexGuard() = default;
  ~MutexGuard();

  MutexGuard(const MutexGuard&) = delete;
  MutexGuard& operator=(const MutexGuard&) = delete;
  MutexGuard(MutexGuard&& other) noexcept;
  MutexGuard& operator=(MutexGuard&& other) noexcept;

  // Creates and takes ownership of the named mutex. Returns kAcquired only when
  // this call created it; kAlreadyExists when another owner already holds it.
  MutexAcquireOutcome Acquire(const std::wstring& name);

  // Releases and closes a held mutex. A no-op when not held.
  void Release();

  bool held() const { return handle_ != nullptr; }

  // True if a mutex with this name currently exists (held by anyone).
  static bool Exists(const std::wstring& name);

 private:
  HANDLE handle_ = nullptr;
};

}  // namespace flutter_alone

#endif  // FLUTTER_ALONE_WINDOWS_MUTEX_GUARD_H_
