import AppKit

protocol AnnotationTool: AnyObject {
    var color: NSColor { get set }
    var strokeWidth: CGFloat { get set }

    func mouseDown(at point: NSPoint)
    func mouseDragged(to point: NSPoint)
    func mouseUp(at point: NSPoint) -> Annotation?
    func drawPreview(in context: NSGraphicsContext)
}
