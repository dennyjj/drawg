import AppKit
import KeyboardShortcuts

class SettingsViewController: NSViewController {
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 250))

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])

        // Hotkey setting
        let hotkeyRow = makeRow(label: "Capture Hotkey:")
        let recorder = KeyboardShortcuts.RecorderCocoa(for: .captureScreenshot)
        hotkeyRow.addArrangedSubview(recorder)
        stackView.addArrangedSubview(hotkeyRow)

        // Image format
        let formatRow = makeRow(label: "Image Format:")
        let formatPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        formatPopup.addItems(withTitles: ["PNG", "JPEG"])
        let savedFormat = UserDefaults.standard.string(forKey: "imageFormat") ?? "png"
        formatPopup.selectItem(withTitle: savedFormat.uppercased())
        formatPopup.target = self
        formatPopup.action = #selector(formatChanged(_:))
        formatRow.addArrangedSubview(formatPopup)
        stackView.addArrangedSubview(formatRow)

        // Launch at login hint
        let loginLabel = NSTextField(wrappingLabelWithString: "To launch Drawg at login, add it to System Settings > General > Login Items.")
        loginLabel.font = NSFont.systemFont(ofSize: 11)
        loginLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(loginLabel)

        // Version info
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let versionLabel = NSTextField(labelWithString: "Drawg v\(version)")
        versionLabel.font = NSFont.systemFont(ofSize: 11)
        versionLabel.textColor = .tertiaryLabelColor
        stackView.addArrangedSubview(versionLabel)
    }

    private func makeRow(label: String) -> NSStackView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .centerY

        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.widthAnchor.constraint(equalToConstant: 120).isActive = true
        row.addArrangedSubview(labelField)

        return row
    }

    @objc private func formatChanged(_ sender: NSPopUpButton) {
        let format = sender.titleOfSelectedItem?.lowercased() ?? "png"
        UserDefaults.standard.set(format, forKey: "imageFormat")
    }
}
