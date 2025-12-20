# YouTube Download Test Script
# Run this while testing the download feature

param(
    [string]$VideoId = "xqJVFc5MuGo",
    [int]$MonitorInterval = 1
)

Write-Host @"
╔════════════════════════════════════════════════════════════╗
║      YouTube Download Comprehensive Test Monitor          ║
╚════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Host "`nVideo ID: $VideoId" -ForegroundColor Yellow
Write-Host "Monitor Interval: ${MonitorInterval}s`n" -ForegroundColor Yellow

# Configuration
$downloadPath = "/storage/emulated/0/Android/data/com.example.mizz/files/Mizz songs"
$logFile = "download_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Start logging
"Test started: $(Get-Date)" | Out-File $logFile

# Check ADB connection
Write-Host "[1/5] Checking ADB connection..." -ForegroundColor Cyan
$devices = adb devices
if ($devices -match "device$") {
    Write-Host "✅ Device connected" -ForegroundColor Green
} else {
    Write-Host "❌ No device connected!" -ForegroundColor Red
    exit 1
}

# Check storage
Write-Host "`n[2/5] Checking storage space..." -ForegroundColor Cyan
$storage = adb shell "df -h /storage/emulated/0 | tail -1"
Write-Host $storage -ForegroundColor White
$storage | Out-File $logFile -Append

# Check download directory
Write-Host "`n[3/5] Checking download directory..." -ForegroundColor Cyan
$dirCheck = adb shell "ls -ld '$downloadPath' 2>&1"
if ($dirCheck -match "Permission denied" -or $dirCheck -match "No such file") {
    Write-Host "⚠️  Directory issue: $dirCheck" -ForegroundColor Yellow
} else {
    Write-Host "✅ Directory accessible" -ForegroundColor Green
    Write-Host $dirCheck -ForegroundColor White
}

# List existing files
Write-Host "`n[4/5] Existing files in download directory..." -ForegroundColor Cyan
$existingFiles = adb shell "ls -lh '$downloadPath/' 2>&1"
Write-Host $existingFiles -ForegroundColor White

# Clear logcat
Write-Host "`n[5/5] Clearing logcat and starting monitor..." -ForegroundColor Cyan
adb logcat -c

Write-Host @"

╔════════════════════════════════════════════════════════════╗
║                  MONITORING STARTED                        ║
║  Press Ctrl+C to stop                                      ║
╚════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

# Start monitoring in background jobs
$logJob = Start-Job -ScriptBlock {
    param($logFile)
    adb logcat -v time flutter:I *:S | Tee-Object -FilePath $logFile -Append
} -ArgumentList $logFile

Write-Host "📋 Flutter logs being saved to: $logFile`n" -ForegroundColor Yellow

# Initialize tracking variables
$lastSize = 0
$lastTime = Get-Date
$startTime = Get-Date
$stuckCount = 0
$peakSpeed = 0
$dataPoints = @()

try {
    while ($true) {
        Clear-Host
        
        $currentTime = Get-Date
        $elapsed = ($currentTime - $startTime).TotalSeconds
        
        Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║           DOWNLOAD MONITOR - $(Get-Date -Format 'HH:mm:ss')                 ║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        # Get file info
        $filePattern = "${VideoId}*.opus"
        $fileInfo = adb shell "ls -l '$downloadPath/$filePattern' 2>/dev/null | tail -1"
        
        if ($fileInfo -and $fileInfo -match '(\d+)\s+\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}\s+(.+)$') {
            $currentSize = [int64]$matches[1]
            $fileName = $matches[2]
            
            # Calculate metrics
            $sizeMB = [math]::Round($currentSize / 1024 / 1024, 3)
            $growth = $currentSize - $lastSize
            $timeDiff = ($currentTime - $lastTime).TotalSeconds
            
            if ($timeDiff -gt 0) {
                $speed = [math]::Round($growth / $timeDiff / 1024, 2)  # KB/s
                if ($speed -gt $peakSpeed) { $peakSpeed = $speed }
            } else {
                $speed = 0
            }
            
            $avgSpeed = if ($elapsed -gt 0) { [math]::Round($currentSize / $elapsed / 1024, 2) } else { 0 }
            
            # Track data points
            $dataPoints += @{
                Time = $elapsed
                Size = $currentSize
                Speed = $speed
            }
            
            # Display file info
            Write-Host "📄 FILE INFORMATION" -ForegroundColor Yellow
            Write-Host "   Name: $fileName" -ForegroundColor White
            Write-Host "   Size: $sizeMB MB ($currentSize bytes)" -ForegroundColor White
            Write-Host ""
            
            # Display download progress
            Write-Host "📊 DOWNLOAD METRICS" -ForegroundColor Yellow
            Write-Host "   Current Speed: $speed KB/s" -ForegroundColor $(if ($speed -gt 50) {"Green"} elseif ($speed -gt 10) {"Yellow"} else {"Red"})
            Write-Host "   Average Speed: $avgSpeed KB/s" -ForegroundColor White
            Write-Host "   Peak Speed: $peakSpeed KB/s" -ForegroundColor White
            Write-Host "   Growth: +$growth bytes" -ForegroundColor $(if ($growth -gt 0) {"Green"} else {"Red"})
            Write-Host "   Elapsed Time: $([math]::Round($elapsed, 1))s" -ForegroundColor White
            Write-Host ""
            
            # Detect issues
            if ($growth -eq 0) {
                $stuckCount++
                Write-Host "⚠️  WARNING: No growth detected!" -ForegroundColor Red
                Write-Host "   Stuck count: $stuckCount" -ForegroundColor Red
                
                if ($stuckCount -ge 5) {
                    Write-Host ""
                    Write-Host "❌ DOWNLOAD APPEARS FROZEN!" -ForegroundColor Red
                    Write-Host "   File size hasn't changed for $($stuckCount * $MonitorInterval) seconds" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "   Checking process status..." -ForegroundColor Yellow
                    
                    # Check if app is still running
                    $processes = adb shell "ps | grep com.example.mizz"
                    if ($processes) {
                        Write-Host "   ✅ App is still running" -ForegroundColor Green
                    } else {
                        Write-Host "   ❌ App not found in process list!" -ForegroundColor Red
                    }
                }
            } else {
                $stuckCount = 0
                Write-Host "✅ Download progressing normally" -ForegroundColor Green
            }
            
            # Estimate completion (if we have average speed)
            if ($avgSpeed -gt 0 -and $sizeMB -lt 10) {
                $estimatedTotal = 1  # Assume 1MB for small files
                $remaining = ($estimatedTotal - $sizeMB) * 1024 / $avgSpeed
                if ($remaining -gt 0 -and $remaining -lt 300) {
                    Write-Host "   ETA: $([math]::Round($remaining, 1))s" -ForegroundColor Cyan
                }
            }
            
            $lastSize = $currentSize
            $lastTime = $currentTime
            
        } else {
            Write-Host "⏳ Waiting for download to start..." -ForegroundColor Yellow
            Write-Host "   Looking for: $downloadPath/$filePattern" -ForegroundColor Gray
            Write-Host ""
            Write-Host "   Elapsed: $([math]::Round($elapsed, 1))s" -ForegroundColor White
            
            if ($elapsed -gt 30) {
                Write-Host ""
                Write-Host "⚠️  Download hasn't started after 30 seconds!" -ForegroundColor Red
                Write-Host "   Check logs for errors" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
        Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
        Write-Host "📋 RECENT FLUTTER LOGS (Last 5 lines):" -ForegroundColor Yellow
        Write-Host ""
        
        # Show recent logs
        if (Test-Path $logFile) {
            Get-Content $logFile -Tail 5 | ForEach-Object {
                if ($_ -match '✅') {
                    Write-Host $_ -ForegroundColor Green
                } elseif ($_ -match '❌') {
                    Write-Host $_ -ForegroundColor Red
                } elseif ($_ -match '⚠️') {
                    Write-Host $_ -ForegroundColor Yellow
                } elseif ($_ -match '📊') {
                    Write-Host $_ -ForegroundColor Cyan
                } else {
                    Write-Host $_ -ForegroundColor White
                }
            }
        }
        
        Write-Host ""
        Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
        
        Start-Sleep -Seconds $MonitorInterval
    }
} finally {
    # Cleanup
    Write-Host "`n`n📊 Generating summary report..." -ForegroundColor Cyan
    
    if ($dataPoints.Count -gt 0) {
        $totalGrowth = $dataPoints[-1].Size
        $totalTime = $dataPoints[-1].Time
        $avgSpeed = if ($totalTime -gt 0) { [math]::Round($totalGrowth / $totalTime / 1024, 2) } else { 0 }
        
        Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                    TEST SUMMARY                            ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Total Downloaded: $([math]::Round($totalGrowth / 1024 / 1024, 2)) MB" -ForegroundColor White
        Write-Host "Total Time: $([math]::Round($totalTime, 1))s" -ForegroundColor White
        Write-Host "Average Speed: $avgSpeed KB/s" -ForegroundColor White
        Write-Host "Peak Speed: $peakSpeed KB/s" -ForegroundColor White
        Write-Host "Data Points: $($dataPoints.Count)" -ForegroundColor White
        Write-Host ""
        Write-Host "📋 Full logs saved to: $logFile" -ForegroundColor Yellow
    }
    
    Stop-Job $logJob
    Remove-Job $logJob
    
    Write-Host "`n✅ Monitoring stopped" -ForegroundColor Green
}
