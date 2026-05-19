# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CaptureManager is a macOS menu bar app (LSUIElement) that monitors a directory for new screenshots, classifies them via Apple Vision OCR + keyword heuristics, and automatically moves them into category subdirectories.

## Build & Run

Open and build in Xcode:
```
open CaptureManager.xcodeproj
```

Command-line build:
```
xcodebuild -project CaptureManager.xcodeproj -scheme CaptureManager -configuration Debug build
```

There are no automated tests in this project. All testing is manual via the running app.

## Architecture

The app has three UI surfaces registered in `CaptureManagerApp.swift`:
- **MenuBarExtra** — `MenuBarContentView` / `MenuBarViewModel`: real-time capture feed, monitoring toggle
- **Window("category-browser")** — `CategoryBrowserView` / `CategoryBrowserViewModel`: browse captures by category
- **Settings** — `SettingsView` / `SettingsViewModel`: directories, thresholds, launch-at-login, category management

All three scenes share a single `ModelContainer` holding three SwiftData models: `Category`, `CaptureItem`, `AppSettings`.

### Screenshot Processing Pipeline

1. `ScreenshotMonitor` — watches a directory using `DispatchSourceFileSystemObject` with a 0.5 s debounce; detects new files matching patterns in `AppConstants.screenshotPatterns` (English/Korean/CleanShot X filename conventions).
2. `AIClassifier` — orchestrates classification stages. Currently only Stage 1 is implemented; a GPT-4o-mini fallback (Stage 2) is stubbed with a `// v2 TODO` comment in `AIClassifier.swift`.
3. `VisionClassifier` — runs `VNRecognizeTextRequest` (Korean + English, `.accurate` level) and scores categories by keyword overlap against `Category.keywords`. Confidence is normalized: `min(score * 1.5, 1.0)`.
4. `FileOrganizer` — creates `<outputDir>/<categoryName>/` if missing, moves or copies files, and resolves filename conflicts by appending `(n)`.

`MenuBarViewModel` owns the monitor, classifier, and organizer. It seeds `DefaultCategories.all` (9 categories: Code, Chat, Web, Design, Document, Terminal, Image, Video, Other) on first launch if no categories exist.

### Data Flow

`ScreenshotMonitor.onNewScreenshot` → `MenuBarViewModel.processScreenshot` → classify → optional move → `ModelContext.insert(CaptureItem)` → `loadRecentCaptures`.

Manual re-classification (drag or context menu) calls `FileOrganizer.reclassifyFile` and updates `CaptureItem.currentPath` + `CaptureItem.category` directly.

### Key Constants

All tuneable values live in `AppConstants` (`Utilities/Constants.swift`): screenshot regex patterns, debounce interval (0.5 s), thumbnail max dimension (200 px), default confidence threshold (0.6).

### Sandbox / Permissions

The app uses security-scoped bookmarks (`AppSettings.sourceDirectoryBookmark`, `outputDirectoryBookmark`) for sandbox-compatible persistent directory access. `ScreenshotPathResolver` reads `defaults com.apple.screencapture location` to auto-detect the user's screenshot save path.
