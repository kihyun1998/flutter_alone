#include "mutex_utils.h"
#include <algorithm>
#include <regex>

namespace flutter_alone {

// Default mutex prefix (used for global scope)
const std::wstring MutexUtils::DEFAULT_MUTEX_PREFIX = L"Global\\";

// Default app identifier used when packageId and appName are missing
const std::wstring MutexUtils::DEFAULT_APP_IDENTIFIER = L"FlutterAloneApp_UniqueId";

std::wstring MutexUtils::GenerateMutexName(
    const std::wstring& packageId,
    const std::wstring& appName,
    const std::wstring& suffix){

    // Check if required parameters are valid
    if (!ValidateMutexNameInputs(packageId, appName)) {
        return GetDefaultMutexName();
    }

    // Sanitize input strings
    std::wstring sanitizedPackageId = SanitizeNamePart(packageId);
    std::wstring sanitizedAppName = SanitizeNamePart(appName);
    std::wstring sanitizedSuffix = suffix.empty() ? L"" : L"_" + SanitizeNamePart(suffix);

    // Combine to form mutex name
    std::wstring mutexName = DEFAULT_MUTEX_PREFIX + 
                            sanitizedPackageId + L"_" + 
                            sanitizedAppName + 
                            sanitizedSuffix;

    // Check if the resulting name is too long (max 260 characters for Windows)
    if(mutexName.length() > 260){
        OutputDebugStringW(L"[WARNING] Mutex name is too long, using truncated version");
    mutexName = mutexName.substr(0, 260);
    }

    return mutexName;
}

bool MutexUtils::ValidateMutexNameInputs(
    const std::wstring& packageId,
    const std::wstring& appName){

    // Both packageId and appName must be non-empty
    return !packageId.empty() && !appName.empty();
}

std::wstring MutexUtils::GetDefaultMutexName() {
    return DEFAULT_MUTEX_PREFIX + DEFAULT_APP_IDENTIFIER;
}

std::wstring MutexUtils::SanitizeNamePart(const std::wstring& input) {
    std::wstring result = input;

    // Remove invalid characters (only allow alphanumeric, underscore, dot, and dash)
    std::wregex invalidChars(L"[^a-zA-Z0-9_.-]");
    result = std::regex_replace(result, invalidChars, L"_");

    // Remove consecutive underscores
    std::wregex multipleUnderscores(L"_{2,}");
    result = std::regex_replace(result, multipleUnderscores, L"_");

    // Trim leading and trailing underscores
    if (!result.empty() && result[0] == L'_') {
        result = result.substr(1);
    }

    if (!result.empty() && result[result.length() - 1] == L'_') {
        result = result.substr(0, result.length() - 1);
    }

    return result;
}


}  // namespace flutter_alone