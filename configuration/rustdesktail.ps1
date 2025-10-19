#rustdesktail.ps1
# PowerShell script to tail RustDesk log files in real-time
param (
    [string]$logDir = "$env:APPDATA\RustDesk\log",
    [string[]]$subDirs = @("", "check-hwcodec-config", "cm", "install-service", "tray")
)

# Function to get log file paths
function Get-LogFiles {
    $logFiles = @()
    foreach ($subDir in $subDirs) {
        $fullPath = Join-Path $logDir $subDir
        if (Test-Path $fullPath) {
            $logFile = Join-Path $fullPath "RustDesk_rCURRENT.log"
            if (Test-Path $logFile) {
                $logFiles += $logFile
                Write-Host "Monitoring: $logFile" -ForegroundColor Cyan
            } else {
                Write-Host "Log file not found: $logFile" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Directory not found: $fullPath" -ForegroundColor Yellow
        }
    }
    return $logFiles
}

Write-Host "Starting rustdesktail.ps1" -ForegroundColor Green
$logFiles = Get-LogFiles
if ($logFiles.Count -eq 0) {
    Write-Host "No log files found to monitor. Exiting..." -ForegroundColor Red
    exit
}

Write-Host "Tailing all rustdesk_rCURRENT.log files: $($logFiles -join ', ')" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop..." -ForegroundColor Yellow

# Initialize last read positions
$lastPositions = @{}
foreach ($file in $logFiles) {
    $lastPositions[$file] = (Get-Item $file).Length
}

try {
    while ($true) {
        foreach ($file in $logFiles) {
            $currentLength = (Get-Item $file).Length
            if ($currentLength -gt $lastPositions[$file]) {
                $content = Get-Content $file -Tail ($currentLength - $lastPositions[$file]) -Encoding UTF8
                foreach ($line in $content) {
                    Write-Host "[$file] $line" -ForegroundColor White
                }
                $lastPositions[$file] = $currentLength
            }
        }
        Start-Sleep -Milliseconds 500  # Check every 0.5 seconds
    }
} catch {
    Write-Host "Monitoring interrupted: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "Stopped tailing logs." -ForegroundColor Green
}