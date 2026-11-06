# QuickFavorites

**A lightweight, floating desktop launcher for Windows — no administrator rights, no installer, and no UAC elevation required.**

QuickFavorites gives you a small, draggable **Desktop »** button that stays above your desktop windows. Click it to open a cascading menu of your favourite folders, files, applications, and Windows shortcuts.

Designed for everyday Windows users, including users working on standard accounts without local administrator privileges.

## Why QuickFavorites?

- **No administrator rights required** — runs in the current user's Windows session.
- **No UAC elevation** — the script does not request administrator elevation or use `Run as administrator`.
- **No installer** — download the PowerShell script and run it.
- **Portable, user-profile based** — stores its menu and settings under your user profile; no Program Files installation is needed.
- **Floating desktop launcher** — a compact, always-on-top button that you can drag to a convenient position.
- **Cascading quick-access menus** — organize folders and shortcuts into subfolders and navigate them from the launcher.
- **No third-party PowerShell modules** — uses Windows PowerShell and built-in Windows components.

> **Note:** QuickFavorites does not require administrator privileges by design. However, an organization's Group Policy, application-control rules, or PowerShell execution restrictions may still prevent scripts from running. Follow your organization's IT policies.

## Features

- Floating, always-on-top desktop launcher.
- Cascading folder menus with lazy loading of subfolders.
- Opens files, applications, and Windows shortcuts from the menu.
- Drag the launcher to reposition it.
- Save and restore launcher position and lock state.
- Optional start-with-Windows setting for the current user.
- Dark menu styling and Windows Shell icons.
- Single-instance protection.
- Hides hidden and system items from the menu.

## Requirements

- Windows 10 or Windows 11.
- Windows PowerShell 5.1.
- Standard user account; administrator rights are not required.
- .NET Framework components included with supported Windows installations.
- No third-party PowerShell modules.

## Installation — no installer required

1. Download `FavoritesMenu.ps1` from this repository (or choose **Code → Download ZIP**).
2. Create this folder if it does not already exist:

   `%USERPROFILE%\QuickFavorites`

3. Place `FavoritesMenu.ps1` in that folder.
4. Create the menu folder:

   `%USERPROFILE%\QuickFavorites\Menu`

5. Add your folders, files, applications, and Windows shortcuts (`.lnk`) to the `Menu` folder.
6. Run the script using Windows PowerShell 5.1:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "$env:USERPROFILE\QuickFavorites\FavoritesMenu.ps1"
   ```

The script creates the menu folder if it does not already exist. The `-ExecutionPolicy Bypass` argument applies to that PowerShell process; it does not change the machine-wide execution policy or grant administrator privileges.

## Using QuickFavorites

- **Left-click** the floating Desktop button to open the favorites menu.
- **Drag** the button to move it.
- **Right-click** the button to access available launcher options, including opening the menu folder, locking or resetting position, configuring startup, and exiting.

The menu reflects the contents of the `Menu` folder. Organize items into subfolders to create cascading menus.

## Runs without administrator privileges

QuickFavorites is designed for a standard Windows user account:

- Its application script and user data can be kept under `%USERPROFILE%`.
- Its optional Start with Windows setting uses the current-user registry location (`HKCU`), not a machine-wide startup location.
- It does not install a Windows service, device driver, or system-wide component.
- It does not need to write to `C:\Program Files` or other protected system folders.
- It does not request UAC elevation.

This makes it suitable for many work or personal PCs where users do not have local administrator access, subject to the computer's PowerShell and application-control policies.

## Configuration and data

QuickFavorites stores its user data outside the source repository:

| Path | Purpose |
|---|---|
| `%USERPROFILE%\QuickFavorites\Menu` | Files, shortcuts, and folders displayed in the menu |
| `%USERPROFILE%\QuickFavorites\settings.json` | Saved launcher position and lock setting |

Do not commit personal shortcuts, documents, or your local settings file to this repository.

## Uninstall

1. Exit QuickFavorites using its right-click menu.
2. If enabled, disable **Start with Windows** from the right-click menu.
3. Remove the QuickFavorites startup shortcut if you created one separately.
4. Optionally delete `%USERPROFILE%\QuickFavorites` after backing up any personal files stored in its `Menu` folder.

No traditional uninstaller is needed.

## Compatibility and limitations

QuickFavorites is designed for Windows desktop use. It uses Windows Forms and Windows Shell APIs and is not intended for macOS or Linux.

Behaviour may vary with Windows display scaling, multi-monitor arrangements, and system policies. Managed devices may restrict PowerShell script execution even when no administrator rights are required.

## Contributing

Bug reports, suggestions, and pull requests are welcome. Please include your Windows version, PowerShell version, steps to reproduce, and any relevant error message.

## License

QuickFavorites is released under the MIT License. See [LICENSE](LICENSE).

## Author

Created by [@ajay19886](https://github.com/ajay19886).
