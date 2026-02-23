import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let captureScreenshot = Self("captureScreenshot", default: .init(.d, modifiers: [.command, .shift]))
}

class HotkeyManager {
    private let onCapture: () -> Void

    init(onCapture: @escaping () -> Void) {
        self.onCapture = onCapture

        KeyboardShortcuts.onKeyUp(for: .captureScreenshot) { [weak self] in
            self?.onCapture()
        }
    }
}
