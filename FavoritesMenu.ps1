#Requires -Version 5.1
<#
.SYNOPSIS
    Floating "Desktop >>" quick-launch bar that shows a folder of shortcuts as a menu.

.NOTES
    Shortcuts folder : %USERPROFILE%\QuickFavorites\Menu   (created if missing)
    Settings file    : %USERPROFILE%\QuickFavorites\settings.json
    Run manually     : powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File FavoritesMenu.ps1
    Right-click the bar for: Open folder, Lock position, Reset position, Start with Windows, Exit.
#>

param([switch]$Detached)

# Relaunch in its own hidden process, so closing the console it was started from does not
# close the bar. Use -Detached to run in the current console instead (handy for debugging:
# warnings and errors then stay visible).
if (-not $Detached -and $PSCommandPath) {
    try {
        $relaunch = '-NoProfile -ExecutionPolicy Bypass -STA -File "{0}" -Detached' -f $PSCommandPath
        Start-Process -FilePath 'powershell.exe' -ArgumentList $relaunch -WindowStyle Hidden -ErrorAction Stop
        return
    } catch { }   # if the relaunch fails, simply continue in this process
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------------------------------------------------------------------
# Single instance (a second launch exits silently instead of stacking a bar)
# ---------------------------------------------------------------------------
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\QuickFavoritesBar', [ref]$createdNew)
if (-not $createdNew) { $mutex.Dispose(); return }

# ---------------------------------------------------------------------------
# DPI awareness - must happen before any window is created (sharp text, correct
# coordinates on 125% / 150% displays)
# ---------------------------------------------------------------------------
try {
    Add-Type -Namespace QuickFav -Name Native -ReferencedAssemblies 'System.Drawing' -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int index);
[DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h, int cmd);
[DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
[DllImport("shell32.dll")] static extern int SHQueryUserNotificationState(out int state);

// Restores the TopMost flag if some other program cleared it (no activation, no move)
public static void EnsureTopMost(IntPtr h) {
    if ((GetWindowLong(h, -20) & 0x8) == 0) SetWindowPos(h, new IntPtr(-1), 0, 0, 0, 0, 0x13);
}
public static bool IsShown(IntPtr h) { return IsWindowVisible(h); }
// Hide / show WITHOUT stealing focus from the app the user is working in
public static void SetShown(IntPtr h, bool show) { ShowWindow(h, show ? 4 : 0); }
// 2 = full-screen app, 3 = Direct3D full-screen, 4 = presentation mode, 5 = normal
public static int FullScreenState() {
    int s;
    return SHQueryUserNotificationState(out s) == 0 ? s : 5;
}

// ---- Shell icons (same icons Explorer shows) ----
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
struct SHFILEINFO {
    public IntPtr hIcon;
    public int iIcon;
    public uint dwAttributes;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szDisplayName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 80)]  public string szTypeName;
}
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
static extern IntPtr SHGetFileInfo(string path, uint attrs, ref SHFILEINFO fi, uint size, uint flags);
[DllImport("user32.dll")] static extern bool DestroyIcon(IntPtr h);

// isFolder   : generic folder icon, no disk access
// byExtension: icon of the file TYPE (docx, pdf...), no disk access
// otherwise  : the item's own icon (.lnk target, .exe, .ico, .url)
public static System.Drawing.Icon GetShellIcon(string path, bool isFolder, bool byExtension) {
    SHFILEINFO fi = new SHFILEINFO();
    uint flags = 0x100 | 0x1;                 // SHGFI_ICON | SHGFI_SMALLICON
    uint attrs = 0;
    if (isFolder)         { flags |= 0x10; attrs = 0x10; }   // SHGFI_USEFILEATTRIBUTES + FILE_ATTRIBUTE_DIRECTORY
    else if (byExtension) { flags |= 0x10; attrs = 0x80; }   // SHGFI_USEFILEATTRIBUTES + FILE_ATTRIBUTE_NORMAL
    SHGetFileInfo(path, attrs, ref fi, (uint)Marshal.SizeOf(fi), flags);
    if (fi.hIcon == IntPtr.Zero) return null;
    System.Drawing.Icon clone = (System.Drawing.Icon)System.Drawing.Icon.FromHandle(fi.hIcon).Clone();
    DestroyIcon(fi.hIcon);
    return clone;
}
'@
    [void][QuickFav.Native]::SetProcessDPIAware()
} catch {
    # Visible only when run from a normal console; the bar still works, minus icons/DPI/full-screen features
    Write-Warning "Native helpers unavailable: $($_.Exception.Message)"
}
[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------------------------------------------------------------------------
# Paths and settings
# ---------------------------------------------------------------------------
$scriptPath   = $PSCommandPath
$baseDir      = Join-Path $env:USERPROFILE 'QuickFavorites'
$root         = Join-Path $baseDir 'Menu'
$settingsFile = Join-Path $baseDir 'settings.json'
$runKey       = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName      = 'QuickFavoritesBar'
$skipAttr     = [System.IO.FileAttributes]'Hidden,System'   # hides desktop.ini, Thumbs.db etc.

$null = New-Item -ItemType Directory -Path $root -Force -ErrorAction SilentlyContinue

$script:settings = @{ Left = $null; Top = $null; Locked = $false }
try {
    if (Test-Path -LiteralPath $settingsFile) {
        $json = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json
        if ($null -ne $json.Left)   { $script:settings.Left   = [int]$json.Left }
        if ($null -ne $json.Top)    { $script:settings.Top    = [int]$json.Top }
        if ($null -ne $json.Locked) { $script:settings.Locked = [bool]$json.Locked }
    }
} catch { }   # corrupt file -> fall back to defaults

function Save-Settings {
    try {
        $script:settings | ConvertTo-Json | Set-Content -LiteralPath $settingsFile -Encoding UTF8 -ErrorAction Stop
    } catch { }   # never crash the bar because a settings write failed
}

# ---------------------------------------------------------------------------
# Main bar
# ---------------------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text            = 'Desktop'
$form.FormBorderStyle = 'None'
$form.StartPosition   = 'Manual'
$form.TopMost         = $true
$form.ShowInTaskbar   = $false
$form.BackColor       = [System.Drawing.Color]::FromArgb(38, 55, 70)

$g = $form.CreateGraphics(); $scale = $g.DpiX / 96.0; $g.Dispose()
$form.Size = New-Object System.Drawing.Size([int](110 * $scale), [int](34 * $scale))

$button = New-Object System.Windows.Forms.Button
$button.Text      = 'Desktop  ' + [char]0x00BB          # built from a char code: no file-encoding problems
$button.Dock      = 'Fill'
$button.TabStop   = $false
$button.FlatStyle = 'Flat'
$button.FlatAppearance.BorderSize         = 0
$button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(55, 78, 98)
$button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(70, 95, 118)
$button.BackColor = $form.BackColor
$button.ForeColor = [System.Drawing.Color]::White
$button.Font      = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Controls.Add($button)

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$menu.Font            = New-Object System.Drawing.Font('Segoe UI', 10)
$menu.ShowImageMargin = $true
$menu.ShowItemToolTips = $true
$iconSize = [int][Math]::Round(16 * $scale)
$menu.ImageScalingSize = New-Object System.Drawing.Size($iconSize, $iconSize)

# Dark theme for the dropdowns, matching the bar (falls back to the normal look if compiling fails)
$darkRenderer = $null
try {
    Add-Type -ReferencedAssemblies 'System.Windows.Forms', 'System.Drawing' -TypeDefinition @'
using System.Drawing;
using System.Windows.Forms;
public class QfColors : ProfessionalColorTable {
    static Color Bg  = Color.FromArgb(38, 55, 70);
    static Color Sel = Color.FromArgb(55, 78, 98);
    static Color Brd = Color.FromArgb(70, 95, 118);
    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Brd; } }
    public override Color MenuItemBorder { get { return Brd; } }
    public override Color MenuItemSelected { get { return Sel; } }
    public override Color MenuItemSelectedGradientBegin { get { return Sel; } }
    public override Color MenuItemSelectedGradientEnd { get { return Sel; } }
    public override Color MenuItemPressedGradientBegin { get { return Sel; } }
    public override Color MenuItemPressedGradientMiddle { get { return Sel; } }
    public override Color MenuItemPressedGradientEnd { get { return Sel; } }
    public override Color SeparatorDark { get { return Brd; } }
    public override Color SeparatorLight { get { return Brd; } }
    public override Color CheckBackground { get { return Sel; } }
    public override Color CheckSelectedBackground { get { return Sel; } }
    public override Color CheckPressedBackground { get { return Sel; } }
}
'@
    $darkRenderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer -ArgumentList (New-Object QfColors)
    $darkRenderer.RoundedEdges = $false
    $menu.Renderer = $darkRenderer
} catch {
    $darkRenderer = $null
    Write-Warning "Dark menu theme unavailable: $($_.Exception.Message)"
}
$menuFore = if ($darkRenderer) { [System.Drawing.Color]::White } else { [System.Drawing.SystemColors]::ControlText }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function Show-Warning {
    param([string]$Message)
    [void][System.Windows.Forms.MessageBox]::Show(
        $form, $Message, 'Quick Favorites',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
}

# Icons are cached (per path for .lnk/.exe/.ico/.url, per extension otherwise)
$script:iconCache = @{}
function Get-ItemImage {
    param([string]$Path, [bool]$IsFolder)
    try {
        $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
        $key = if ($IsFolder) { '<folder>' }
               elseif ($ext -in '.lnk', '.exe', '.ico', '.url', '') { $Path }
               else { $ext }
        if (-not $script:iconCache.ContainsKey($key)) {
            $byExt = (-not $IsFolder) -and ($ext -notin '.lnk', '.exe', '.ico', '.url', '')
            $icon  = $null
            try { $icon = [QuickFav.Native]::GetShellIcon($Path, $IsFolder, $byExt) } catch { }
            if (-not $icon -and -not $IsFolder) {
                try { $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($Path) } catch { }
            }
            if ($icon) { $script:iconCache[$key] = $icon.ToBitmap(); $icon.Dispose() }
            else       { $script:iconCache[$key] = $null }
        }
        return $script:iconCache[$key]
    } catch { return $null }
}

function Clear-MenuItems {
    param([System.Windows.Forms.ToolStripItemCollection]$Items)
    $old = @($Items)
    $Items.Clear()
    foreach ($i in $old) { $i.Dispose() }     # avoids leaking handles on every rebuild
}

function Start-Favorite {
    param([string]$Path)
    try {
        if (-not (Test-Path -LiteralPath $Path)) { throw "This item no longer exists:`n$Path" }
        Start-Process -FilePath $Path -ErrorAction Stop
    } catch {
        Show-Warning $_.Exception.Message
    }
}

$natural = { [regex]::Replace($_.Name, '\d+', { param($m) $m.Value.PadLeft(12, '0') }) }

# Adds one level only. Sub-folders are filled when they are opened (lazy), so a
# big or looping folder tree (junctions/symlinks) can never freeze the bar.
function Add-Entries {
    param(
        [System.Windows.Forms.ToolStripItemCollection]$Items,
        [string]$Folder
    )

    try {
        $all = @(Get-ChildItem -LiteralPath $Folder -Force -ErrorAction Stop)
    } catch {
        # Access denied, offline network share, folder deleted... show it in the menu instead of hiding it
        $bad = New-Object System.Windows.Forms.ToolStripMenuItem("(can't open this folder)")
        $bad.Enabled     = $false
        $bad.ToolTipText = $_.Exception.Message
        [void]$Items.Add($bad)
        return
    }

    $entries = @($all |
        Where-Object { ([int]($_.Attributes -band $skipAttr)) -eq 0 } |
        Sort-Object @{ Expression = { -not $_.PSIsContainer } }, @{ Expression = $natural })

    foreach ($entry in $entries) {
        $item = New-Object System.Windows.Forms.ToolStripMenuItem
        $item.ToolTipText = $entry.FullName
        $item.ForeColor = $menuFore
        $item.Image = Get-ItemImage -Path $entry.FullName -IsFolder $entry.PSIsContainer

        if ($entry.PSIsContainer) {
            $item.Text = $entry.Name -replace '&', '&&'            # '&' would otherwise become a hotkey underline
            $item.Tag  = $entry.FullName
            [void]$item.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripMenuItem('...')))   # placeholder so the arrow shows
            $item.Add_DropDownOpening({
                param($sender, $e)
                Clear-MenuItems $sender.DropDownItems
                Add-Entries -Items $sender.DropDownItems -Folder ([string]$sender.Tag)
                if ($sender.DropDownItems.Count -eq 0) {
                    $empty = New-Object System.Windows.Forms.ToolStripMenuItem('(empty)')
                    $empty.Enabled = $false
                    [void]$sender.DropDownItems.Add($empty)
                }
            })
        }
        else {
            # Hide .lnk/.url extensions, keep others so "Report.docx" and "Report.pdf" stay distinguishable
            $ext  = $entry.Extension.ToLowerInvariant()
            $name = if ($ext -in '.lnk', '.url') { [System.IO.Path]::GetFileNameWithoutExtension($entry.Name) } else { $entry.Name }
            $item.Text = $name -replace '&', '&&'
            $item.Tag  = $entry.FullName
            $item.Add_Click({
                param($sender, $e)
                Start-Favorite -Path ([string]$sender.Tag)
            })
        }
        [void]$Items.Add($item)
    }
}

function Get-VisiblePosition {
    # Keeps the bar fully inside the working area of whichever monitor it is on.
    param([int]$X, [int]$Y)
    $rect = New-Object System.Drawing.Rectangle($X, $Y, $form.Width, $form.Height)
    $wa   = [System.Windows.Forms.Screen]::FromRectangle($rect).WorkingArea
    $nx = [Math]::Max($wa.Left, [Math]::Min($X, $wa.Right  - $form.Width))
    $ny = [Math]::Max($wa.Top,  [Math]::Min($Y, $wa.Bottom - $form.Height))
    return [System.Drawing.Point]::new($nx, $ny)
}

function Get-DefaultPosition {
    $wa = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    return [System.Drawing.Point]::new($wa.Left + 15, $wa.Bottom - $form.Height)
}

# ---------------------------------------------------------------------------
# Left click: show favorites (opens upward near the bottom, downward near the top)
# ---------------------------------------------------------------------------
$script:dragging      = $false
$script:suppressClick = $false
$script:mouseStart    = [System.Drawing.Point]::Empty
$script:formStart     = [System.Drawing.Point]::Empty
$dragThreshold        = [int][Math]::Round(6 * $scale)

$button.Add_Click({
    if ($script:suppressClick) { $script:suppressClick = $false; return }

    Clear-MenuItems $menu.Items
    Add-Entries -Items $menu.Items -Folder $root
    if ($menu.Items.Count -eq 0) {
        $empty = New-Object System.Windows.Forms.ToolStripMenuItem('(no favorites yet - right-click the bar > Open favorites folder)')
        $empty.Enabled = $false
        [void]$menu.Items.Add($empty)
    }

    $wa = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
    if ($form.Top -gt ($wa.Top + $wa.Height / 2)) {
        $menu.Show($button, [System.Drawing.Point]::new(0, 0), [System.Windows.Forms.ToolStripDropDownDirection]::AboveRight)
    } else {
        $menu.Show($button, [System.Drawing.Point]::new(0, $button.Height), [System.Windows.Forms.ToolStripDropDownDirection]::BelowRight)
    }
})

# ---------------------------------------------------------------------------
# Drag to move (disabled while locked), position saved on release
# ---------------------------------------------------------------------------
$button.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:dragging      = $false
        $script:suppressClick = $false
        $script:mouseStart    = [System.Windows.Forms.Control]::MousePosition
        $script:formStart     = $form.Location
    }
})

$button.Add_MouseMove({
    param($sender, $e)
    if ($script:settings.Locked) { return }
    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }

    $cur = [System.Windows.Forms.Control]::MousePosition
    $dx  = $cur.X - $script:mouseStart.X
    $dy  = $cur.Y - $script:mouseStart.Y

    if ($script:dragging -or [Math]::Abs($dx) -gt $dragThreshold -or [Math]::Abs($dy) -gt $dragThreshold) {
        $script:dragging = $true
        $form.Location = Get-VisiblePosition ($script:formStart.X + $dx) ($script:formStart.Y + $dy)
    }
})

$button.Add_MouseUp({
    if ($script:dragging) {
        $script:dragging      = $false
        $script:suppressClick = $true
        $script:settings.Left = $form.Left
        $script:settings.Top  = $form.Top
        Save-Settings
    }
})

# ---------------------------------------------------------------------------
# Right-click menu for the bar itself
# ---------------------------------------------------------------------------
$barMenu = New-Object System.Windows.Forms.ContextMenuStrip
$barMenu.Font = New-Object System.Drawing.Font('Segoe UI', 10)
if ($darkRenderer) { $barMenu.Renderer = $darkRenderer }

$miOpen = New-Object System.Windows.Forms.ToolStripMenuItem('Open favorites folder')
$miOpen.Add_Click({ Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $root) })

$miLock = New-Object System.Windows.Forms.ToolStripMenuItem('Lock position')
$miLock.CheckOnClick = $true
$miLock.Checked = [bool]$script:settings.Locked
$miLock.Add_Click({
    param($sender, $e)
    $script:settings.Locked = $sender.Checked
    Save-Settings
})

$miReset = New-Object System.Windows.Forms.ToolStripMenuItem('Reset position')
$miReset.Add_Click({
    $script:settings.Left = $null
    $script:settings.Top  = $null
    Save-Settings
    $d = Get-DefaultPosition
    $form.Location = Get-VisiblePosition $d.X $d.Y
})

# If a Startup-folder shortcut already launches this script, a Run-key entry would start it twice.
# In that case the menu item is locked (checked + disabled) and our own Run-key entry is removed.
function Get-StartupShortcut {
    $ws = $null
    try {
        $leaf = Split-Path -Leaf $scriptPath
        $dir  = [Environment]::GetFolderPath('Startup')
        $ws   = New-Object -ComObject WScript.Shell
        foreach ($f in @(Get-ChildItem -LiteralPath $dir -Filter '*.lnk' -ErrorAction SilentlyContinue)) {
            $s = $ws.CreateShortcut($f.FullName)
            $cmd = '{0} {1}' -f $s.TargetPath, $s.Arguments
            if ($cmd.IndexOf($leaf, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { return $f.FullName }
        }
    } catch { }
    finally { if ($ws) { [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($ws) } }
    return $null
}

$miStartup = New-Object System.Windows.Forms.ToolStripMenuItem('Start with Windows')
$startupLnk = Get-StartupShortcut
if ($startupLnk) {
    Remove-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
    $miStartup.Text        = 'Start with Windows (via Startup folder shortcut)'
    $miStartup.Checked     = $true
    $miStartup.Enabled     = $false
    $miStartup.ToolTipText = $startupLnk
} else {
    $miStartup.CheckOnClick = $true
    $miStartup.Checked = [bool](Get-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue)
}
$miStartup.Add_Click({
    param($sender, $e)
    try {
        if ($sender.Checked) {
            $cmd = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -STA -File "{0}" -Detached' -f $scriptPath
            Set-ItemProperty -Path $runKey -Name $runName -Value $cmd -ErrorAction Stop
        } else {
            Remove-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
        }
    } catch {
        $sender.Checked = -not $sender.Checked
        Show-Warning $_.Exception.Message
    }
})

$miExit = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
$miExit.Add_Click({ $form.Close() })

[void]$barMenu.Items.Add($miOpen)
[void]$barMenu.Items.Add($miLock)
[void]$barMenu.Items.Add($miReset)
[void]$barMenu.Items.Add($miStartup)
[void]$barMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
[void]$barMenu.Items.Add($miExit)
foreach ($i in $barMenu.Items) { $i.ForeColor = $menuFore }
$button.ContextMenuStrip = $barMenu

# ---------------------------------------------------------------------------
# Initial position (restore, validated against ALL monitors)
# ---------------------------------------------------------------------------
$start = Get-DefaultPosition
if ($null -ne $script:settings.Left -and $null -ne $script:settings.Top) {
    $start = [System.Drawing.Point]::new([int]$script:settings.Left, [int]$script:settings.Top)
}
$form.Location = Get-VisiblePosition $start.X $start.Y

# Housekeeping every 1.5 s: hide over full-screen apps / slideshows, restore TopMost
# if something cleared it, and keep the bar on-screen after monitor/dock/scale changes
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1500
$timer.Add_Tick({
    if ($script:dragging) { return }
    try {
        $h = $form.Handle
        $state = [QuickFav.Native]::FullScreenState()
        $fullScreen = ($state -eq 2 -or $state -eq 3 -or $state -eq 4)
        $shown = [QuickFav.Native]::IsShown($h)

        if ($fullScreen) {
            if ($shown) { [QuickFav.Native]::SetShown($h, $false) }
            return
        }
        if (-not $shown) { [QuickFav.Native]::SetShown($h, $true) }
        [QuickFav.Native]::EnsureTopMost($h)

        $p = Get-VisiblePosition $form.Left $form.Top
        if ($p.X -ne $form.Left -or $p.Y -ne $form.Top) { $form.Location = $p }
    } catch { }   # a failed tick must never kill the bar
})
$timer.Start()

# ---------------------------------------------------------------------------
# Run + clean up
# ---------------------------------------------------------------------------
try {
    [System.Windows.Forms.Application]::Run($form)
}
finally {
    $timer.Stop(); $timer.Dispose()
    foreach ($bmp in $script:iconCache.Values) { if ($bmp) { $bmp.Dispose() } }
    $menu.Dispose(); $barMenu.Dispose(); $form.Dispose()
    $mutex.ReleaseMutex(); $mutex.Dispose()
}
