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

    case "debugIsRunning":
      guard let args = call.arguments as? [String: Any],
            let pid = args["pid"] as? pid_t else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "PID is required", details: nil))
        return
      }
      let running = isRunning(pid: pid)
      result(running)

    case "activateCurrentApp":
      print("[FlutterAlone] activateCurrentApp called. Attempting to activate current app.")
      NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])

      // 추가: 현재 앱의 모든 창을 순회하며 makeKeyAndOrderFront 호출
      DispatchQueue.main.async {
          if let appDelegate = NSApplication.shared.delegate as? FlutterAppDelegate {
              // mainFlutterWindow는 FlutterAppDelegate에 정의된 메인 창입니다.
              // windowScene?.windows는 macOS 10.15+에서 Scene 기반 앱의 창을 가져오는 방식입니다.
              // 대부분의 Flutter 앱은 하나의 메인 창을 가집니다.
              if let window = appDelegate.mainFlutterWindow {
                  print("[FlutterAlone] Found mainFlutterWindow. Making key and ordering front.")
                  window.makeKeyAndOrderFront(nil)
              } else {
                  print("[FlutterAlone] mainFlutterWindow not found. Checking all windows.")
                  // Fallback: 모든 NSWindow를 순회하여 활성화 시도
                  for window in NSApplication.shared.windows {
                      print("[FlutterAlone] Processing NSApplication window: \(window.title) (isVisible: \(window.isVisible))")
                      window.makeKeyAndOrderFront(nil)
                  }
              }
          } else {
              print("[FlutterAlone] AppDelegate is not FlutterAppDelegate or not found. Cannot directly access mainFlutterWindow.")
              // Fallback: 모든 NSWindow를 순회하여 활성화 시도
              for window in NSApplication.shared.windows {
                  print("[FlutterAlone] Processing NSApplication window: \(window.title) (isVisible: \(window.isVisible))")
                  window.makeKeyAndOrderFront(nil)
              }
          }
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Core Logic

  private func checkAndRun(lockFilePath: String, windowTitle: String?) -> Bool {
    print("[FlutterAlone] checkAndRun called with lockFilePath: \(lockFilePath)")
    let fileManager = FileManager.default
    let currentPid = ProcessInfo.processInfo.processIdentifier

    if fileManager.fileExists(atPath: lockFilePath) {
      print("[FlutterAlone] Lock file exists at: \(lockFilePath)")
      // Lock file exists, check if the process is still running
      if let existingPid = readPid(from: lockFilePath) {
        print("[FlutterAlone] PID read from lock file: \(existingPid)")
        if isRunning(pid: existingPid) {
          print("[FlutterAlone] Existing process is running. Activating app.")
          // Another instance is running, activate its window
          if let app = NSRunningApplication(processIdentifier: existingPid) {
            app.activate(options: [.activateIgnoringOtherApps])
            print("[FlutterAlone] Activated existing app with PID: \(existingPid)")

            // 추가: 기존 앱의 창을 활성화하는 로직
            DispatchQueue.main.async {
                if let appDelegate = NSApplication.shared.delegate as? FlutterAppDelegate {
                    if let window = appDelegate.mainFlutterWindow {
                        print("[FlutterAlone] Found mainFlutterWindow for existing app. Making key and ordering front.")
                        window.makeKeyAndOrderFront(nil)
                    } else {
                        print("[FlutterAlone] mainFlutterWindow not found for existing app. Checking all windows.")
                        for window in NSApplication.shared.windows {
                            print("[FlutterAlone] Processing NSApplication window for existing app: \(window.title ?? "No Title") (isVisible: \(window.isVisible))")
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                } else {
                    print("[FlutterAlone] AppDelegate is not FlutterAppDelegate or not found for existing app. Cannot directly access mainFlutterWindow.")
                    for window in NSApplication.shared.windows {
                        print("[FlutterAlone] Processing NSApplication window for existing app: \(window.title ?? "No Title") (isVisible: \(window.isVisible))")
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
          } else {
            print("[FlutterAlone] Could not find NSRunningApplication for PID: \(existingPid)")
          }
          return false // Cannot run, another instance is active
        } else {
          print("[FlutterAlone] Stale lock file detected. Process \(existingPid) is not running. Removing lock file.")
          // Stale lock file, process is dead. Clean up and proceed.
          removeLockFile(path: lockFilePath)
        }
      } else {
        print("[FlutterAlone] Lock file exists but PID cannot be read. Treating as stale. Removing lock file.")
        // Lock file exists but PID cannot be read. Treat as stale.
        removeLockFile(path: lockFilePath)
      }
    }

    print("[FlutterAlone] No active lock file found. Creating new one.")
    // No lock file, or stale lock file cleaned up. Create a new one.
    return createLockFile(path: lockFilePath, pid: currentPid)
  }

  private func dispose() {
    print("[FlutterAlone] dispose called.")
    if let path = currentLockFilePath {
      print("[FlutterAlone] Removing lock file on dispose: \(path)")
      removeLockFile(path: path)
      currentLockFilePath = nil
    }
  }

  // MARK: - Helper Functions

  private func isRunning(pid: pid_t) -> Bool {
    let isProcRunning = kill(pid, 0) == 0
    print("[FlutterAlone] Checking if PID \(pid) is running: \(isProcRunning)")
    return isProcRunning
  }

  private func createLockFile(path: String, pid: pid_t) -> Bool {
    let pidString = String(pid)
    guard let data = pidString.data(using: .utf8) else {
      print("[FlutterAlone] Failed to convert PID to data.")
      return false
    }
    
    do {
      print("[FlutterAlone] Attempting to create lock file at: \(path) with PID: \(pid)")
      // Write atomically to ensure integrity
      try data.write(to: URL(fileURLWithPath: path), options: .atomic)
      print("[FlutterAlone] Lock file created successfully.")
      return true
    } catch {
      print("[FlutterAlone] Error creating lock file at \(path): \(error)")
      return false
    }
  }

  private func readPid(from path: String) -> pid_t? {
    do {
      let pidString = try String(contentsOfFile: path, encoding: .utf8)
      let trimmedPidString = pidString.trimmingCharacters(in: .whitespacesAndNewlines)
      print("[FlutterAlone] Read PID string: \"\(trimmedPidString)\" from \(path)")
      if let pid = pid_t(trimmedPidString) {
        print("[FlutterAlone] Parsed PID: \(pid)")
        return pid
      } else {
        print("[FlutterAlone] Failed to parse PID from string: \"\(trimmedPidString)\"")
        return nil
      }
    } catch {
      print("[FlutterAlone] Error reading PID from lock file at \(path): \(error)")
      return nil
    }
  }

  private func removeLockFile(path: String) {
    print("[FlutterAlone] Attempting to remove lock file at: \(path)")
    do {
      try FileManager.default.removeItem(atPath: path)
      print("[FlutterAlone] Lock file removed successfully.")
    } catch {
      print("[FlutterAlone] Error removing lock file at \(path): \(error)")
    }
  }
}