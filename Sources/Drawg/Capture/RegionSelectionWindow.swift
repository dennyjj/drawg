import AppKit

class RegionSelectionWindow: NSPanel {
    init(screen: NSScreen,
         onRegionSelected: @escaping (NSRect, NSScreen) -> Void,
         onCancel: @escaping () -> Void) {

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.hasShadow = false
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false

        let viewFrame = NSRect(origin: .zero, size: screen.frame.size)
        let selectionView = RegionSelectionView(frame: viewFrame) { rect in
            let screenRect = NSRect(
                x: screen.frame.origin.x + rect.origin.x,
                y: screen.frame.origin.y + rect.origin.y,
                width: rect.width,
                height: rect.height
            )
            onRegionSelected(screenRect, screen)
        } onCancel: {
            onCancel()
        }

        self.contentView = selectionView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
