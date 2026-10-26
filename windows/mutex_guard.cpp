#include "mutex_guard.h"

#include <sddl.h>

#include <mutex>
#include <set>

namespace flutter_alone {

namespace {
// Everyone gets SYNCHRONIZE; Creator/Owner gets full mutex access. This lets a
// mutex created by one user be detected by another (cross-user detection).
constexpr wchar_t kMutexSecurityDescriptor[] =
    L"D:(A;;0x00100000;;;WD)(A;;0x001F0001;;;CO)";

// Names held by a MutexGuard in this process, and the lock guarding them.
std::mutex& HeldNamesLock() {
  static std::mutex lock;
  return lock;
}
std::set<std::wstring>& HeldNames() {
  static std::set<std::wstring> names;
  return names;
}
}  // namespace

bool IsValidMutexName(const std::wstring& name) {
  if (name.empty() || name.length() > kMaxMutexNameLength) {
    return false;
  }
  // A single Global\ or Local\ prefix is expected; reject a backslash embedded
  // after it. The prefix backslash sits at index <= 6, so search from index 7.
  if (name.find(L'\\', 7) != std::wstring::npos) {
    return false;
  }
  return true;
}

MutexGuard::~MutexGuard() { Release(); }

MutexGuard::MutexGuard(MutexGuard&& other) noexcept
    : handle_(other.handle_), name_(std::move(other.name_)) {
  other.handle_ = nullptr;
  other.name_.clear();
}

MutexGuard& MutexGuard::operator=(MutexGuard&& other) noexcept {
  if (this != &other) {
    Release();
    handle_ = other.handle_;
    name_ = std::move(other.name_);
    other.handle_ = nullptr;
    other.name_.clear();
  }
  return *this;
}

MutexAcquireOutcome MutexGuard::Acquire(const std::wstring& name) {
  if (handle_ != nullptr) {
    // This guard already owns a mutex; treat as contention rather than leaking.
    return MutexAcquireOutcome::kAlreadyExists;
  }
  if (!IsValidMutexName(name)) {
    return MutexAcquireOutcome::kInvalidName;
  }
  // A name another guard in this process holds is refused before any wait.
  std::lock_guard<std::mutex> held_lock(HeldNamesLock());
  if (HeldNames().count(name) != 0) {
    return MutexAcquireOutcome::kAlreadyExists;
  }

  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = FALSE;

  PSECURITY_DESCRIPTOR pSD = nullptr;
  if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(
          kMutexSecurityDescriptor, SDDL_REVISION_1, &pSD, nullptr)) {
    pSD = nullptr;  // fall back to default security on failure
  }
  sa.lpSecurityDescriptor = pSD;

  HANDLE handle = CreateMutexW(&sa, TRUE, name.c_str());
  const DWORD last_error = GetLastError();

  if (pSD != nullptr) {
    LocalFree(pSD);
  }

  if (handle != nullptr) {
    if (last_error == ERROR_ALREADY_EXISTS) {
      // Existed and we could open it: ours only if it has no live owner.
      return TakeOver(handle, name);
    }
    return Adopt(handle, name);
  }

  // CreateMutexW returned null. ERROR_ACCESS_DENIED means the named mutex
  // already exists but its restrictive DACL (Everyone gets SYNCHRONIZE only, not
  // the full access CreateMutexW requests) denies us, so it is reopened with
  // SYNCHRONIZE for the takeover wait. Any other failure is an error.
  if (last_error == ERROR_ACCESS_DENIED) {
    HANDLE existing = OpenMutexW(SYNCHRONIZE, FALSE, name.c_str());
    if (existing == nullptr) return MutexAcquireOutcome::kAlreadyExists;
    return TakeOver(existing, name);
  }
  return MutexAcquireOutcome::kError;
}

// Takes ownership of an existing mutex through `existing` when nobody owns it
// or its owner died (abandoned); otherwise closes `existing` and reports a live
// owner (timeout) or an error (failed wait). The caller holds HeldNamesLock().
MutexAcquireOutcome MutexGuard::TakeOver(HANDLE existing,
                                         const std::wstring& name) {
  const DWORD waited = WaitForSingleObject(existing, 0);
  if (waited == WAIT_ABANDONED || waited == WAIT_OBJECT_0) {
    return Adopt(existing, name);
  }
  CloseHandle(existing);
  return waited == WAIT_TIMEOUT ? MutexAcquireOutcome::kAlreadyExists
                                : MutexAcquireOutcome::kError;
}

// Records `handle` as this guard's owned mutex. The caller holds
// HeldNamesLock().
MutexAcquireOutcome MutexGuard::Adopt(HANDLE handle, const std::wstring& name) {
  handle_ = handle;
  name_ = name;
  HeldNames().insert(name);
  return MutexAcquireOutcome::kAcquired;
}

void MutexGuard::Release() {
  if (handle_ != nullptr) {
    ReleaseMutex(handle_);
    CloseHandle(handle_);
    handle_ = nullptr;
    std::lock_guard<std::mutex> held_lock(HeldNamesLock());
    HeldNames().erase(name_);
    name_.clear();
  }
}

bool MutexGuard::Exists(const std::wstring& name) {
  if (name.empty()) {
    return false;
  }
  HANDLE handle = OpenMutexW(SYNCHRONIZE, FALSE, name.c_str());
  if (handle != nullptr) {
    CloseHandle(handle);
    return true;
  }
  return false;
}

}  // namespace flutter_alone
