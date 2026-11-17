# Changelog

All notable changes are documented here. Format: Keep a Changelog; versions
follow SemVer.

## [0.1.0] — 2026-10-27 (pre-release)

### Added
- Rust engine: scanning with signature sniffing, templates, six built-in
  profiles, hash-proven duplicate detection, import planning, verified copy
  to several destinations with a durable SQLite journal, no-replace
  finalization, pause/resume/cancel, crash and unplug recovery,
  completeness check, JSON/CSV reports, library index.
- `mediaflow` CLI: plan, import, resume, cancel, sessions, report, verify,
  library, profiles, volumes.
- Desktop app (Tauri 2 + React): overview, four-step import, projects,
  library, duplicates, verification, history with journal, settings;
  light/dark themes; keyboard navigation.
- Menu-bar / tray icon, Dock and taskbar progress, native notifications,
  card detection (never auto-starts), macOS WidgetKit widget.
- Installers: macOS universal DMG (widget included), Windows setup + MSI,
  Linux AppImage / deb / rpm, CLI binaries.
- Automated tests on Linux, macOS and Windows, including a kill-and-resume
  end-to-end test.

### Changed
- Repository layout: the desktop app moved from `app/` to `apps/desktop/`
  and the macOS widget to `apps/macos-widget/`; layout and branch naming
  are described in `CONTRIBUTING.md`.
- The CLI now uses the desktop app's library (`org.mediaflow.app` in the
  platform data folder), so command-line imports appear in the app. An
  earlier CLI library is left in place and pointed out once.
- `mediaflow resume` accepts `--yes`, like `import`.
- The destination folder picker opens in the Movies/Videos folder instead
  of wherever the picker was last used (often the card itself).
- The import preview opens on the files to copy rather than on all files.
- `scripts/build-macos.sh` can notarize the DMG (`NOTARIZE=1`) and signs
  with a secure timestamp when a Developer ID is given; procedure in
  `docs/MACOS_RELEASE.md`.

### Fixed
- CLI dates (`sessions`, `verify`) are shown in local time instead of UTC.
- macOS: the startup disk is listed once, as `/`, and no longer as
  read-only.

### Known limitations
- The desktop app was used by hand on Linux only; macOS and Windows builds
  are tested in CI but not yet by hand. Builds are not signed by Apple or
  Microsoft. See docs/ROADMAP.md.
