import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    print("[AppDelegate] applicationShouldHandleReopen called.")
    print("[AppDelegate] hasVisibleWindows: \(flag)")
    print("[AppDelegate] Number of windows in sender.windows: \(sender.windows.count)")

    if !flag {
      for (index, window) in sender.windows.enumerated() {
        print("[AppDelegate] Processing window \(index): \(window.title) (isVisible: \(window.isVisible))")
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
