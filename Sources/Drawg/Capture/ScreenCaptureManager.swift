import AppKit
import ScreenCaptureKit

class ScreenCaptureManager {
    func captureRegion(rect: NSRect, screen: NSScreen, completion: @escaping (CGImage?) -> Void) {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
            guard let content = content else {
                completion(nil)
                return
            }

            // Find the matching SCDisplay for this screen
            guard let display = content.displays.first(where: { display in
                display.displayID == screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            }) else {
                completion(nil)
                return
            }

            // Exclude Drawg's own windows
            let drawgWindows = content.windows.filter { $0.owningApplication?.bundleIdentifier == "com.drawg.app" }

            let filter = SCContentFilter(display: display, excludingWindows: drawgWindows)

            let config = SCStreamConfiguration()

            // Convert from NSScreen coordinates to display-native pixel coordinates
            let backingScaleFactor = screen.backingScaleFactor

            // NSScreen coordinate system has origin at bottom-left of the primary screen
            // CGImage coordinate system has origin at top-left
            // Convert the rect to be relative to the screen
            let screenRelativeRect = NSRect(
                x: rect.origin.x - screen.frame.origin.x,
                y: rect.origin.y - screen.frame.origin.y,
                width: rect.width,
                height: rect.height
            )

            // Flip Y axis for CGImage coordinates (origin at top-left)
            let flippedY = screen.frame.height - screenRelativeRect.origin.y - screenRelativeRect.height

            config.sourceRect = CGRect(
                x: screenRelativeRect.origin.x,
                y: flippedY,
                width: screenRelativeRect.width,
                height: screenRelativeRect.height
            )
            config.width = Int(screenRelativeRect.width * backingScaleFactor)
            config.height = Int(screenRelativeRect.height * backingScaleFactor)
            config.showsCursor = false
            config.capturesAudio = false

            if #available(macOS 14.0, *) {
                SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                    completion(image)
                }
            } else {
                // Fallback for macOS 13: use CGWindowListCreateImage
                let cgRect = CGRect(
                    x: rect.origin.x,
                    y: NSScreen.screens[0].frame.height - rect.origin.y - rect.height,
                    width: rect.width,
                    height: rect.height
                )
                let image = CGWindowListCreateImage(
                    cgRect,
                    .optionOnScreenBelowWindow,
                    kCGNullWindowID,
                    [.boundsIgnoreFraming]
                )
                completion(image)
            }
        }
    }
}
