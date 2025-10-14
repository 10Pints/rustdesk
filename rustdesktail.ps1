# DetectClipboardHog.ps1
# Guaranteed timestamped console output + RustDesk correlation

# NOTE: this uses System.Console to print fully-evaluated timestamped lines.

Add-Type -AssemblyName System.Windows.Forms

# --- Helper for timestamp ---
function Get-TimeStamp {
    return (Get-Date).ToString("HH:mm:ss.fff")
}

# --- Win32 helper (clipboard owner lookup) ---
if (-not ("Win32Utils" -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32Utils
{
    [DllImport("user32.dll")] public static extern IntPtr GetClipboardOwner();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool OpenClipboard(IntPtr hWndNewOwner);
    [DllImport("user32.dll")] public static extern bool CloseClipboard();
    [DllImport("user32.dll")] public static extern bool EmptyClipboard();
}
"@
    [System.Console]::WriteLine("{0} Win32 type loaded", (Get-TimeStamp))
} else {
    [System.Console]::WriteLine("{0} Win32 type already loaded - validating methods", (Get-TimeStamp))
}

# --- Test reading clipboard safely ---
function Test-Clipboard {
    try {
        # Using Windows.Forms clipboard reading - this may throw on locked clipboard
        [void][System.Windows.Forms.Clipboard]::GetText()
        return $true
    } catch {
        return $false
    }
}

# --- Determine which process currently "owns" clipboard ---
function Get-ClipboardLockingProcess {
    try {
        $ownerHwnd = [Win32Utils]::GetClipboardOwner()
        if ($ownerHwnd -eq [IntPtr]::Zero) { return $null }

        [uint32]$pid = 0
        [Win32Utils]::GetWindowThreadProcessId($ownerHwnd, [ref]$pid) | Out-Null
        if ($pid -eq 0) { return $null }

        try {
            $proc = Get-Process -Id $pid -ErrorAction Stop
            return "$($proc.ProcessName) (PID $pid)"
        } catch {
            return "Unknown (PID $pid)"
        }
    } catch {
        return $null
    }
}

# --- Logging paths ---
$rustdeskLog = "C:\Users\Terry\AppData\Roaming\RustDesk\log\cm\RustDesk_rCURRENT.log"
$internalLogDir = "C:\rustdesk-server\logs"
if (-not (Test-Path $internalLogDir)) { New-Item -ItemType Directory -Path $internalLogDir -Force | Out-Null }
$internalLog = Join-Path $internalLogDir "clipboard_hog.log"

# Write startup lines (timestamped, guaranteed)
[System.Console]::WriteLine("{0} Enhanced clipboard monitoring with RustDesk correlation...", (Get-TimeStamp))
[System.Console]::WriteLine("{0} Press Ctrl+C to stop monitoring...", (Get-TimeStamp))
[System.Console]::WriteLine("{0} Testing clipboard detection...", (Get-TimeStamp))

# Track last-read line count for RustDesk file
$lastLogLineCount = 0
if (Test-Path $rustdeskLog) {
    $lastLogLineCount = (Get-Content $rustdeskLog -ErrorAction SilentlyContinue).Count
    [System.Console]::WriteLine("{0} Watching RustDesk log for clipboard errors: {1}", (Get-TimeStamp), $rustdeskLog)
} else {
    [System.Console]::WriteLine("{0} RustDesk log not present at: {1}", (Get-TimeStamp), $rustdeskLog)
}

# --- Main loop ---
while ($true) {
    $ts = Get-TimeStamp
[System.Console]::WriteLine("[{0}] Terry test", $ts)
    # Clipboard quick test
    if (Test-Clipboard) {
        [System.Console]::WriteLine("{0} Clipboard read OK", $ts)
        # also append to internal log for persistent record
        "{0} Clipboard read OK" -f $ts | Out-File -FilePath $internalLog -Append -Encoding UTF8
    } else {
        [System.Console]::WriteLine("{0} ⚠ Clipboard read FAILED - attempting to detect locker...", $ts)
        "{0} CLIPBOARD_READ_FAILED" -f $ts | Out-File -FilePath $internalLog -Append -Encoding UTF8

        $locker = Get-ClipboardLockingProcess
        if ($locker) {
            [System.Console]::WriteLine("{0} Clipboard currently locked by: {1}", $ts, $locker)
            "{0} Clipboard locked by: {1}" -f $ts, $locker | Out-File -FilePath $internalLog -Append -Encoding UTF8
        } else {
            [System.Console]::WriteLine("{0} Clipboard locked but process unknown", $ts)
            "{0} Clipboard locked but process unknown" -f $ts | Out-File -FilePath $internalLog -Append -Encoding UTF8
        }
    }

    # --- Tail the RustDesk log for new lines (non-blocking read of entire file is fine here) ---
    if (Test-Path $rustdeskLog) {
        try {
            $allLines = Get-Content $rustdeskLog -ErrorAction Stop
            if ($allLines.Count -gt $lastLogLineCount) {
                $newLines = $allLines[$lastLogLineCount..($allLines.Count - 1)]
                foreach ($ln in $newLines) {
                    # Match the common error fragments you showed
                    if ($ln -match "ClipboardOccupied" -or $ln -match "Error reading HTML from clipboard" -or $ln -match "failed to read clipboard") {
                        $mark = Get-TimeStamp
                        [System.Console]::WriteLine("{0} ⚠ RustDesk log error detected:", $mark)
                        [System.Console]::WriteLine("→ {0}", $ln)
                        # Immediately attempt to find locking process as close to the event as possible
                        $owner = Get-ClipboardLockingProcess
                        if ($owner) {
                            [System.Console]::WriteLine("{0} => Owner at detection: {1}", $mark, $owner)
                            "{0} RUSTDESK_TRIGGER -> Owner: {1} | Log: {2}" -f $mark, $owner, ($ln -replace "`r?`n"," ") | Out-File -FilePath $internalLog -Append -Encoding UTF8
                        } else {
                            [System.Console]::WriteLine("{0} => No owner found at detection time", $mark)
                            "{0} RUSTDESK_TRIGGER -> No owner found | Log: {1}" -f $mark, ($ln -replace "`r?`n"," ") | Out-File -FilePath $internalLog -Append -Encoding UTF8
                        }
                    }
                }
                $lastLogLineCount = $allLines.Count
            }
        } catch {
            [System.Console]::WriteLine("{0} Error reading RustDesk log: {1}", (Get-TimeStamp), $_.Exception.Message)
        }
    }

    Start-Sleep -Milliseconds 500
}
