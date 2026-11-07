@echo off
title QuickFavorites installer
rem  Double-click to install or update QuickFavorites for the current user (no admin rights needed).
rem  Extract the whole download first - this file needs Install-QuickFavorites.ps1 next to it.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-QuickFavorites.ps1" %*
echo.
pause
