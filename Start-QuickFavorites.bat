@echo off
rem ---------------------------------------------------------------
rem  QuickFavorites launcher - double-click this file to start the bar.
rem  Keep it in the same folder as FavoritesMenu.ps1 (any folder works).
rem  Starting it again while the bar is running does nothing.
rem ---------------------------------------------------------------
if not exist "%~dp0FavoritesMenu.ps1" (
    echo FavoritesMenu.ps1 was not found next to this file.
    echo Put both files in the same folder and try again.
    pause
    exit /b 1
)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "%~dp0FavoritesMenu.ps1"
exit /b 0
