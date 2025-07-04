import Foundation

class ProcessUtils {
    /// Checks if a process with the given process ID (PID) is currently running.
    /// This is done by checking if a process group ID can be retrieved for the PID.
    /// If the process does not exist, `getpgid` will fail.
    /// - Parameter pid: The process ID to check.
    /// - Returns: `true` if the process is running, `false` otherwise.
    static func isProcessRunning(pid: pid_t) -> Bool {
        // A pid of 0 is not a valid process ID.
        if pid <= 0 {
            return false
        }
        // getpgid returns -1 if the process does not exist.
        return getpgid(pid) != -1
    }
}
