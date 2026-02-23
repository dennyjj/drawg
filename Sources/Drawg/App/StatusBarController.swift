import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private let onCapture: () -> Void
    private let onLibrary: () -> Void
    private let onSettings: () -> Void
    private let onQuit: () -> Void

    init(onCapture: @escaping () -> Void,
         onLibrary: @escaping () -> Void,
         onSettings: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.onCapture = onCapture
        self.onLibrary = onLibrary
        self.onSettings = onSettings
        self.onQuit = onQuit

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.and.scribble", accessibilityDescription: "Drawg")
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let captureItem = NSMenuItem(title: "Capture Screenshot", action: #selector(captureClicked), keyEquivalent: "")
        captureItem.target = self
        menu.addItem(captureItem)

        menu.addItem(NSMenuItem.separator())

        let libraryItem = NSMenuItem(title: "Library...", action: #selector(libraryClicked), keyEquivalent: "")
        libraryItem.target = self
        menu.addItem(libraryItem)

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(settingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Drawg", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func captureClicked() {
        onCapture()
    }

    @objc private func libraryClicked() {
        onLibrary()
    }

    @objc private func settingsClicked() {
        onSettings()
    }

    @objc private func quitClicked() {
        onQuit()
    }
}
