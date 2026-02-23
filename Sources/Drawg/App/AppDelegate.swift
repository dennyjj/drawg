import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyManager: HotkeyManager!
    private var screenCaptureManager: ScreenCaptureManager!
    private var storageManager: StorageManager!
    private var annotationController: AnnotationWindowController?
    private var libraryController: LibraryWindowController?
    private var settingsController: SettingsWindowController?
    private var regionSelectionWindows: [RegionSelectionWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        storageManager = StorageManager()
        screenCaptureManager = ScreenCaptureManager()

        statusBarController = StatusBarController(
            onCapture: { [weak self] in self?.startCapture() },
            onLibrary: { [weak self] in self?.showLibrary() },
            onSettings: { [weak self] in self?.showSettings() },
            onQuit: { NSApp.terminate(nil) }
        )

        hotkeyManager = HotkeyManager { [weak self] in
            self?.startCapture()
        }

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleActivation),
            name: NSNotification.Name("com.drawg.activate"),
            object: nil
        )
    }

    @objc private func handleActivation(_ notification: Notification) {
        startCapture()
    }

    func startCapture() {
        regionSelectionWindows.forEach { $0.close() }
        regionSelectionWindows.removeAll()

        // Activate app so overlay windows can become key and receive events
        NSApp.activate(ignoringOtherApps: true)

        for screen in NSScreen.screens {
            let window = RegionSelectionWindow(screen: screen) { [weak self] rect, screen in
                self?.handleRegionSelected(rect: rect, screen: screen)
            } onCancel: { [weak self] in
                self?.dismissRegionSelection()
            }
            regionSelectionWindows.append(window)
            window.orderFrontRegardless()
        }

        // Make the first window key for keyboard events (Escape to cancel)
        regionSelectionWindows.first?.makeKey()
    }

    private func handleRegionSelected(rect: NSRect, screen: NSScreen) {
        dismissRegionSelection()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self = self else { return }
            self.screenCaptureManager.captureRegion(rect: rect, screen: screen) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let image = image {
                        self.showAnnotationEditor(with: image)
                    }
                    // If nil, the system permission dialog was shown — user can try again after granting
                }
            }
        }
    }

    private func dismissRegionSelection() {
        regionSelectionWindows.forEach { $0.orderOut(nil) }
        regionSelectionWindows.removeAll()
    }

    private func showAnnotationEditor(with image: CGImage) {
        setActivationPolicy(.regular)
        annotationController = AnnotationWindowController(image: image, storageManager: storageManager) { [weak self] in
            DispatchQueue.main.async {
                self?.annotationController = nil
                self?.restoreActivationPolicyIfNeeded()
            }
        }
        annotationController?.window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showLibrary() {
        setActivationPolicy(.regular)
        if let existing = libraryController {
            existing.window.makeKeyAndOrderFront(nil)
        } else {
            libraryController = LibraryWindowController(storageManager: storageManager) { [weak self] in
                DispatchQueue.main.async {
                    self?.libraryController = nil
                    self?.restoreActivationPolicyIfNeeded()
                }
            }
            libraryController?.window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettings() {
        setActivationPolicy(.regular)
        if let existing = settingsController {
            existing.window.makeKeyAndOrderFront(nil)
        } else {
            settingsController = SettingsWindowController { [weak self] in
                DispatchQueue.main.async {
                    self?.settingsController = nil
                    self?.restoreActivationPolicyIfNeeded()
                }
            }
            settingsController?.window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setActivationPolicy(_ policy: NSApplication.ActivationPolicy) {
        NSApp.setActivationPolicy(policy)
    }

    private func restoreActivationPolicyIfNeeded() {
        if annotationController == nil && libraryController == nil && settingsController == nil {
            setActivationPolicy(.accessory)
        }
    }
}
