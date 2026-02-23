import AppKit

class LibraryViewController: NSViewController {
    private let storageManager: StorageManager
    private var collectionView: NSCollectionView!
    private var captures: [CaptureFile] = []
    private let itemIdentifier = NSUserInterfaceItemIdentifier("CaptureCell")

    init(storageManager: StorageManager) {
        self.storageManager = storageManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 720, height: 500))

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 160, height: 140)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        collectionView = NSCollectionView()
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColors = [.controlBackgroundColor]
        collectionView.isSelectable = true
        collectionView.register(CaptureCell.self, forItemWithIdentifier: itemIdentifier)

        let scrollView = NSScrollView()
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Toolbar with refresh and delete
        let toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let refreshButton = NSButton(title: "Refresh", target: self, action: #selector(refresh))
        refreshButton.bezelStyle = .toolbar
        refreshButton.translatesAutoresizingMaskIntoConstraints = false

        let deleteButton = NSButton(title: "Delete", target: self, action: #selector(deleteSelected))
        deleteButton.bezelStyle = .toolbar
        deleteButton.translatesAutoresizingMaskIntoConstraints = false

        let openFolderButton = NSButton(title: "Open Folder", target: self, action: #selector(openFolder))
        openFolderButton.bezelStyle = .toolbar
        openFolderButton.translatesAutoresizingMaskIntoConstraints = false

        toolbar.addSubview(refreshButton)
        toolbar.addSubview(deleteButton)
        toolbar.addSubview(openFolderButton)

        NSLayoutConstraint.activate([
            refreshButton.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 12),
            refreshButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            deleteButton.leadingAnchor.constraint(equalTo: refreshButton.trailingAnchor, constant: 8),
            deleteButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            openFolderButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 8),
            openFolderButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
        ])

        view.addSubview(toolbar)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 40),

            scrollView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refresh()
    }

    @objc private func refresh() {
        captures = storageManager.listCaptures()
        collectionView.reloadData()
    }

    @objc private func deleteSelected() {
        let selectedIndexPaths = collectionView.selectionIndexPaths
        guard !selectedIndexPaths.isEmpty else { return }

        let alert = NSAlert()
        alert.messageText = "Delete Selected?"
        alert.informativeText = "This will permanently delete \(selectedIndexPaths.count) capture(s)."
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let indices = selectedIndexPaths.map { $0.item }.sorted(by: >)
        for index in indices {
            storageManager.deleteCapture(at: captures[index].url)
        }
        refresh()
    }

    @objc private func openFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let capturesDir = home.appendingPathComponent(".drawg/captures")
        NSWorkspace.shared.open(capturesDir)
    }
}

// MARK: - NSCollectionViewDataSource

extension LibraryViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return captures.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: itemIdentifier, for: indexPath)
        guard let cell = item as? CaptureCell else { return item }

        let capture = captures[indexPath.item]
        cell.configure(with: capture, storageManager: storageManager)
        return cell
    }
}

// MARK: - NSCollectionViewDelegate

extension LibraryViewController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didDoubleClickOn indexPath: IndexPath) {
        let capture = captures[indexPath.item]
        NSWorkspace.shared.open(capture.url)
    }
}

// MARK: - CaptureCell

class CaptureCell: NSCollectionViewItem {
    private var thumbnailView: NSImageView!
    private var nameLabel: NSTextField!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 160, height: 140))
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.cgColor

        thumbnailView = NSImageView(frame: NSRect(x: 4, y: 24, width: 152, height: 112))
        thumbnailView.imageScaling = .scaleProportionallyUpOrDown
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel = NSTextField(labelWithString: "")
        nameLabel.font = NSFont.systemFont(ofSize: 10)
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(thumbnailView)
        view.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            thumbnailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            thumbnailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            thumbnailView.bottomAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -4),

            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
            nameLabel.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    override var isSelected: Bool {
        didSet {
            view.layer?.borderColor = isSelected ? NSColor.controlAccentColor.cgColor : NSColor.separatorColor.cgColor
            view.layer?.borderWidth = isSelected ? 2 : 1
        }
    }

    func configure(with capture: CaptureFile, storageManager: StorageManager) {
        thumbnailView.image = storageManager.thumbnail(for: capture.url)
        nameLabel.stringValue = capture.url.lastPathComponent
    }
}
