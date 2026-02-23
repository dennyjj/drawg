import AppKit

protocol AnnotationToolbarDelegate: AnyObject {
    func toolbarDidSelectTool(_ toolType: AnnotationType)
    func toolbarDidChangeColor(_ color: NSColor)
    func toolbarDidChangeStrokeWidth(_ width: CGFloat)
    func toolbarDidPressSave()
    func toolbarDidPressUndo()
    func toolbarDidPressRedo()
}

class AnnotationToolbar: NSView {
    weak var delegate: AnnotationToolbarDelegate?
    private var toolButtons: [AnnotationType: NSButton] = [:]
    private var colorWell: NSColorWell!
    private var strokeSlider: NSSlider!
    private var selectedTool: AnnotationType = .pen

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupToolbar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupToolbar() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 8
        stackView.alignment = .centerY
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        // Tool buttons
        let tools: [(AnnotationType, String, String)] = [
            (.pen, "pencil", "Pen"),
            (.rectangle, "rectangle", "Rectangle"),
            (.arrow, "arrow.right", "Arrow"),
            (.text, "textformat", "Text"),
        ]

        for (type, iconName, tooltip) in tools {
            let button = NSButton(frame: .zero)
            button.bezelStyle = .toolbar
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: tooltip)
            button.toolTip = tooltip
            button.target = self
            button.action = #selector(toolButtonClicked(_:))
            button.tag = tools.firstIndex(where: { $0.0 == type })!
            toolButtons[type] = button
            stackView.addArrangedSubview(button)
        }

        // Separator
        let separator1 = NSBox()
        separator1.boxType = .separator
        separator1.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator1.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stackView.addArrangedSubview(separator1)

        // Color well
        colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 30, height: 30))
        colorWell.color = .red
        colorWell.target = self
        colorWell.action = #selector(colorChanged(_:))
        colorWell.widthAnchor.constraint(equalToConstant: 30).isActive = true
        colorWell.heightAnchor.constraint(equalToConstant: 30).isActive = true
        stackView.addArrangedSubview(colorWell)

        // Stroke width slider
        let strokeLabel = NSTextField(labelWithString: "Size:")
        strokeLabel.font = NSFont.systemFont(ofSize: 11)
        stackView.addArrangedSubview(strokeLabel)

        strokeSlider = NSSlider(value: 3.0, minValue: 1.0, maxValue: 20.0, target: self, action: #selector(strokeChanged(_:)))
        strokeSlider.widthAnchor.constraint(equalToConstant: 80).isActive = true
        stackView.addArrangedSubview(strokeSlider)

        // Separator
        let separator2 = NSBox()
        separator2.boxType = .separator
        separator2.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator2.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stackView.addArrangedSubview(separator2)

        // Undo/Redo
        let undoButton = NSButton(frame: .zero)
        undoButton.bezelStyle = .toolbar
        undoButton.image = NSImage(systemSymbolName: "arrow.uturn.backward", accessibilityDescription: "Undo")
        undoButton.toolTip = "Undo (⌘Z)"
        undoButton.target = self
        undoButton.action = #selector(undoClicked)
        stackView.addArrangedSubview(undoButton)

        let redoButton = NSButton(frame: .zero)
        redoButton.bezelStyle = .toolbar
        redoButton.image = NSImage(systemSymbolName: "arrow.uturn.forward", accessibilityDescription: "Redo")
        redoButton.toolTip = "Redo (⌘⇧Z)"
        redoButton.target = self
        redoButton.action = #selector(redoClicked)
        stackView.addArrangedSubview(redoButton)

        // Separator
        let separator3 = NSBox()
        separator3.boxType = .separator
        separator3.widthAnchor.constraint(equalToConstant: 1).isActive = true
        separator3.heightAnchor.constraint(equalToConstant: 24).isActive = true
        stackView.addArrangedSubview(separator3)

        // Save button
        let saveButton = NSButton(frame: .zero)
        saveButton.bezelStyle = .toolbar
        saveButton.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Save")
        saveButton.toolTip = "Save & Copy (⌘S)"
        saveButton.target = self
        saveButton.action = #selector(saveClicked)
        stackView.addArrangedSubview(saveButton)

        // Highlight default tool
        updateToolSelection()
    }

    @objc private func toolButtonClicked(_ sender: NSButton) {
        let types: [AnnotationType] = [.pen, .rectangle, .arrow, .text]
        guard sender.tag >= 0 && sender.tag < types.count else { return }
        selectedTool = types[sender.tag]
        updateToolSelection()
        delegate?.toolbarDidSelectTool(selectedTool)
    }

    @objc private func colorChanged(_ sender: NSColorWell) {
        delegate?.toolbarDidChangeColor(sender.color)
    }

    @objc private func strokeChanged(_ sender: NSSlider) {
        delegate?.toolbarDidChangeStrokeWidth(CGFloat(sender.doubleValue))
    }

    @objc private func undoClicked() {
        delegate?.toolbarDidPressUndo()
    }

    @objc private func redoClicked() {
        delegate?.toolbarDidPressRedo()
    }

    @objc private func saveClicked() {
        delegate?.toolbarDidPressSave()
    }

    private func updateToolSelection() {
        for (type, button) in toolButtons {
            button.state = type == selectedTool ? .on : .off
        }
    }
}
