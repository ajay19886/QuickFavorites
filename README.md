# QuickFavorites

A lightweight floating desktop launcher for Windows, built with Windows PowerShell and Windows Forms.

QuickFavorites displays a small **Desktop »** button on the desktop. Clicking it opens a cascading menu based on the contents of your personal `QuickFavorites\Menu` folder.

## Features

- Floating, always-on-top desktop launcher.
- Cascading folder menus with lazy loading of subfolders.
- Opens files, applications, and Windows shortcuts from the menu.
- Drag the launcher to reposition it.
- Save and restore launcher position and lock state.
- Optional start-with-Windows setting.
- Dark menu styling and Windows Shell icons.
- Single-instance protection.
- Hides hidden and system items from the menu.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1.
- .NET Framework components included with supported Windows installations.
- No third-party PowerShell modules are required.

## Installation

1. Download `FavoritesMenu.ps1` from this repository (or download the ZIP from **Code → Download ZIP**).
2. Create the folder:

   ```text
   %USERPROFILE%\QuickFavorites
   ```

3. Place `FavoritesMenu.ps1` in that folder.
4. Create the menu folder:

   ```text
   %USERPROFILE%\QuickFavorites\Menu
   ```

5. Add folders, files, and shortcuts (`.lnk`) to the `Menu` folder.
6. Run the script using Windows PowerShell 5.1:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "$env:USERPROFILE\QuickFavorites\FavoritesMenu.ps1"
   ```

The script creates the menu folder if it does not already exist.

## Using QuickFavorites

- **Left-click** the floating Desktop button to open the favorites menu.
- **Drag** the button to move it.
- **Right-click** the button to access the available launcher options, including opening the menu folder, locking/resetting position, configuring startup, and exiting.

The menu reflects the contents of the `Menu` folder. Organize items into subfolders to create cascading menus.

## Configuration and data

QuickFavorites stores its user data outside the source repository:

| Path | Purpose |
|---|---|
| `%USERPROFILE%\QuickFavorites\Menu` | Files, shortcuts, and folders displayed in the menu |
| `%USERPROFILE%\QuickFavorites\settings.json` | Saved launcher position and lock setting |

Do not commit personal shortcuts, documents, or the local settings file to this repository.

## Uninstall

1. Exit QuickFavorites using its right-click menu.
2. If enabled, disable **Start with Windows** from the right-click menu.
3. Remove the QuickFavorites startup shortcut if you created one separately.
4. Optionally delete `%USERPROFILE%\QuickFavorites` after backing up any personal files stored in its `Menu` folder.

## Compatibility and limitations

This project is designed for Windows desktop use. It uses Windows Forms and Windows Shell APIs and is not intended for macOS or Linux.

The repository contains the current PowerShell implementation. Behaviour may vary with Windows display scaling, multi-monitor arrangements, and system policies.

## Contributing

Bug reports, suggestions, and pull requests are welcome. Please include your Windows version, PowerShell version, steps to reproduce, and any relevant error message.

## License

QuickFavorites is released under the MIT License. See [LICENSE](LICENSE).

## Author

Created by [@ajay19886](https://github.com/ajay19886).
