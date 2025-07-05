import Foundation

/// Manages the creation, locking, and deletion of a lockfile to prevent duplicate app instances.
class FileLockManager {
    private var fileDescriptor: CInt = -1
    private let lockfilePath: String

    /// Initializes the manager with a unique lockfile path based on the bundle ID.
    /// Returns `nil` if the bundle identifier is not available.
    init?(bundleIdentifier: String) {
        let tempDir = NSTemporaryDirectory()
        self.lockfilePath = (tempDir as NSString).appendingPathComponent("\(bundleIdentifier).lock")
    }

    /// Attempts to acquire an exclusive, non-blocking lock on the lockfile.
    /// - Returns: `true` if the lock was acquired, `false` otherwise.
    func lock() -> Bool {
        // Open the file, creating it if it doesn't exist.
        self.fileDescriptor = open(lockfilePath, O_CREAT | O_RDWR, 0o644)
        if fileDescriptor == -1 {
            return false
        }

        // Attempt to acquire a lock without blocking.
        if flock(fileDescriptor, LOCK_EX | LOCK_NB) == -1 {
            close(fileDescriptor)
            fileDescriptor = -1
            return false
        }
        return true
    }

    /// Writes the current process ID to the lockfile.
    func writePID() {
        guard fileDescriptor != -1 else { return }
        
        let pid = getpid() 
        let pidString = String(pid)
        
        // Truncate the file to zero length before writing.
        ftruncate(fileDescriptor, 0)
        // Write the PID string to the file.
        let result = pidString.withCString { ptr in
            write(fileDescriptor, ptr, strlen(ptr))
        }
        if result == -1 {
            // Handle write error if necessary
        }
    }

    /// Reads the process ID from the lockfile.
    /// - Returns: The process ID, or `nil` if it cannot be read.
    func readPID() -> pid_t? {
        let tempFd = open(lockfilePath, O_RDONLY)
        if tempFd == -1 { return nil }
        defer { close(tempFd) }

        let bufferSize = 255
        var buffer = [CChar](repeating: 0, count: bufferSize)
        
        let bytesRead = read(tempFd, &buffer, bufferSize - 1)
        if bytesRead <= 0 { return nil }
        
        let pidString = String(cString: buffer)
        return pid_t(pidString)
    }

    /// Releases the lock and deletes the lockfile.
    func unlock() {
        guard fileDescriptor != -1 else { return }
        
        flock(fileDescriptor, LOCK_UN)
        close(fileDescriptor)
        fileDescriptor = -1
        try? FileManager.default.removeItem(atPath: lockfilePath)
    }
}
