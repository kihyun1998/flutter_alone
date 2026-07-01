#include "mutex_guard.h"

#include <sddl.h>

namespace flutter_alone {

namespace {
// Everyone gets SYNCHRONIZE; Creator/Owner gets full mutex access. This lets a
// mutex created by one user be detected by another (cross-user detection).
constexpr wchar_t kMutexSecurityDescriptor[] =
    L"D:(A;;0x00100000;;;WD)(A;;0x001F0001;;;CO)";
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

MutexGuard::MutexGuard(MutexGuard&& other) noexcept : handle_(other.handle_) {
  other.handle_ = nullptr;
}

MutexGuard& MutexGuard::operator=(MutexGuard&& other) noexcept {
  if (this != &other) {
    Release();
    handle_ = other.handle_;
    other.handle_ = nullptr;
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
      // Existed and we could open it; we never owned it, so drop our handle.
      CloseHandle(handle);
      return MutexAcquireOutcome::kAlreadyExists;
    }
    handle_ = handle;
    return MutexAcquireOutcome::kAcquired;
  }

  // CreateMutexW returned null. ERROR_ACCESS_DENIED means the named mutex
  // already exists but its restrictive DACL (Everyone gets SYNCHRONIZE only, not
  // the full access CreateMutexW requests) denies us -- i.e. another instance
  // owns it. Any other failure is a genuine error.
  if (last_error == ERROR_ACCESS_DENIED) {
    return MutexAcquireOutcome::kAlreadyExists;
  }
  return MutexAcquireOutcome::kError;
}

void MutexGuard::Release() {
  if (handle_ != nullptr) {
    ReleaseMutex(handle_);
    CloseHandle(handle_);
    handle_ = nullptr;
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
