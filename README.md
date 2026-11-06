<p align="center">
  <img src="docs/banner.png" alt="QuickFavorites - your favorite shortcuts, one click away (illustration)" width="100%">
</p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-green.svg">
  <img alt="Windows 10 | 11" src="https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4">
  <img alt="PowerShell 5.1" src="https://img.shields.io/badge/PowerShell-5.1-5391FE">
  <img alt="No admin rights" src="https://img.shields.io/badge/admin%20rights-not%20required-brightgreen">
</p>

# QuickFavorites

**Bring your favorite shortcuts back to Windows 11 - one click, no admin rights, no installer.**

Windows 11 removed the classic taskbar toolbars. QuickFavorites puts a small, draggable **Desktop »** button on your screen. Click it and a cascading menu of your favorite folders, files, apps and shortcuts opens - built from one ordinary folder you control.

It is a single, readable PowerShell script. Download it, run it, done.

## Why you might like it

- **No administrator rights.** Runs in your normal user session. It never asks for UAC elevation.
- **No installer, no background service.** One `.ps1` file. Exit it from its right-click menu and it is gone.
- **Floating and draggable.** Put it wherever you like, lock it in place, and it remembers the position.
- **Your folder is the menu.** Drop a shortcut in, and it appears. Sub-folders become cascading menus, with real Windows icons.
- **Readable and auditable.** No compiled binary - you can read every line before you run it.
- **Considerate.** Hides itself during full-screen apps and presentations, stays on-screen after monitor or scaling changes, and never starts twice.

## Screenshots

> The images below are **illustrations** of the interface. Real screenshots are welcome - see [Contributing](#contributing).

<p align="center">
  <img src="docs/screenshots/menu.png" alt="Cascading favorites menu opening above the floating Desktop button (illustration)" width="85%">
</p>

<p align="center">
  <img src="docs/screenshots/options.png" alt="Right-click options: open folder, lock position, reset position, start with Windows, exit (illustration)" width="60%">
</p>

## Quick start

1. Download [`FavoritesMenu.ps1`](FavoritesMenu.ps1) and save it to `%USERPROFILE%\QuickFavorites\`.
2. Right-click the file, choose **Properties**, and tick **Unblock** if you see it. Click OK.
3. Press **Win + R**, paste this, and press Enter (or run it from Command Prompt):

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%USERPROFILE%\QuickFavorites\FavoritesMenu.ps1"
   ```

4. Right-click the **Desktop »** button, choose **Open favorites folder**, and drop in your shortcuts.
5. Optional: right-click the button and tick **Start with Windows**.

The script starts itself in a separate hidden process, so you can close the window you launched it from and the bar keeps running. To run it in the current console instead (to see warnings while troubleshooting), add `-Detached` to the command.

`-ExecutionPolicy Bypass` applies to that one PowerShell process only. It does not change your machine's policy and does not grant admin rights.

> **Managed work PC?** Group Policy, AppLocker or similar rules may still block scripts, even without admin rights. Follow your organization's IT policy.

## Features

| Feature | Details |
| --- | --- |
| Folder-driven menu | Shortcuts, files, apps and folders from `%USERPROFILE%\QuickFavorites\Menu` |
| Windows icons | The same icons Explorer shows, cached for speed |
| Lazy sub-menus | Sub-folders load when opened, so big or looping folder trees stay fast |
| Draggable and lockable | Drag threshold prevents accidental moves; position saved per user |
| Multi-monitor and DPI aware | Stays on a visible screen after docking, undocking or scaling changes |
| Right-click options | Open folder, Lock position, Reset position, Start with Windows, Exit |
| Full-screen friendly | Hides during full-screen apps and presentations (best-effort detection) |
| Single instance | Starting it twice does not stack two bars |
| Dark theme | Dropdowns match the bar |
| Visible errors | A folder that cannot be opened shows a greyed "(can't open this folder)" item |
| Startup check | Detects an existing Startup-folder shortcut so it never launches twice |

## How it compares

Several free projects solve the same Windows 11 gap in different ways. Pick whichever fits your workflow.

| Project | Approach |
| --- | --- |
| **QuickFavorites** (this project) | A floating, always-on-top button on the desktop; one readable PowerShell script |
| [TrayToolbar](https://github.com/brondavies/TrayToolbar) | Tray-icon menu built from a folder of shortcuts |
| [TaskFolder](https://github.com/rod-trent/TaskFolder) | System-tray launcher menu |
| [WinPinMenu](https://github.com/hatelamers/winpinmenu) | Pins a folder as a popup menu from the taskbar |
| [ExplorerPatcher](https://github.com/valinet/ExplorerPatcher) | Restores the Windows 10 taskbar, including its toolbars |

QuickFavorites' angle: you can *see* it on your desktop, move it where you want, and read the whole source in one file. Check each project's own page for its requirements.

## Using it

- **Left-click** the button to open your favorites.
- **Drag** the button to move it. Use **Lock position** to stop accidental moves.
- **Right-click** the button for options.
- Organize favorites with sub-folders. Folders sort first, with natural number order (2 before 10).
- Hidden and system files such as `desktop.ini` are not shown.

## Where things are stored

| What | Location |
| --- | --- |
| Your shortcuts | `%USERPROFILE%\QuickFavorites\Menu` |
| Settings (position, lock) | `%USERPROFILE%\QuickFavorites\settings.json` |
| Optional autostart | `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, value `QuickFavoritesBar` |

The script makes **no network connections**. Please do not commit your own shortcuts or `settings.json` to this repository.

## Uninstall

1. Right-click the button, untick **Start with Windows** if it is ticked, then choose **Exit**.
2. Delete the script and, if you wish, the `%USERPROFILE%\QuickFavorites` folder.

## Known limitations

- **Unsigned script.** Windows SmartScreen or antivirus tools may warn about it. Read the code, and use the Unblock step above.
- **Compiled helper code.** At start-up the script compiles a small piece of C# in memory (`Add-Type`) for icons, DPI and window handling. Some security products flag this on any script.
- **Full-screen detection is best-effort.** It uses the Windows `SHQueryUserNotificationState` API, which does not recognise every borderless full-screen window.
- **DPI:** system-level awareness only, not per-monitor. Moving the bar between monitors with different scaling may look slightly blurry.
- **Folder icons** are the standard Windows folder icon; custom per-folder icons are not shown.
- Built for **Windows PowerShell 5.1**. PowerShell 7 has not been tested.
- Early release: tested by the author on Windows 11. Reports from other setups are very welcome.

## Ideas (not promises)

Keyboard shortcut to open the menu, configurable favorites folder and bar size, per-monitor DPI, shortcut search. Open an issue if one of these matters to you.

## Contributing

Bug reports, ideas and pull requests are welcome. When reporting a display problem, please include your Windows version, scaling and monitor setup.

**Real screenshots wanted:** if you run it, a screenshot (using demo shortcuts, no private folder names) is a great contribution.

## Credits

Created by [@ajay19886](https://github.com/ajay19886), developed with the assistance of Claude (Anthropic).

## License

[MIT](LICENSE) - free to use, change and share.
