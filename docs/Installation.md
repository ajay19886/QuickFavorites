# Installation Guide

1. Ensure Windows PowerShell 5.1 is available.
2. Create `%USERPROFILE%\QuickFavorites`.
3. Copy `FavoritesMenu.ps1` into that folder.
4. Create `%USERPROFILE%\QuickFavorites\Menu`.
5. Add your own shortcuts, files, and subfolders to `Menu`.
6. Run:

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "$env:USERPROFILE\QuickFavorites\FavoritesMenu.ps1"
   ```

Use only shortcuts and files you trust. The launcher starts selected items using Windows `Start-Process`.
