# Drawg

A lightweight screenshot & annotation tool for macOS. Lives in your menu bar, captures screen regions with a global hotkey, and lets you draw on them before saving.

## Features

- **Region capture** — Select any area of any screen with a crosshair overlay
- **Annotation tools** — Pen, rectangle, arrow, and text
- **Customizable** — Color picker, stroke width, configurable global hotkey
- **Undo/redo** — Full undo history per annotation session
- **Auto-save & clipboard** — Saves to `~/.drawg/captures/` and copies to clipboard on save
- **Library** — Browse and manage previous captures
- **Menu bar app** — No Dock icon, stays out of your way

## Install

### Homebrew

```bash
brew tap dennyjj/drawg
brew install --cask drawg
```

### Build from source

Requires Swift 5.9+ and macOS 13+.

```bash
git clone https://github.com/dennyjj/drawg.git
cd drawg
make install
```

This builds the app and copies `Drawg.app` to `/Applications/`.

## Usage

1. Launch Drawg — a pencil icon appears in your menu bar
2. Press **Cmd+Ctrl+D** (default) or click **Capture** in the menu bar
3. Drag to select a region
4. Annotate with the toolbar tools
5. Press **Cmd+S** or click **Save** — image is saved and copied to clipboard

### Keyboard shortcuts

| Shortcut | Action |
|---|---|
| Cmd+Ctrl+D | Capture (global, configurable in Settings) |
| Cmd+S | Save & copy to clipboard |
| Cmd+Z | Undo |
| Cmd+Shift+Z | Redo |
| Escape | Cancel capture |

### Settings

Open **Settings** from the menu bar to:
- Change the global hotkey
- Switch between PNG and JPEG output
- View app version

## Permissions

Drawg needs **Screen Recording** permission. macOS will prompt you on first capture. Grant it in **System Settings → Privacy & Security → Screen Recording**.

## License

[MIT](LICENSE)
