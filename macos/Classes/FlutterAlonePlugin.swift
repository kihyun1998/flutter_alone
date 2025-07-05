import FlutterMacOS
import Foundation

public class FlutterAlonePlugin: NSObject, FlutterPlugin {
    private var fileLockManager: FileLockManager?
    private var duplicateLaunchNotification: Notification.Name?
    private var methodChannel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_alone", binaryMessenger: registrar.messenger)
        let instance = FlutterAlonePlugin()
        // Use the same channel name as the plugin's method channel for consistency
        // This allows the plugin to send messages back to its own Dart side.
        instance.methodChannel = FlutterMethodChannel(name: "flutter_alone", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAndRun":
            handleCheckAndRun(result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleCheckAndRun(result: @escaping FlutterResult) {
        NSLog("FlutterAlonePlugin: handleCheckAndRun called")
        guard let bundleId = Bundle.main.bundleIdentifier else {
            NSLog("FlutterAlonePlugin: ERROR - Bundle identifier not found")
            result(FlutterError(code: "ERROR", message: "Bundle identifier not found", details: nil))
            return
        }

        fileLockManager = FileLockManager(bundleIdentifier: bundleId)
        duplicateLaunchNotification = Notification.Name("com.flutter_alone.\(bundleId).duplicateLaunch")

        if fileLockManager?.lock() == true {
            // This is the first instance.
            NSLog("FlutterAlonePlugin: First instance. Acquired lock.")
            fileLockManager?.writePID()
            registerForNotifications()
            result(true)
        } else {
            // Another instance is potentially running.
            NSLog("FlutterAlonePlugin: Lock failed. Checking for existing process.")
            if let pid = fileLockManager?.readPID(), ProcessUtils.isProcessRunning(pid: pid) {
                // A verified instance is running, notify it.
                NSLog("FlutterAlonePlugin: Verified existing instance (PID: \(pid)). Posting duplicate launch notification.")
                postDuplicateLaunchNotification()
                result(false)
            } else {
                // Stale lockfile found. Take ownership.
                NSLog("FlutterAlonePlugin: Stale lockfile found. Cleaning up and taking ownership.")
                fileLockManager?.unlock() // Clean up the old lock
                if fileLockManager?.lock() == true {
                    NSLog("FlutterAlonePlugin: Successfully acquired lock after cleaning stale lockfile.")
                    fileLockManager?.writePID()
                    registerForNotifications()
                    result(true)
                } else {
                    NSLog("FlutterAlonePlugin: ERROR - Failed to acquire lock after cleaning stale lockfile.")
                    result(FlutterError(code: "ERROR", message: "Failed to acquire lock after cleaning stale lockfile", details: nil))
                }
            }
        }
    }

    private func handleDispose(result: @escaping FlutterResult) {
        NSLog("FlutterAlonePlugin: handleDispose called")
        fileLockManager?.unlock()
        if let notificationName = duplicateLaunchNotification {
            DistributedNotificationCenter.default().removeObserver(self, name: notificationName, object: nil)
            NSLog("FlutterAlonePlugin: Removed observer for \(notificationName.rawValue)")
        }
        result(nil)
    }

    private func registerForNotifications() {
        if let notificationName = duplicateLaunchNotification {
            NSLog("FlutterAlonePlugin: Registering for notifications with name: \(notificationName.rawValue)")
            DistributedNotificationCenter.default().addObserver(
                self,
                selector: #selector(handleDuplicateLaunch),
                name: notificationName,
                object: nil
            )
        }
    }

    private func postDuplicateLaunchNotification() {
        if let notificationName = duplicateLaunchNotification {
            NSLog("FlutterAlonePlugin: Posting distributed notification: \(notificationName.rawValue)")
            DistributedNotificationCenter.default().post(name: notificationName, object: nil)
        }
    }

    @objc func handleDuplicateLaunch(notification: Notification) {
        NSLog("FlutterAlonePlugin: handleDuplicateLaunch received notification: \(notification.name.rawValue)")
        // Activate the application at the macOS level first
        NSApp.activate(ignoringOtherApps: true)
        // Call the Dart method to notify about duplicate launch
        methodChannel?.invokeMethod("onDuplicateLaunch", arguments: nil) { result in
            if let error = result as? FlutterError {
                NSLog("FlutterAlonePlugin: Error invoking onDuplicateLaunch on Dart side: \(error.message ?? "Unknown error")")
            } else {
                NSLog("FlutterAlonePlugin: Successfully invoked onDuplicateLaunch on Dart side.")
            }
        }
    }

    deinit {
        fileLockManager?.unlock()
        if let notificationName = duplicateLaunchNotification {
            DistributedNotificationCenter.default().removeObserver(self, name: notificationName, object: nil)
        }
    }
}
