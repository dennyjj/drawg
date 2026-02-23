import AppKit

class AnnotationCanvasView: NSView {
    private let baseImage: CGImage
    private var annotations: [Annotation] = []
    private var redoStack: [Annotation] = []
    private var currentTool: AnnotationTool?

    var onAnnotationsChanged: (() -> Void)?
    var onSaveRequested: (() -> Void)?

    init(frame: NSRect, image: CGImage) {
        self.baseImage = image
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isFlipped: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    func setTool(_ tool: AnnotationTool) {
        if let textTool = currentTool as? TextTool {
            textTool.commitActiveTextField()
        }
        currentTool = tool
        if let textTool = tool as? TextTool {
            textTool.canvasView = self
        }
    }

    func commitAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
        redoStack.removeAll()
        needsDisplay = true
        onAnnotationsChanged?()
    }

    func undo() {
        guard !annotations.isEmpty else { return }
        let annotation = annotations.removeLast()
        redoStack.append(annotation)
        needsDisplay = true
        onAnnotationsChanged?()
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        let annotation = redoStack.removeLast()
        annotations.append(annotation)
        needsDisplay = true
        onAnnotationsChanged?()
    }

    var canUndo: Bool { !annotations.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func allAnnotations() -> [Annotation] {
        return annotations
    }

    func getBaseImage() -> CGImage {
        return baseImage
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw base image
        context.draw(baseImage, in: bounds)

        // Draw committed annotations
        for annotation in annotations {
            annotation.draw()
        }

        // Draw in-progress preview
        if let tool = currentTool, let nsContext = NSGraphicsContext.current {
            tool.drawPreview(in: nsContext)
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        currentTool?.mouseDown(at: point)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        currentTool?.mouseDragged(to: point)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let annotation = currentTool?.mouseUp(at: point) {
            commitAnnotation(annotation)
        }
        needsDisplay = true
    }

    // MARK: - Keyboard shortcuts

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "z":
                if event.modifierFlags.contains(.shift) {
                    redo()
                } else {
                    undo()
                }
                return
            case "s":
                onSaveRequested?()
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }
}
