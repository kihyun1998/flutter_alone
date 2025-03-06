#ifndef FLUTTER_PLUGIN_MUTEX_UTILS_H_
#define FLUTTER_PLUGIN_MUTEX_UTILS_H_

#include <string>
#include <windows.h>

namespace flutter_alone {

class MutexUtils {
public:
    /**
     * Generate mutex name based on package id, app name and optional suffix
     * 
     * @param packageId The package identifier
     * @param appName The application name
     * @param suffix Optional suffix for the mutex name
     * @return Generated mutex name
     */
    static std::wstring GenerateMutexName(
        const std::wstring& packageId,
        const std::wstring& appName,
        const std::wstring& suffix = L"");

    /**
     * Check if input strings are valid for mutex name creation
     * 
     * @param packageId The package identifier
     * @param appName The application name
     * @return True if valid, false otherwise
     */
    static bool ValidateMutexNameInputs(
        const std::wstring& packageId,
        const std::wstring& appName);

    /**
     * Create default mutex name when required fields are missing
     * 
     * @return Default mutex name
     */
    static std::wstring GetDefaultMutexName();

private:
    // Default mutex name prefix for global scope
    static const std::wstring DEFAULT_MUTEX_PREFIX;
    
    // Default application identifier
    static const std::wstring DEFAULT_APP_IDENTIFIER;
    
    // Sanitize input string for mutex name (remove invalid characters)
    static std::wstring SanitizeNamePart(const std::wstring& input);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MUTEX_UTILS_H_