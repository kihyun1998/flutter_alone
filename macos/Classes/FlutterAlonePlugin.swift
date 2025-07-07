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
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments are required", details: nil))
        return
      }

      guard let lockFilePath = args["lockFilePath"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "lockFilePath is required for macOS", details: nil))
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
      if let existingPid = readPid(from: lockFilePath) {
        if isRunning(pid: existingPid) {
          if let app = NSRunningApplication(processIdentifier: existingPid) {
            app.activate(options: [.activateIgnoringOtherApps])

            DispatchQueue.main.async {
                if let appDelegate = NSApplication.shared.delegate as? FlutterAppDelegate {
                    if let window = appDelegate.mainFlutterWindow {
                        window.makeKeyAndOrderFront(nil)
                    } else {
                        for window in NSApplication.shared.windows {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                } else {
                    for window in NSApplication.shared.windows {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
          }
          return false // Cannot run, another instance is active
        } else {
          removeLockFile(path: lockFilePath)
        }
      } else {
        removeLockFile(path: lockFilePath)
      }
    }

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
    let isProcRunning = kill(pid, 0) == 0
    return isProcRunning
  }

  private func createLockFile(path: String, pid: pid_t) -> Bool {
    let pidString = String(pid)
    guard let data = pidString.data(using: .utf8) else {
      return false
    }
    
    do {
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
      return true
    } catch {
      return false
    }
  }

  private func readPid(from path: String) -> pid_t? {
    do {
      let pidString = try String(contentsOfFile: path, encoding: .utf8)
      let trimmedPidString = pidString.trimmingCharacters(in: .whitespacesAndNewlines)
      if let pid = pid_t(trimmedPidString) {
        return pid
      } else {
        return nil
      }
    } catch {
      return nil
    }
  }

  private func removeLockFile(path: String) {
    do {
      try FileManager.default.removeItem(atPath: path)
    } catch {
    }
  }
}