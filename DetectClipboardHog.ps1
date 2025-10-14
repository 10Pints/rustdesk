# DetectClipboardHog.ps1 version 1.26
Write-Host "=== DetectClipboardHog.ps1 version 1.26 starting ==="

# --------------------------------------------------------------------
# Win32 interop setup
# --------------------------------------------------------------------
$versionTag = "v1_26"
$global:Win32TypeName = "Win32_$versionTag"
$global:Win32Type = $null

$existing = [AppDomain]::CurrentDomain.GetAssemblies() |
    ForEach-Object { $_.GetTypes() } |
    Where-Object { $_.Name -eq $global:Win32TypeName }

if ($existing) {
    Write-Host "Reusing loaded interop type: $global:Win32TypeName"
    $global:Win32Type = $existing
} else {
    Write-Host "Initializing interop type: $global:Win32TypeName"

    $sig = @"
using System;
using System.Runtime.InteropServices;

public class $global:Win32TypeName {
    [DllImport("user32.dll")]
    public static extern IntPtr GetOpenClipboardWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int processId);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
}
"@

    try {
        Add-Type -TypeDefinition $sig -ErrorAction Stop
        $global:Win32Type = [Type]::GetType($global:Win32TypeName, $false)
        if (-not $global:Win32Type) {
            $global:Win32Type = [AppDomain]::CurrentDomain.GetAssemblies() |
                ForEach-Object { $_.GetTypes() } |
                Where-Object { $_.Name -eq $global:Win32TypeName } |
                Select-Object -First 1
        }
        Write-Host "Win32 interop type $global:Win32TypeName loaded successfully."
    } catch {
        Write-Warning "⚠ Add-Type failed: $($_.Exception.Message)"
    }
}

if (-not $global:Win32Type) {
    Write-Warning "⚠ Win32 interop type failed to load properly."
}

Write-Host "Enhanced clipboard monitoring with RustDesk correlation..."
Write-Host "Press Ctrl+C to stop monitoring..."
Start-Sleep -Seconds 1
Write-Host "Testing clipboard detection..."

# --------------------------------------------------------------------
# RustDesk log path
# --------------------------------------------------------------------
$rustDeskLog = "$env:AppData\RustDesk\log\cm\RustDesk_rCURRENT.log"
Write-Host "Watching RustDesk log for clipboard errors: $rustDeskLog"

# --------------------------------------------------------------------
# Identify PowerShell instances to ignore (those tailing RustDesk logs)
# --------------------------------------------------------------------
$ignorePIDs = @()
try {
    $ignorePIDs = Get-Process -Name "powershell" -ErrorAction SilentlyContinue |
        Where-Object {
            try { $_.Path -like "C:\rustdesk-server\*" } catch { $false }
        } |
        Select-Object -ExpandProperty Id -ErrorAction SilentlyContinue
} catch {}

if ($ignorePIDs.Count -gt 0) {
    Write-Host "Ignoring PowerShell PIDs from C:\rustdesk-server: $($ignorePIDs -join ', ')"
} else {
    Write-Host "No PowerShell PIDs from C:\rustdesk-server found to ignore."
}

# --------------------------------------------------------------------
# Function: Get clipboard lock info
# --------------------------------------------------------------------
function Get-ClipboardOwnerInfo {
    try {
        if (-not $global:Win32Type) { return "Error: Win32 type not found" }

        $t = $global:Win32Type
        $hWnd = $t::GetOpenClipboardWindow()
        if ($hWnd -eq [IntPtr]::Zero) {
            # Try fallback to foreground window
            $hWnd = $t::GetForegroundWindow()
            if ($hWnd -eq [IntPtr]::Zero) { return "None | PID:  | Process:" }
        }

        $procId = 0
        [void]$t::GetWindowThreadProcessId($hWnd, [ref]$procId)

        $sb = New-Object System.Text.StringBuilder 256
        [void]$t::GetWindowText($hWnd, $sb, $sb.Capacity)
        $winText = $sb.ToString()

        $proc = if ($procId -ne 0) { Get-Process -Id $procId -ErrorAction SilentlyContinue } else { $null }
        $procName = if ($proc) { $proc.ProcessName } else { "" }

        # Check if this PID should be ignored
        if ($ignorePIDs -contains $procId) {
            return "IGNORED PowerShell (RustDesk tail) | PID: $procId | Process: $procName"
        }

        return "$winText | PID: $procId | Process: $procName"
    } catch {
        return "Error retrieving owner: $($_.Exception.Message)"
    }
}

# --------------------------------------------------------------------
# Function: Clipboard test read
# --------------------------------------------------------------------
function Test-Clipboard {
    try {
        Get-Clipboard -ErrorAction Stop | Out-Null
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard read OK"
        return $true
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard read FAILED"
        return $false
    }
}

# --------------------------------------------------------------------
# Monitor loop
# --------------------------------------------------------------------
$filter = "ClipboardOccupied"
$lastLine = ""

Get-Content -Path $rustDeskLog -Tail 0 -Wait | ForEach-Object {
    $line = $_
    if ($line -ne $lastLine -and $line -match $filter) {
        $lastLine = $line
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') RustDesk log error detected ($filter)"
        $owner = Get-ClipboardOwnerInfo
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard currently locked by window: $owner"
    }

    Test-Clipboard | Out-Null
    Start-Sleep -Milliseconds 500
}
