import AppKit

class AnnotationWindowController: NSObject, NSWindowDelegate, AnnotationToolbarDelegate {
    let window: NSWindow
    private let canvasView: AnnotationCanvasView
    private let annotationToolbar: AnnotationToolbar
    private let storageManager: StorageManager
    private let onClose: () -> Void

    private var penTool = PenTool()
    private var rectangleTool = RectangleTool()
    private var arrowTool = ArrowTool()
    private var textTool = TextTool()

    init(image: CGImage, storageManager: StorageManager, onClose: @escaping () -> Void) {
        self.storageManager = storageManager
        self.onClose = onClose

        // Calculate window size based on image, constrained to screen
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let toolbarHeight: CGFloat = 44
        let maxWidth = screenFrame.width * 0.9
        let maxHeight = screenFrame.height * 0.9 - toolbarHeight

        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        let scale = min(maxWidth / imageWidth, maxHeight / imageHeight, 1.0)
        let canvasWidth = imageWidth * scale
        let canvasHeight = imageHeight * scale

        let windowWidth = canvasWidth
        let windowHeight = canvasHeight + toolbarHeight

        canvasView = AnnotationCanvasView(
            frame: NSRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight),
            image: image
        )

        annotationToolbar = AnnotationToolbar(
            frame: NSRect(x: 0, y: canvasHeight, width: windowWidth, height: toolbarHeight)
        )

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

        window.title = "Drawg - Annotate"
        window.minSize = NSSize(width: 400, height: 300)
        window.delegate = self

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))

        annotationToolbar.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(annotationToolbar)
        containerView.addSubview(canvasView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = containerView

        NSLayoutConstraint.activate([
            annotationToolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
            annotationToolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            annotationToolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            annotationToolbar.heightAnchor.constraint(equalToConstant: toolbarHeight),

            canvasView.topAnchor.constraint(equalTo: annotationToolbar.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        annotationToolbar.delegate = self

        canvasView.setTool(penTool)
        canvasView.onSaveRequested = { [weak self] in self?.saveAndCopy() }
        updateToolColors(.red)
        updateToolStrokeWidth(3.0)
    }

    func saveAndCopy() {
        let annotations = canvasView.allAnnotations()
        let baseImage = canvasView.getBaseImage()

        let finalImage: CGImage
        if annotations.isEmpty {
            finalImage = baseImage
        } else {
            guard let flattened = ImageExporter.flattenAnnotations(
                baseImage: baseImage,
                annotations: annotations,
                canvasSize: canvasView.bounds.size
            ) else { return }
            finalImage = flattened
        }

        let format = UserDefaults.standard.string(forKey: "imageFormat") == "jpeg" ? ImageFormat.jpeg : ImageFormat.png

        if storageManager.saveImage(finalImage, format: format) != nil {
            ImageExporter.copyToClipboard(finalImage)

            window.title = "Drawg - Saved!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.window.title = "Drawg - Annotate"
            }
        }
    }

    private func updateToolColors(_ color: NSColor) {
        penTool.color = color
        rectangleTool.color = color
        arrowTool.color = color
        textTool.color = color
    }

    private func updateToolStrokeWidth(_ width: CGFloat) {
        penTool.strokeWidth = width
        rectangleTool.strokeWidth = width
        arrowTool.strokeWidth = width
        textTool.strokeWidth = width
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        onClose()
    }

    // MARK: - AnnotationToolbarDelegate

    func toolbarDidSelectTool(_ toolType: AnnotationType) {
        switch toolType {
        case .pen:
            canvasView.setTool(penTool)
        case .rectangle:
            canvasView.setTool(rectangleTool)
        case .arrow:
            canvasView.setTool(arrowTool)
        case .text:
            canvasView.setTool(textTool)
        }
    }

    func toolbarDidChangeColor(_ color: NSColor) {
        updateToolColors(color)
    }

    func toolbarDidChangeStrokeWidth(_ width: CGFloat) {
        updateToolStrokeWidth(width)
    }

    func toolbarDidPressSave() {
        saveAndCopy()
    }

    func toolbarDidPressUndo() {
        canvasView.undo()
    }

    func toolbarDidPressRedo() {
        canvasView.redo()
    }
}
