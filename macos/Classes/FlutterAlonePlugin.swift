import Cocoa
import FlutterMacOS
import AppKit // Add AppKit for NSRunningApplication

public class FlutterAlonePlugin: NSObject, FlutterPlugin {
  // Store the path of the lock file created by this instance
  private var currentLockFilePath: String?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_alone", binaryMessenger: registrar.messenger)
    let instance = FlutterAlonePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkAndRun":
      guard let args = call.arguments as? [String: Any],
            let lockFilePath = args["lockFilePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "lockFilePath is required", details: nil))
        return
      }
      
      let windowTitle = args["windowTitle"] as? String // Optional window title
      
      self.currentLockFilePath = lockFilePath // Store for dispose

      let canRun = self.checkAndRun(lockFilePath: lockFilePath, windowTitle: windowTitle)
      result(canRun)

    case "dispose":
      self.dispose()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Core Logic

  private func checkAndRun(lockFilePath: String, windowTitle: String?) -> Bool {
    let fileManager = FileManager.default
    let currentPid = ProcessInfo.processInfo.processIdentifier

    if fileManager.fileExists(atPath: lockFilePath) {
      // Lock file exists, check if the process is still running
      if let existingPid = readPid(from: lockFilePath) {
        if isRunning(pid: existingPid) {
          // Another instance is running, activate its window
          if let app = NSRunningApplication(processIdentifier: existingPid) {
            app.activate(options: [.activateIgnoringOtherApps])
          } else if let title = windowTitle, !title.isEmpty {
            // Fallback: try to find and activate by window title
            // This is less reliable and might require Accessibility permissions
            // For simplicity, we'll just activate the existing app by PID if found.
            // If not found by PID, we assume it's a different app or a hidden window.
            // More robust window activation by title would involve iterating windows.
            // For now, we rely on PID activation.
          }
          return false // Cannot run, another instance is active
        } else {
          // Stale lock file, process is dead. Clean up and proceed.
          removeLockFile(path: lockFilePath)
        }
      } else {
        // Lock file exists but PID cannot be read. Treat as stale.
        removeLockFile(path: lockFilePath)
      }
    }

    // No lock file, or stale lock file cleaned up. Create a new one.
    return createLockFile(path: lockFilePath, pid: currentPid)
  }

  private func dispose() {
    if let path = currentLockFilePath {
      removeLockFile(path: path)
      currentLockFilePath = nil
    }
  }

  // MARK: - Helper Functions

  private func isRunning(pid: pid_t) -> Bool {
    // Check if a process with the given PID is running
    // kill(pid, 0) checks if the process exists and you have permission to send a signal
    return kill(pid, 0) == 0
  }

  private func activateApp(pid: pid_t) {
    if let app = NSRunningApplication(processIdentifier: pid) {
      app.activate(options: [.activateIgnoringOtherApps])
    }
  }

  private func createLockFile(path: String, pid: pid_t) -> Bool {
    let pidString = String(pid)
    guard let data = pidString.data(using: .utf8) else {
      return false
    }
    
    do {
      // Write atomically to ensure integrity
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
      return true
    } catch {
      print("Error creating lock file at \(path): \(error)")
      return false
    }
  }

  private func readPid(from path: String) -> pid_t? {
    do {
      let pidString = try String(contentsOfFile: path, encoding: .utf8)
      return pid_t(pidString.trimmingCharacters(in: .whitespacesAndNewlines))
    } catch {
      print("Error reading PID from lock file at \(path): \(error)")
      return nil
    }
  }

  private func removeLockFile(path: String) {
    do {
      try FileManager.default.removeItem(atPath: path)
    } catch {
      print("Error removing lock file at \(path): \(error)")
    }
  }
}