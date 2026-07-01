import Cocoa
import FlutterMacOS

public class FlutterAlonePlugin: NSObject, FlutterPlugin {
  private static let channelName = "flutter_alone"
  private static let lockFilePermissions: mode_t = 0o644

  private var currentLockFilePath: String?
  private var lockFd: Int32 = -1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
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

      guard let lockFileName = args["lockFileName"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "lockFileName is required for macOS", details: nil))
        return
      }

      // Validate lockFileName: no path separators, no dot-only names, no null bytes
      // Reject Windows-style separators too, for cross-platform safety
      if lockFileName.contains("/") || lockFileName.contains("\\") ||
         lockFileName.isEmpty || lockFileName == "." || lockFileName == ".." ||
         lockFileName.contains("\0") {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "lockFileName must be a simple filename without path separators", details: nil))
        return
      }

      let tempDirectory = FileManager.default.temporaryDirectory
      let lockFilePath = tempDirectory.appendingPathComponent(lockFileName).path

      // Message config (previously ignored on macOS). Used to notify the user
      // when a duplicate is detected but the existing instance cannot be
      // activated -- parity with Windows and Linux.
      let messageType = args["type"] as? String ?? "en"
      let showMessageBox = args["showMessageBox"] as? Bool ?? true
      let customTitle = args["customTitle"] as? String ?? ""
      let customMessage = args["customMessage"] as? String ?? ""

      let canRun = self.checkAndRun(
        lockFilePath: lockFilePath,
        messageType: messageType,
        showMessageBox: showMessageBox,
        customTitle: customTitle,
        customMessage: customMessage)
      result(canRun)

    case "dispose":
      self.dispose()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Core Logic

  private func checkAndRun(
    lockFilePath: String,
    messageType: String,
    showMessageBox: Bool,
    customTitle: String,
    customMessage: String
  ) -> Bool {
    let currentPid = ProcessInfo.processInfo.processIdentifier

    let fd = open(lockFilePath, O_CREAT | O_RDWR | O_NOFOLLOW, Self.lockFilePermissions)
    if fd < 0 {
      NSLog("flutter_alone: failed to open lock file at %@: errno %d", lockFilePath, errno)
      return false
    }

    if flock(fd, LOCK_EX | LOCK_NB) != 0 {
      let flockErrno = errno
      close(fd)

      if flockErrno == EWOULDBLOCK || flockErrno == EAGAIN {
        // Another instance holds the lock. Try to activate it; if we cannot
        // (no PID, dead process, or a different bundle id), notify the user so
        // a duplicate launch is never a silent no-op (parity with Win/Linux).
        let activated =
          readPid(from: lockFilePath).map { activateExistingInstance(pid: $0) } ?? false
        if !activated && showMessageBox {
          showAlreadyRunningAlert(
            title: DuplicateMessage.title(type: messageType, custom: customTitle),
            message: DuplicateMessage.body(type: messageType, custom: customMessage))
        }
      } else {
        NSLog("flutter_alone: flock failed with errno %d", flockErrno)
      }
      return false
    }

    // We hold the lock. Write our PID.
    if !writePid(to: fd, pid: currentPid) {
      NSLog("flutter_alone: failed to write PID to lock file")
      flock(fd, LOCK_UN)
      close(fd)
      return false
    }

    // Do NOT close fd here — advisory flock is released when all fds are closed.
    // The kernel will release it automatically on process death.
    self.lockFd = fd
    self.currentLockFilePath = lockFilePath
    return true
  }

  private func writePid(to fd: Int32, pid: pid_t) -> Bool {
    if ftruncate(fd, 0) != 0 { return false }
    let pidString = String(pid)
    guard let data = pidString.data(using: .utf8) else { return false }
    let written = data.withUnsafeBytes { bytes -> Int in
      write(fd, bytes.baseAddress!, data.count)
    }
    return written == data.count
  }

  /// Returns true if an existing instance was found and activation was attempted,
  /// false if there is no matching instance to bring forward (in which case the
  /// caller shows the "already running" notification instead).
  @discardableResult
  private func activateExistingInstance(pid: pid_t) -> Bool {
    guard isRunning(pid: pid) else { return false }
    guard let app = NSRunningApplication(processIdentifier: pid) else { return false }

    // Require both bundle IDs to be present and match
    guard let currentBundleId = Bundle.main.bundleIdentifier,
          let appBundleId = app.bundleIdentifier,
          currentBundleId == appBundleId else { return false }

    // Unhide first so Cmd+H-hidden instances become visible.
    if app.isHidden {
      app.unhide()
    }
    // open() sends applicationShouldHandleReopen to the running instance, which
    // restores Dock-minimized windows; activate() alone does not.
    if let bundleURL = app.bundleURL {
      NSWorkspace.shared.open(bundleURL)
    } else {
      app.activate(options: [.activateIgnoringOtherApps])
    }
    return true
  }

  // Synchronous by design: the alert blocks before the duplicate instance exits,
  // matching MessageBoxW on Windows and gtk_dialog_run on Linux.
  private func showAlreadyRunningAlert(title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private func dispose() {
    if lockFd >= 0 {
      flock(lockFd, LOCK_UN)
      close(lockFd)
      lockFd = -1
    }
    if let path = currentLockFilePath {
      removeLockFile(path: path)
      currentLockFilePath = nil
    }
  }

  // MARK: - Helper Functions

  private func isRunning(pid: pid_t) -> Bool {
    if kill(pid, 0) == 0 {
      return true
    }
    if errno == EPERM {
      return true
    }
    return false
  }

  private func readPid(from path: String) -> pid_t? {
    do {
      let pidString = try String(contentsOfFile: path, encoding: .utf8)
      let trimmedPidString = pidString.trimmingCharacters(in: .whitespacesAndNewlines)
      return pid_t(trimmedPidString)
    } catch {
      NSLog("flutter_alone: failed to read PID from %@: %@", path, error.localizedDescription)
      return nil
    }
  }

  private func removeLockFile(path: String) {
    do {
      try FileManager.default.removeItem(atPath: path)
    } catch {
      NSLog("flutter_alone: failed to remove lock file at %@: %@", path, error.localizedDescription)
    }
  }
}
