import AppKit

class LibraryWindowController: NSObject, NSWindowDelegate {
    let window: NSWindow
    private let onClose: () -> Void

    init(storageManager: StorageManager, onClose: @escaping () -> Void) {
        self.onClose = onClose

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowWidth: CGFloat = 720
        let windowHeight: CGFloat = 500

        let contentRect = NSRect(
            x: screenFrame.midX - windowWidth / 2,
            y: screenFrame.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )

        window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        super.init()

        window.title = "Drawg - Library"
        window.minSize = NSSize(width: 400, height: 300)
        window.isReleasedWhenClosed = false
        window.delegate = self

        let viewController = LibraryViewController(storageManager: storageManager)
        window.contentViewController = viewController
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
