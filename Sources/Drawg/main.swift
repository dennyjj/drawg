import AppKit

// Single-instance check
let bundleID = "com.drawg.app"
let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
let isAlreadyRunning = runningApps.contains { $0 != NSRunningApplication.current }

if isAlreadyRunning {
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("com.drawg.activate"),
        object: nil
    )
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Prevent macOS from auto-terminating this windowless menu bar app
ProcessInfo.processInfo.disableAutomaticTermination("Drawg is a menu bar app")
ProcessInfo.processInfo.disableSuddenTermination()

let delegate = AppDelegate()
app.delegate = delegate

// withExtendedLifetime prevents ARC from releasing the delegate early
// (NSApplication.delegate is weak)
withExtendedLifetime(delegate) {
    app.run()
}
