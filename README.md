# QuickFavorites

A lightweight, no-install floating desktop launcher for Windows, built with Windows PowerShell and Windows Forms.

QuickFavorites displays a small **Desktop »** button on your desktop. Clicking it opens a cascading menu based on the contents of your personal `QuickFavorites\Menu` folder.

It is designed to run under your current Windows user account. It does not require an installer, administrator rights, or UAC elevation.

## Features

- Floating, always-on-top desktop launcher.
- Cascading folder menus with lazy loading of subfolders.
- Opens files, applications, and Windows shortcuts from the menu.
- Draggable launcher with saved position.
- Option to lock the launcher position and reset it.
- Optional start-with-Windows setting for the current user.
- Dark menu styling and Windows Shell icons.
- Single-instance protection.
- Hides hidden and system items from the menu.
- Displays a clear menu entry when a folder cannot be accessed.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1.
- .NET Framework components included with supported Windows installations.
- No third-party PowerShell modules are required.

PowerShell 7 compatibility has not been tested.

## Installation

1. Download `FavoritesMenu.ps1` from this repository, or download the repository ZIP using **Code → Download ZIP**.
2. Create this folder if it does not already exist:

   ```text
   %USERPROFILE%\QuickFavorites
   ```

3. Place `FavoritesMenu.ps1` in that folder.
4. Create the menu folder:

   ```text
   %USERPROFILE%\QuickFavorites\Menu
   ```

5. Add folders, files, and Windows shortcuts (`.lnk`) to the `Menu` folder.
6. Run the script using Windows PowerShell 5.1:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "$env:USERPROFILE\QuickFavorites\FavoritesMenu.ps1"
   ```

The script creates the menu folder if it does not already exist.

## Using QuickFavorites

- **Left-click** the floating Desktop button to open the favorites menu.
- **Drag** the button to reposition it.
- **Right-click** the button to access launcher options, including opening the menu folder, locking or resetting the position, configuring startup, and exiting.

The menu reflects the contents of the `Menu` folder. Organize items into subfolders to create cascading menus. Subfolders are populated when opened.

## Configuration and data

QuickFavorites stores its user data outside the source repository:

| Path | Purpose |
|---|---|
| `%USERPROFILE%\QuickFavorites\Menu` | Files, shortcuts, and folders displayed in the menu |
| `%USERPROFILE%\QuickFavorites\settings.json` | Saved launcher position and lock setting |

The application is **no-install**, but it is not a fully portable USB application: its menu and settings are stored under the current Windows user's profile, not beside the script.

Do not commit personal shortcuts, documents, or the local settings file to this repository.

## Start with Windows

QuickFavorites provides a **Start with Windows** option in the right-click menu. This configures startup for the current Windows user only; it does not require administrator rights.

If you already launch the script using a shortcut in your Windows Startup folder, the application detects that shortcut to avoid creating a second automatic launch entry.

## Security and execution notes

- **Unsigned script:** `FavoritesMenu.ps1` is not digitally signed. Windows SmartScreen, antivirus software, or organisational security policies may warn about or block an unsigned PowerShell script. Review the script before running it and follow your organisation's security requirements.
- **Downloaded-file blocking:** Windows may mark downloaded files as coming from the internet. If Windows displays a security warning, inspect the file first. The file's **Properties** dialog may offer an **Unblock** option; use it only if you trust the source and your organisation permits it.
- **In-memory C# helper compilation:** The script uses PowerShell `Add-Type` to compile small C# helper classes in memory. These helpers support native Windows functions such as shell icons, window visibility, and topmost behaviour. Some security tools may scrutinise scripts that compile code at runtime.
- **Execution policy:** The example launch command uses `-ExecutionPolicy Bypass` for that PowerShell process. It does not change the machine-wide execution policy, but organisational security controls may still prevent execution.

## Compatibility and known limitations

- **Windows only:** QuickFavorites uses Windows Forms and Windows Shell APIs. It is not intended for macOS or Linux.
- **PowerShell version:** Developed for Windows PowerShell 5.1. PowerShell 7 compatibility has not been tested.
- **Full-screen behaviour:** Hiding the launcher over full-screen applications is best-effort. Behaviour may vary with the application and its display mode; it is not guaranteed for every game or full-screen program.
- **Display scaling:** DPI awareness is system-level. Per-monitor DPI V2 awareness is not implemented.
- **Multiple monitors:** The launcher can be used on multi-monitor desktops, but monitor topology changes have not been fully validated. Disconnecting or reconnecting an external display may affect the launcher's position or visibility; manual repositioning or restarting the launcher may be necessary.
- **Display settings:** Different scaling settings, resolutions, taskbar positions, and monitor arrangements may affect placement.

## Uninstall

1. Exit QuickFavorites using its right-click menu.
2. If enabled, disable **Start with Windows** from the right-click menu.
3. Remove any separate QuickFavorites shortcut you created in the Windows Startup folder.
4. Optionally delete `%USERPROFILE%\QuickFavorites` after backing up any personal files stored in its `Menu` folder.

## Contributing

Bug reports, suggestions, and pull requests are welcome. Please include:

- Windows version and build.
- Windows PowerShell version.
- Display scaling and monitor arrangement, if relevant.
- Steps to reproduce the issue.
- Any relevant error message.

## License

QuickFavorites is released under the MIT License. See [LICENSE](LICENSE).

## Author

Created by [@ajay19886](https://github.com/ajay19886).
