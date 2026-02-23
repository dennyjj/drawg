import AppKit

class PermissionsManager {
    func requestScreenRecordingPermission() {
        if #available(macOS 15.0, *) {
            CGRequestScreenCaptureAccess()
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }

        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "Drawg needs screen recording permission to capture screenshots. Please grant permission in System Settings, then try capturing again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
