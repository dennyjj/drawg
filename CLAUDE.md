# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Drawg

A native macOS screenshot & annotation tool. Menu bar agent app (LSUIElement) — no Dock icon. Global hotkey triggers region selection overlay, captures via ScreenCaptureKit, opens annotation editor, saves to `~/.drawg/captures/`, copies to clipboard. Distributed via Homebrew Cask.

## Build & Run

```bash
swift build -c release    # Compile
make bundle               # Build + create .app bundle (ad-hoc codesigned)
make run                  # Build + bundle + open app
make install              # Build + bundle + copy to /Applications
make dist                 # Build + bundle + zip for distribution
make clean                # Clean build artifacts
```

**Must test as .app bundle** — `swift run` won't work properly (no bundle ID = no screen recording permission, no menu bar behavior, no hotkey).

**After finishing code changes, always run `make install` so the user can test immediately.**

## Architecture

**Tech stack:** Swift + AppKit (no SwiftUI), SPM (no Xcode project), ScreenCaptureKit, KeyboardShortcuts (sindresorhus).

**App lifecycle (`main.swift`):** Single-instance check via `NSRunningApplication` + `DistributedNotificationCenter`. Activation policy `.accessory` (menu bar only), switches to `.regular` when windows are open. `withExtendedLifetime` keeps delegate alive since `NSApplication.delegate` is weak. Auto-termination disabled to prevent macOS killing the windowless app.

**Central coordinator:** `AppDelegate` owns all managers and window controllers. Closure-based callbacks between components (no custom delegate protocols for inter-component wiring).

**Capture flow:** Hotkey/menu → `RegionSelectionWindow` (NSPanel per screen, borderless overlay) → user drags region → 50ms delay → `ScreenCaptureManager` captures → `AnnotationWindowController` opens.

**Annotation system:** `AnnotationTool` protocol with `mouseDown/mouseDragged/mouseUp/drawPreview`. Tools return an `Annotation` model on mouseUp. `AnnotationCanvasView` renders base image → committed annotations → tool preview. Undo/redo via array + stack (no NSUndoManager).

**Window pattern:** All windows use controller pattern (NSObject owning a plain NSWindow/NSPanel). Do NOT subclass NSWindow with stored `let` properties — AppKit internally calls a different init and crashes.

## Key Constraints

- **No `resources` in Package.swift** — Adding `resources: [.copy(...)]` generates a `Drawg_Drawg.bundle` that crashes at runtime. KeyboardShortcuts' resource bundles are copied by the Makefile instead.
- **Ad-hoc codesigning required** — The Makefile codesigns with `--identifier com.drawg.app` so screen recording permission persists across rebuilds/installs.
- **macOS 13+ with fallback** — ScreenCaptureKit's `SCScreenshotManager` is macOS 14+; falls back to `CGWindowListCreateImage` on macOS 13.
- **PermissionsManager.swift is unused** — Exists on disk but not referenced. Permission prompts are handled by the system automatically.

## Release Process

Push a git tag (`git tag v1.x.x && git push --tags`) → GitHub Actions builds, creates release with zip, and auto-updates the `dennyjj/homebrew-drawg` tap (requires `TAP_TOKEN` secret).

Install: `brew tap dennyjj/drawg && brew install --cask drawg`
