import AppKit

class AnnotationCanvasView: NSView {
    private let baseImage: CGImage
    private var annotations: [Annotation] = []
    private var undoStack: [CanvasAction] = []
    private var redoStack: [CanvasAction] = []
    private var currentTool: AnnotationTool?

    // Pending erasure accumulated during a single eraser drag
    private var pendingErasure: [(index: Int, annotation: Annotation)] = []

    var onAnnotationsChanged: (() -> Void)?
    var onSaveRequested: (() -> Void)?

    private enum CanvasAction {
        case add(Annotation)
        case erase([(index: Int, annotation: Annotation)])
    }

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
        if let eraserTool = tool as? EraserTool {
            eraserTool.canvasView = self
        }
    }

    func commitAnnotation(_ annotation: Annotation) {
        annotations.append(annotation)
        undoStack.append(.add(annotation))
        redoStack.removeAll()
        needsDisplay = true
        onAnnotationsChanged?()
    }

    // MARK: - Eraser support

    func beginErasure() {
        pendingErasure.removeAll()
    }

    func eraseAnnotations(near point: NSPoint, radius: CGFloat) {
        // Iterate in reverse so removing doesn't shift indices of earlier items
        for i in stride(from: annotations.count - 1, through: 0, by: -1) {
            let annotation = annotations[i]
            if hitTest(point: point, annotation: annotation, radius: radius) {
                pendingErasure.append((index: i, annotation: annotation))
                annotations.remove(at: i)
                needsDisplay = true
            }
        }
    }

    func commitErasure() {
        guard !pendingErasure.isEmpty else { return }
        // Reverse so indices are in ascending order for proper re-insertion on undo
        let erased = pendingErasure.reversed().map { (index: $0.index, annotation: $0.annotation) }
        undoStack.append(.erase(erased))
        redoStack.removeAll()
        pendingErasure.removeAll()
        onAnnotationsChanged?()
    }

    private func hitTest(point: NSPoint, annotation: Annotation, radius: CGFloat) -> Bool {
        switch annotation.type {
        case .pen, .rectangle:
            guard let path = annotation.path else { return false }
            let cgPath = path.cgPathRepresentation
            let strokedPath = cgPath.copy(
                strokingWithWidth: annotation.strokeWidth + radius * 2,
                lineCap: .round, lineJoin: .round, miterLimit: 10
            )
            return strokedPath.contains(point)

        case .arrow:
            guard let start = annotation.startPoint, let end = annotation.endPoint else { return false }
            let arrowPath = CGMutablePath()
            arrowPath.move(to: start)
            arrowPath.addLine(to: end)
            let strokedPath = arrowPath.copy(
                strokingWithWidth: annotation.strokeWidth + radius * 2,
                lineCap: .round, lineJoin: .round, miterLimit: 10
            )
            return strokedPath.contains(point)

        case .text:
            guard let rect = annotation.textRect else { return false }
            return rect.insetBy(dx: -radius, dy: -radius).contains(point)

        case .eraser:
            return false
        }
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let action = undoStack.popLast() else { return }
        switch action {
        case .add(let annotation):
            annotations.removeAll { $0.id == annotation.id }
        case .erase(let items):
            // Re-insert in ascending index order
            for item in items {
                let idx = min(item.index, annotations.count)
                annotations.insert(item.annotation, at: idx)
            }
        }
        redoStack.append(action)
        needsDisplay = true
        onAnnotationsChanged?()
    }

    func redo() {
        guard let action = redoStack.popLast() else { return }
        switch action {
        case .add(let annotation):
            annotations.append(annotation)
        case .erase(let items):
            // Remove in descending index order
            let ids = Set(items.map { $0.annotation.id })
            annotations.removeAll { ids.contains($0.id) }
        }
        undoStack.append(action)
        needsDisplay = true
        onAnnotationsChanged?()
    }

    var canUndo: Bool { !undoStack.isEmpty }
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

// MARK: - NSBezierPath → CGPath

extension NSBezierPath {
    var cgPathRepresentation: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo: path.move(to: points[0])
            case .lineTo: path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath: path.closeSubpath()
            case .quadraticCurveTo: path.addQuadCurve(to: points[1], control: points[0])
            @unknown default: break
            }
        }
        return path
    }
}
