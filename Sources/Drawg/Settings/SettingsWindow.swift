import AppKit

class SettingsWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose

        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 250

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let contentRect = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )

        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "Drawg - Settings"
        window.delegate = self

        let viewController = SettingsViewController()
        window.contentViewController = viewController
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
