#Requires -Version 5.1
<#
.SYNOPSIS
    Installs (or removes) QuickFavorites for the current user. No administrator rights needed.

.DESCRIPTION
    Install : copies the program files to %USERPROFILE%\QuickFavorites, optionally creates a sample
              favorites menu, a desktop shortcut and "start with Windows", then starts the bar.
              Re-running it simply updates the program files. Your own Menu folder and settings are
              never overwritten or deleted by an install or update.
    Uninstall: stops the bar and removes the startup entry and desktop shortcut. It deletes your
              favorites and settings only if you explicitly say yes.

.PARAMETER Uninstall
    Remove QuickFavorites instead of installing it.

.PARAMETER Quiet
    No questions. Install: update files, create the sample menu only if the Menu folder is empty,
    keep an existing autostart entry (never adds a new one), start the bar. Uninstall: never deletes your data.
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

$src      = $PSScriptRoot
$target   = Join-Path $env:USERPROFILE 'QuickFavorites'
$menuDir  = Join-Path $target 'Menu'
$runKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName  = 'QuickFavoritesBar'
$lnkPath  = Join-Path ([Environment]::GetFolderPath('Desktop')) 'QuickFavorites.lnk'
$appFiles = 'FavoritesMenu.ps1', 'Start-QuickFavorites.bat', 'Install-QuickFavorites.ps1'

# On Windows 11 the bar is started through a headless console host, so no Windows Terminal tab or
# taskbar icon appears (and nothing can be closed by accident). Older Windows uses a hidden window.
function Get-StartupCommand {
    $file = Join-Path $target 'FavoritesMenu.ps1'
    if ([Environment]::OSVersion.Version.Build -ge 22000) {
        return ('conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "{0}" -Detached' -f $file)
    }
    return ('powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "{0}" -Detached' -f $file)
}

function Start-Bar {
    $file   = Join-Path $target 'FavoritesMenu.ps1'
    $psArgs = '-NoProfile -ExecutionPolicy Bypass -STA -File "{0}" -Detached' -f $file
    if ([Environment]::OSVersion.Version.Build -ge 22000) {
        Start-Process -FilePath 'conhost.exe' -ArgumentList "--headless powershell.exe $psArgs"
    } else {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $psArgs -WindowStyle Hidden
    }
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Read-YesNo {
    param([string]$Question, [bool]$Default)
    if ($Quiet) { return $Default }
    $hint = if ($Default) { '[Y/n] (Enter = Yes)' } else { '[y/N] (Enter = No)' }
    while ($true) {
        $answer = (Read-Host "$Question $hint").Trim().ToLowerInvariant()
        if ($answer -eq '')               { return $Default }
        if ($answer -in 'y', 'yes')       { return $true }
        if ($answer -in 'n', 'no')        { return $false }
    }
}

function New-Shortcut {
    param(
        [string]$Path,
        [string]$Target,
        [string]$WorkingDirectory = '',
        [int]$WindowStyle = 1,
        [string]$Description = ''
    )
    $ws = New-Object -ComObject WScript.Shell
    try {
        $s = $ws.CreateShortcut($Path)
        $s.TargetPath  = $Target
        if ($WorkingDirectory) { $s.WorkingDirectory = $WorkingDirectory }
        if ($Description)      { $s.Description = $Description }
        $s.WindowStyle = $WindowStyle
        $s.Save()
    } finally {
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws)
    }
}

# Stops a running bar (only processes whose command line mentions FavoritesMenu.ps1)
function Stop-QuickFavorites {
    Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'conhost.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*FavoritesMenu.ps1*' -and $_.ProcessId -ne $PID } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

# Sample menu: files come from the "sample-menu" folder of the download; shortcuts to
# built-in Windows tools and your own folders are created here so the paths are always correct.
function New-SampleMenu {
    $null = New-Item -ItemType Directory -Path $menuDir -Force

    $sample = Join-Path $src 'sample-menu'
    if (Test-Path -LiteralPath $sample) {
        Copy-Item -Path (Join-Path $sample '*') -Destination $menuDir -Recurse -Force
    }

    $tools = Join-Path $menuDir '03 - Tools'
    $quick = Join-Path $menuDir '04 - Quick folders'
    $null = New-Item -ItemType Directory -Path $tools, $quick -Force

    $sys = Join-Path $env:SystemRoot 'System32'
    $toolList = [ordered]@{
        'Notepad'       = Join-Path $sys 'notepad.exe'
        'Calculator'    = Join-Path $sys 'calc.exe'
        'Paint'         = Join-Path $sys 'mspaint.exe'
        'Task Manager'  = Join-Path $sys 'taskmgr.exe'
        'File Explorer' = Join-Path $env:SystemRoot 'explorer.exe'
    }
    foreach ($name in $toolList.Keys) {
        if (Test-Path -LiteralPath $toolList[$name]) {
            New-Shortcut -Path (Join-Path $tools "$name.lnk") -Target $toolList[$name]
        }
    }

    $downloads = $null
    try { $downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path } catch { }
    if (-not $downloads) { $downloads = Join-Path $env:USERPROFILE 'Downloads' }

    $folderList = [ordered]@{
        'Downloads' = $downloads
        'Documents' = [Environment]::GetFolderPath('MyDocuments')
        'Desktop'   = [Environment]::GetFolderPath('Desktop')
        'Pictures'  = [Environment]::GetFolderPath('MyPictures')
    }
    foreach ($name in $folderList.Keys) {
        $p = $folderList[$name]
        if ($p -and (Test-Path -LiteralPath $p)) {
            New-Shortcut -Path (Join-Path $quick "$name.lnk") -Target $p
        }
    }
}

# ---------------------------------------------------------------------------
# Install / update
# ---------------------------------------------------------------------------
function Install-App {
    foreach ($f in 'FavoritesMenu.ps1', 'Start-QuickFavorites.bat') {
        if (-not (Test-Path -LiteralPath (Join-Path $src $f))) {
            throw "$f was not found next to the installer. Extract the whole download first, then run Install.bat again."
        }
    }

    Write-Host ''
    Write-Host 'QuickFavorites installer' -ForegroundColor Cyan
    Write-Host "Install folder: $target"
    Write-Host 'Questions: just press Enter for Yes, or type n for No.'
    Write-Host ''

    $null = New-Item -ItemType Directory -Path $target -Force
    Stop-QuickFavorites

    if ((Resolve-Path -LiteralPath $src).Path -ine (Resolve-Path -LiteralPath $target).Path) {
        foreach ($f in $appFiles) {
            Copy-Item -LiteralPath (Join-Path $src $f) -Destination $target -Force
        }
    }
    Get-ChildItem -LiteralPath $target -File | Unblock-File -ErrorAction SilentlyContinue
    Write-Host 'Program files installed (existing favorites and settings were not touched).' -ForegroundColor Green

    # Sample menu - only offered when there are no favorites yet
    $hasMenu = (Test-Path -LiteralPath $menuDir) -and
               (Get-ChildItem -LiteralPath $menuDir -Force -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $hasMenu) {
        if (Read-YesNo 'Create a sample favorites menu so you can try it right away?' $true) {
            New-SampleMenu
            Write-Host 'Sample menu created.' -ForegroundColor Green
        } else {
            $null = New-Item -ItemType Directory -Path $menuDir -Force
        }
    }

    # Desktop shortcut
    if (Read-YesNo 'Create a desktop shortcut to start QuickFavorites?' $true) {
        New-Shortcut -Path $lnkPath -Target (Join-Path $target 'Start-QuickFavorites.bat') `
                     -WorkingDirectory $target -WindowStyle 7 -Description 'Start QuickFavorites'
        Write-Host 'Desktop shortcut created.' -ForegroundColor Green
    }

    # Start with Windows (an existing entry is simply repointed to the installed copy)
    $existing = Get-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
    if ($existing -or (-not $Quiet -and (Read-YesNo 'Start QuickFavorites automatically when you sign in to Windows?' $true))) {
        Set-ItemProperty -Path $runKey -Name $runName -Value (Get-StartupCommand)
        Write-Host 'Start with Windows is on.' -ForegroundColor Green
    }

    # Start the bar
    Start-Bar

    Write-Host ''
    Write-Host 'Done! Look for the "Desktop >>" button just above the taskbar.' -ForegroundColor Cyan
    Write-Host 'Tip: right-click the button for options. To start it again later, use the desktop shortcut or'
    Write-Host "     $target\Start-QuickFavorites.bat"
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
function Uninstall-App {
    Write-Host ''
    Write-Host 'Removing QuickFavorites...' -ForegroundColor Cyan
    Stop-QuickFavorites
    Remove-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $lnkPath -Force -ErrorAction SilentlyContinue
    Write-Host 'Stopped the bar, removed "start with Windows" and the desktop shortcut.' -ForegroundColor Green

    if (Test-Path -LiteralPath $target) {
        if (Read-YesNo "Also DELETE the folder $target, including your favorites menu and settings?" $false) {
            try {
                Set-Location -LiteralPath $env:SystemRoot     # never delete the folder we are standing in
                # cmd's rd removes junctions/symlinks as links only - it never deletes what they point to
                Start-Process -FilePath 'cmd.exe' -ArgumentList '/c', ('rd /s /q "{0}"' -f $target) -Wait -WindowStyle Hidden
                if (Test-Path -LiteralPath $target) { throw 'some files are still in use or protected' }
                Write-Host 'Folder deleted.' -ForegroundColor Green
            } catch {
                Write-Host "Some files could not be deleted ($($_.Exception.Message)). You can delete the folder manually." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Kept $target (your favorites and settings)."
        }
    }
    Write-Host 'Done.'
}

# ---------------------------------------------------------------------------
try {
    if (-not $env:USERPROFILE) { throw 'The USERPROFILE environment variable is not set.' }
    if ($Uninstall) { Uninstall-App } else { Install-App }
} catch {
    Write-Host ''
    Write-Host "Something went wrong: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
