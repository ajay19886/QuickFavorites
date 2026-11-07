@echo off
title QuickFavorites uninstaller
rem  Double-click to remove QuickFavorites. Your favorites are only deleted if you say yes.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-QuickFavorites.ps1" -Uninstall %*
echo.
pause
