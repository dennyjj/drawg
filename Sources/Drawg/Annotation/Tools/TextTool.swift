import AppKit

class TextTool: AnnotationTool {
    var color: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    var fontSize: CGFloat = 16.0

    weak var canvasView: AnnotationCanvasView?
    private var activeTextField: NSTextField?
    private var textOrigin: NSPoint?

    func mouseDown(at point: NSPoint) {
        commitActiveTextField()
        textOrigin = point
        createTextField(at: point)
    }

    func mouseDragged(to point: NSPoint) {
        // No drag behavior for text tool
    }

    func mouseUp(at point: NSPoint) -> Annotation? {
        // Text is committed when the user presses Enter or clicks elsewhere
        return nil
    }

    func drawPreview(in context: NSGraphicsContext) {
        // Nothing to preview - text uses live NSTextField
    }

    private func createTextField(at point: NSPoint) {
        guard let canvas = canvasView else { return }

        let textField = NSTextField(frame: NSRect(x: point.x, y: point.y - 10, width: 200, height: 24))
        textField.isEditable = true
        textField.isBordered = false
        textField.backgroundColor = NSColor.white.withAlphaComponent(0.8)
        textField.font = NSFont.systemFont(ofSize: fontSize, weight: .medium)
        textField.textColor = color
        textField.focusRingType = .none
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.target = self
        textField.action = #selector(textFieldAction(_:))

        canvas.addSubview(textField)
        textField.becomeFirstResponder()
        activeTextField = textField
    }

    @objc private func textFieldAction(_ sender: NSTextField) {
        commitActiveTextField()
    }

    func commitActiveTextField() {
        guard let textField = activeTextField,
              let text = textField.stringValue.isEmpty ? nil : textField.stringValue,
              let origin = textOrigin else {
            activeTextField?.removeFromSuperview()
            activeTextField = nil
            textOrigin = nil
            return
        }

        let annotation = Annotation(type: .text, color: color, strokeWidth: strokeWidth, fontSize: fontSize)
        annotation.text = text
        annotation.textRect = NSRect(
            x: origin.x,
            y: origin.y - 10,
            width: textField.frame.width,
            height: textField.frame.height
        )

        canvasView?.commitAnnotation(annotation)

        textField.removeFromSuperview()
        activeTextField = nil
        textOrigin = nil
    }
}
