# DetectClipboardHog.ps1
# version 1.39

Write-Host "=== DetectClipboardHog.ps1 version 1.39 starting ==="

$global:Win32Type = "Win32Interop"

# Load Win32 interop type if not already loaded
if (-not ([Type]::GetType($global:Win32Type))) {
    $win32Definition = @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class Win32Interop {
    [DllImport("user32.dll")]
    public static extern IntPtr GetOpenClipboardWindow();

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
}
"@

    try {
        Add-Type -TypeDefinition $win32Definition -ErrorAction Stop
        Write-Host "Win32 interop type $global:Win32Type loaded successfully."
    } catch {
        Write-Warning "Win32 type could not be loaded: $($_.Exception.Message)"
    }
} else {
    Write-Host "Win32 interop type $global:Win32Type already defined."
}

# Function to check clipboard lock
function Get-ClipboardOwner {
    if (-not ([Type]::GetType($global:Win32Type))) {
        Write-Warning "Unable to find type [$global:Win32Type]."
        return $null
    }

    try {
        $hWnd = [Win32Interop]::GetOpenClipboardWindow()
        if ($hWnd -eq [IntPtr]::Zero) { return $null }

        [uint32]$pid = 0
        [Win32Interop]::GetWindowThreadProcessId($hWnd, [ref]$pid) | Out-Null

        $sb = New-Object System.Text.StringBuilder 256
        [Win32Interop]::GetWindowText($hWnd, $sb, $sb.Capacity) | Out-Null

        $ownerName = $sb.ToString()
        return @{ PID = $pid; Name = $ownerName }
    } catch {
        Write-Warning "Clipboard lock detection error: $($_.Exception.Message)"
        return $null
    }
}

# Main monitoring loop
Write-Host "Enhanced clipboard monitoring with RustDesk correlation..."
Write-Host "Press Ctrl+C to stop monitoring..."

while ($true) {
    # Basic clipboard read test
    try {
        $clip = Get-Clipboard -ErrorAction Stop
        Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard read OK"
    } catch {
        Write-Warning "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard read failed: $($_.Exception.Message)"
    }

    # Check clipboard lock
    $owner = Get-ClipboardOwner
    if ($owner) {
        # Get all RustDesk processes
        $rustDeskProcesses = Get-Process | Where-Object { $_.Name -eq "RustDesk" }

        $matchingProcess = $rustDeskProcesses | Where-Object { $_.Id -eq $owner.PID }
        if ($matchingProcess) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard currently locked by window: $($owner.Name) | PID: $($owner.PID)"
        } else {
            Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') Clipboard currently locked by unknown process PID $($owner.PID)"
        }
    }

    # Check RustDesk processes
    $allRustDesk = Get-Process | Where-Object { $_.Name -eq "RustDesk" }
    if (-not $allRustDesk) {
        Write-Warning "$(Get-Date -Format 'HH:mm:ss.fff') RustDesk process not found! Possible crash/restart."
    } else {
        foreach ($p in $allRustDesk) {
            Write-Host "$(Get-Date -Format 'HH:mm:ss.fff') RustDesk process running: $($p.Name) | PID: $($p.Id)"
        }
    }

    Start-Sleep -Seconds 1
}
