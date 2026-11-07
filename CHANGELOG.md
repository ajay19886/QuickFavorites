# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/), and the project uses [Semantic Versioning](https://semver.org/).

## [1.1.1] - 2026-11-07

### Fixed
- On Windows 11 with Windows Terminal as the default terminal, starting with Windows left a visible PowerShell tab and taskbar icon, and closing it closed the bar. The bar is now started through a headless console host (`conhost.exe --headless`): no window, no tab, no taskbar icon. Older Windows keeps using a hidden window.
- Existing "Start with Windows" entries created by v1.1.0 are upgraded automatically the next time the bar starts from the same location.
- Sub-menu arrows are now white, so they are visible on the dark menu.

### Changed
- The installer, the right-click "Start with Windows" option and the self-relaunch all use the same start-up command.
- The uninstaller also stops the headless console host that wraps the bar.
- README wording clarified: nothing needs installing to run it, an optional installer is included; monitor and DPI handling described as best-effort.
- Release ZIP now includes the README images and LICENSE.

## [1.1.0] - 2026-11-07

### Added
- Double-click or right-click a folder in the menu to open it in Explorer, instead of drilling down into it.
- `Start-QuickFavorites.bat`: double-click launcher that works from any folder (no typing a command to restart after Exit).
- `Install.bat` / `Install-QuickFavorites.ps1`: one-click per-user installer and updater (no admin rights). Optional sample menu, desktop shortcut and Start with Windows; never overwrites your favorites or settings.
- `Uninstall.bat`: removes the startup entry and desktop shortcut; deletes your data only on explicit confirmation. Folder deletion uses `rd /s /q`, so links inside your favorites are removed as links and their targets are never touched.
- Dark menu: check marks (Lock position, Start with Windows) are now drawn as a clear white tick.
- `sample-menu/`: sample folders, documents and web links used by the installer (Notepad, Calculator and similar shortcuts are generated at install time so the paths are always correct).

## [1.0.1] - 2026-11-06

### Fixed
- Closing the PowerShell window the script was started from no longer closes the bar. The script now relaunches itself in a separate hidden process.

### Added
- `-Detached` switch to run in the current console (useful for debugging; warnings stay visible).

## [1.0.0] - 2026-11-06

First public release.

### Added
- Floating, always-on-top **Desktop »** button that opens a cascading menu built from `%USERPROFILE%\QuickFavorites\Menu`.
- Windows Shell icons for folders, shortcuts and files, cached for speed.
- Lazy-loaded sub-folders, so large or looping folder trees stay responsive.
- Drag to move (with a drag threshold), **Lock position** and **Reset position**; settings stored in `settings.json`.
- Right-click options menu: Open favorites folder, Lock position, Reset position, Start with Windows, Exit.
- Optional **Start with Windows** using the current-user registry Run key, with detection of an existing Startup-folder shortcut to avoid launching twice.
- Single-instance protection.
- DPI awareness and multi-monitor position validation, re-checked periodically.
- Hides during full-screen apps and presentations; restores the always-on-top flag if another program clears it.
- Dark menu theme.
- A greyed "(can't open this folder)" item when a folder is inaccessible.

### Fixed (compared with the original prototype)
- `»` rendering as `Â»` caused by file encoding.
- Names containing `&` losing the character in menus.
- Hidden and system files such as `desktop.ini` appearing in the menu.
- Folder names containing dots being truncated.
- Menu items and icons leaking handles on rebuild.

### Known limitations
See the README section "Known limitations".
