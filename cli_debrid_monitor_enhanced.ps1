# ==========================
# CONFIG
# ==========================

# URL that stops working when cli_debrid is hung
$Url = "http://localhost:40000/auth/login" # Put your specific cli_debrid URL, your port may be different

# Full path to cli_debrid.exe
$ExePath = "C:\YOUR FILE LOCATION\cli_debrid.exe"
$WorkingDir = Split-Path $ExePath

# Discord webhook URL
$DiscordWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

# Enable/Disable Discord notifications (set to $false to disable all Discord notifications)
$EnableDiscordNotifications = $true

# How often to check (seconds)
$IntervalSeconds = 600

# How many failed checks in a row before we restart
$FailuresBeforeRestart = 3

# Fast check mode (after first failure detected)
$EnableFastCheckAfterFailure = $true    # Set to $false to disable
$FastCheckIntervalSeconds = 60           # Check every 60 seconds after first failure
$FastCheckFailuresBeforeRestart = 3      # Total failures needed (includes first failure)

# Max restarts allowed per rolling hour
$MaxRestartsPerHour = 2

# Time to wait after restart before health check (seconds)
$PostRestartWaitTime = 30

# Timeout for post-restart health verification (seconds)
$PostRestartTimeout = 60

# Memory threshold in MB (restart if exceeded)
$MaxMemoryMB = 1024

# CPU threshold percentage (restart if exceeded for multiple checks)
$MaxCPUPercent = 80
$CPUCheckCount = 3  # How many consecutive high CPU readings before restart

# Response time threshold in milliseconds (warn if exceeded)
$ResponseTimeWarningMs = 5000

# Enable verbose Discord notifications (startup, every health check pass, etc.)
$VerboseDiscordNotifications = $false

# Show routine health check output (set to $true to see every check, $false for quiet mode)
$ShowRoutineHealthChecks = $false

# Send hourly heartbeat notification to Discord
$SendHourlyHeartbeat = $true

# Log file and diagnostics (in the script's current directory)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}
$LogFile = Join-Path $ScriptDir "cli_debrid_monitor.log"
$DiagnosticFolder = Join-Path $ScriptDir "diagnostics"

$ErrorActionPreference = "Stop"
$failureCount = 0
$highCPUCount = 0

# Track timestamps of restarts for rate limiting
$script:restartTimestamps = @()

# Script uptime tracking (not cli_debrid process uptime)
$script:monitorStartTime = Get-Date
$script:totalRestarts = 0
$script:totalDowntime = [TimeSpan]::Zero

# Response time tracking
$script:responseTimes = @()
$script:slowResponseCount = 0

# Hourly heartbeat tracking
$script:lastHeartbeatTime = Get-Date

# Status update counter (show "still monitoring" message every 10 checks)
$script:checkCounter = 0

# Fast check mode tracking
$script:inFastCheckMode = $false

# ==========================
# COUNTDOWN FUNCTION
# ==========================

function Show-Countdown {
    param(
        [int]$Seconds, 
        [string]$Message = "Next check in"
    )
    
    $endTime = (Get-Date).AddSeconds($Seconds)
    
    while ((Get-Date) -lt $endTime) {
        $remaining = ($endTime - (Get-Date))
        $minutes = [int][math]::Floor($remaining.TotalMinutes)
        $seconds = [int]$remaining.Seconds
        
        Write-Host ("`r💤 {0}: {1:D2}:{2:D2}   " -f $Message, $minutes, $seconds) -NoNewline -ForegroundColor DarkCyan
        Start-Sleep -Seconds 1
    }
    
    # Clear the countdown line
    Write-Host "`r" -NoNewline
    Write-Host (" " * 80) -NoNewline
    Write-Host "`r" -NoNewline
}

function Write-BoxLine {
    param(
        [string]$Content,
        [int]$Width = 59,   # TOTAL width including borders (matches your ╔══...╗ line)
        [ConsoleColor]$BorderColor = 'DarkCyan',
        [ConsoleColor]$TextColor = 'White'
    )
    $leftBorder  = "║"
    $rightBorder = "║"
    # One space after the left border
    $text = " " + $Content
    # Calculate display width of the visible text (emoji-aware)
    $displayWidth = 0
    foreach ($char in $text.ToCharArray()) {
        $code = [int][char]$char
        # Zero-width / modifiers: count as 0
        if ($code -in 0x200B,0x200C,0x200D,0xFE0F) {
            continue
        }
        # Wide characters (emoji & symbols)
        elseif (
            ($code -ge 0x1F300 -and $code -le 0x1FAFF)  -or  # emoji blocks
            ($code -ge 0x2300 -and $code -le 0x23FF)   -or  # ⏰ and other misc technical symbols
            ($code -ge 0x2600 -and $code -le 0x26FF)   -or  # misc symbols
            ($code -ge 0x2700 -and $code -le 0x27BF)        # dingbats
        ) {
            $displayWidth += 2
        }
        else {
            $displayWidth += 1
        }
    }
    $innerWidth = $Width - 2                # space between the borders
    $padding    = $innerWidth - $displayWidth
    if ($padding -lt 0) { $padding = 0 }
    Write-Host $leftBorder -NoNewline -ForegroundColor $BorderColor
    Write-Host $text      -NoNewline -ForegroundColor $TextColor
    Write-Host (" " * $padding) -NoNewline
    Write-Host $rightBorder -ForegroundColor $BorderColor
}

# ==========================
# HELPERS
# ==========================

# Ensure directories exist
if (-not (Test-Path $ScriptDir)) {
    New-Item -Path $ScriptDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $DiagnosticFolder)) {
    New-Item -Path $DiagnosticFolder -ItemType Directory -Force | Out-Null
}

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "Info"  # Info, Success, Warning, Error
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Write to log file
    "$timestamp`t$Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
    
    # Write to console with colors
    $color = switch ($Level) {
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Info" { "Cyan" }
        default { "White" }
    }
    
    # Detect emoji/icon in message for auto-coloring
    if ($Message -match "^✅") { $color = "Green" }
    elseif ($Message -match "^⚠️") { $color = "Yellow" }
    elseif ($Message -match "^❌") { $color = "Red" }
    elseif ($Message -match "^🔄") { $color = "Cyan" }
    elseif ($Message -match "^📊|^💾") { $color = "Magenta" }
    elseif ($Message -match "^=") { $color = "DarkCyan" }
    elseif ($Message -match "Health check:") { $color = "Gray" }
    elseif ($Message -match "Process health") { $color = "Gray" }
    elseif ($Message -match "CPU:") { $color = "Gray" }
    
    # Skip console output for routine health checks if ShowRoutineHealthChecks is false
    $isRoutineHealthCheck = $Message -match "Health check:" -or $Message -match "Process health" -or $Message -match "^CPU:"
    
    if (-not $isRoutineHealthCheck -or $ShowRoutineHealthChecks) {
        Write-Host "$timestamp`t" -NoNewline -ForegroundColor DarkGray
        Write-Host $Message -ForegroundColor $color
    }
}

function Send-DiscordNotification {
    param(
        [string]$Message,
        [string]$Color = "3447003",  # Default blue color
        [int]$MaxRetries = 3,
        [string]$NotificationType = ""  # Optional description of notification type
    )

    # Check if Discord notifications are enabled
    if (-not $EnableDiscordNotifications) {
        return
    }

    $payload = @{
        embeds = @(
            @{
                title = "cli_debrid Monitor"
                description = $Message
                color = [int]$Color
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                footer = @{
                    text = $env:COMPUTERNAME
                }
            }
        )
    } | ConvertTo-Json -Depth 4 -Compress

    $attempt = 0
    $success = $false

    while ($attempt -lt $MaxRetries -and -not $success) {
        $attempt++
        try {
            $response = Invoke-RestMethod -Uri $DiscordWebhook -Method Post -Body $payload -ContentType "application/json; charset=utf-8" -TimeoutSec 10
            
            # Log what was sent instead of generic message
            if ($NotificationType) {
                Write-Log "📤 $NotificationType sent to Discord"
            } else {
                # Extract first line of message for logging
                $firstLine = ($Message -split "`n")[0] -replace '\*\*', '' -replace '^\s+', ''
                Write-Log "📤 Discord: $firstLine"
            }
            
            $success = $true
        }
        catch {
            $errorMsg = $_.Exception.Message
            
            if ($attempt -lt $MaxRetries) {
                Write-Log "Failed to send Discord notification (attempt $attempt/$MaxRetries): $errorMsg - Retrying in 5 seconds..."
                Start-Sleep -Seconds 5
            }
            else {
                Write-Log "Failed to send Discord notification after $MaxRetries attempts: $errorMsg"
                if ($_.Exception.Response) {
                    try {
                        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                        $responseBody = $reader.ReadToEnd()
                        Write-Log "Discord API Response: $responseBody"
                    }
                    catch {
                        # Ignore errors reading response
                    }
                }
            }
        }
    }
    
    return $success
}

function Test-AppHealth {
    param([string]$TestUrl)

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $response = Invoke-WebRequest -Uri $TestUrl -UseBasicParsing -TimeoutSec 10
        $stopwatch.Stop()
        $responseTime = $stopwatch.ElapsedMilliseconds
        
        # Track response time
        $script:responseTimes += $responseTime
        if ($script:responseTimes.Count -gt 100) {
            $script:responseTimes = $script:responseTimes[-100..-1]  # Keep last 100
        }
        
        # Always convert to seconds for display
        $responseSeconds = [math]::Round($responseTime / 1000, 2)
        $displayTime = "${responseSeconds}s"
        
        # Log slow responses
        if ($responseTime -gt $ResponseTimeWarningMs) {
            $script:slowResponseCount++
            $warningSeconds = [math]::Round($ResponseTimeWarningMs / 1000, 1)
            Write-Log "⚠️ SLOW RESPONSE: Health check took $displayTime (threshold: ${warningSeconds}s)" "Warning"
            
            if ($script:slowResponseCount -ge 3) {
                $responseSeconds = [math]::Round($responseTime / 1000, 1)
                $thresholdSeconds = [math]::Round($ResponseTimeWarningMs / 1000, 1)
                Send-DiscordNotification -Message "⚠️ **Performance Degradation Detected**`n`nHealth checks are consistently slow:`n- Current: ${responseSeconds}s`n- Threshold: ${thresholdSeconds}s`n- Slow responses: $($script:slowResponseCount) in a row`n`nThis may indicate cli_debrid is struggling." -Color "16776960" -NotificationType "⚠️ Slow response warning"
                $script:slowResponseCount = 0
            }
        }
        else {
            $script:slowResponseCount = 0  # Reset counter on normal response
        }
        
        Write-Log "Health check: $displayTime"
        
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            return $true
        }
        else {
            Write-Log "Health check failed: HTTP $($response.StatusCode)"
            return $false
        }
    }
    catch {
        $stopwatch.Stop()
        Write-Log "Health check error: $($_.Exception.Message)"
        return $false
    }
}

function Test-ProcessHealth {
    try {
        $proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue
        if (-not $proc) {
            Write-Log "❌ cli_debrid process not running!"
            return $false
        }
        
        # If multiple processes, use the first one (this is normal for cli_debrid)
        if ($proc -is [array]) {
            $proc = $proc[0]
        }
        
        # Check memory usage (in MB)
        $memoryMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
        Write-Log "Process health - Memory: ${memoryMB}MB"
        
        if ($memoryMB -gt $MaxMemoryMB) {
            Write-Log "⚠️ MEMORY THRESHOLD EXCEEDED: ${memoryMB}MB (limit: ${MaxMemoryMB}MB)"
            Send-DiscordNotification -Message "⚠️ **High Memory Usage Detected**`n`nMemory: ${memoryMB}MB`nThreshold: ${MaxMemoryMB}MB`n`nRestarting cli_debrid..." -Color "16776960" -NotificationType "⚠️ High memory warning"
            return $false
        }
        
        # Check CPU usage (requires a bit of calculation)
        # Note: CPU property is cumulative, so we need to track delta
        if ($null -ne $script:lastCPUTime) {
            $cpuDelta = $proc.CPU - $script:lastCPUTime
            $timeDelta = ((Get-Date) - $script:lastCPUCheck).TotalSeconds
            
            if ($timeDelta -gt 0) {
                $cpuPercent = [math]::Round(($cpuDelta / $timeDelta) * 100, 1)
                Write-Log "CPU: ${cpuPercent}%"
                
                if ($cpuPercent -gt $MaxCPUPercent) {
                    $script:highCPUCount++
                    Write-Log "⚠️ HIGH CPU: ${cpuPercent}% (threshold: ${MaxCPUPercent}%, count: $script:highCPUCount/$CPUCheckCount)" "Warning"
                    
                    if ($script:highCPUCount -ge $CPUCheckCount) {
                        Write-Log "❌ CPU threshold exceeded $CPUCheckCount times consecutively" "Error"
                        Send-DiscordNotification -Message "⚠️ **High CPU Usage Detected**`n`nCPU: ${cpuPercent}%`nThreshold: ${MaxCPUPercent}%`nConsecutive high readings: $script:highCPUCount`n`nRestarting cli_debrid..." -Color "16776960" -NotificationType "⚠️ High CPU warning"
                        $script:highCPUCount = 0
                        return $false
                    }
                }
                else {
                    $script:highCPUCount = 0  # Reset counter
                }
            }
        }
        
        $script:lastCPUTime = $proc.CPU
        $script:lastCPUCheck = Get-Date
        
        return $true
    }
    catch {
        Write-Log "Error checking process health: $($_.Exception.Message)"
        return $true  # Don't trigger restart on monitoring errors
    }
}

function Save-DiagnosticInfo {
    param([string]$Reason = "Health check failure")
    
    try {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $diagFile = Join-Path $DiagnosticFolder "diagnostic_${timestamp}.txt"
        
        Write-Log "Saving diagnostic information to: $diagFile"
        
        "=" * 80 | Out-File $diagFile
        "cli_debrid Diagnostic Report" | Out-File $diagFile -Append
        "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $diagFile -Append
        "Reason: $Reason" | Out-File $diagFile -Append
        "=" * 80 | Out-File $diagFile -Append
        "" | Out-File $diagFile -Append
        
        # Process information
        "PROCESS INFORMATION:" | Out-File $diagFile -Append
        "-" * 80 | Out-File $diagFile -Append
        $proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue
        if ($proc) {
            # Handle multiple processes
            if ($proc -is [array]) {
                "Multiple processes detected: $($proc.Count) (This is normal - cli_debrid architecture)" | Out-File $diagFile -Append
                "  - Process 1: Main Python interpreter running main.py" | Out-File $diagFile -Append
                "  - Process 2: Flask web server (threading/WSGI)" | Out-File $diagFile -Append
                "  - Process 3: Metadata battery service (port 5001)" | Out-File $diagFile -Append
                "" | Out-File $diagFile -Append
                foreach ($p in $proc) {
                    "Process ID: $($p.Id)" | Out-File $diagFile -Append
                    "Memory Usage: $([math]::Round($p.WorkingSet64 / 1MB, 2))MB" | Out-File $diagFile -Append
                    "Thread Count: $($p.Threads.Count)" | Out-File $diagFile -Append
                    "Handle Count: $($p.HandleCount)" | Out-File $diagFile -Append
                    "" | Out-File $diagFile -Append
                }
            } else {
                $proc | Format-List * | Out-File $diagFile -Append
                "" | Out-File $diagFile -Append
                "Memory Usage: $([math]::Round($proc.WorkingSet64 / 1MB, 2))MB" | Out-File $diagFile -Append
                "Thread Count: $($proc.Threads.Count)" | Out-File $diagFile -Append
                "Handle Count: $($proc.HandleCount)" | Out-File $diagFile -Append
            }
        }
        else {
            "Process not running" | Out-File $diagFile -Append
        }
        "" | Out-File $diagFile -Append
        
        # Network connections
        "NETWORK CONNECTIONS (Port 40000):" | Out-File $diagFile -Append
        "-" * 80 | Out-File $diagFile -Append
        Get-NetTCPConnection -LocalPort 40000 -ErrorAction SilentlyContinue | 
            Format-Table -AutoSize | Out-File $diagFile -Append
        "" | Out-File $diagFile -Append
        
        # Response time statistics
        "RESPONSE TIME STATISTICS:" | Out-File $diagFile -Append
        "-" * 80 | Out-File $diagFile -Append
        if ($script:responseTimes.Count -gt 0) {
            $avgResponse = [math]::Round(($script:responseTimes | Measure-Object -Average).Average / 1000, 2)
            $minResponse = [math]::Round((($script:responseTimes | Measure-Object -Minimum).Minimum) / 1000, 2)
            $maxResponse = [math]::Round((($script:responseTimes | Measure-Object -Maximum).Maximum) / 1000, 2)
            
            "Sample Size: $($script:responseTimes.Count)" | Out-File $diagFile -Append
            "Average: ${avgResponse}s" | Out-File $diagFile -Append
            "Minimum: ${minResponse}s" | Out-File $diagFile -Append
            "Maximum: ${maxResponse}s" | Out-File $diagFile -Append
        }
        else {
            "No response time data available" | Out-File $diagFile -Append
        }
        "" | Out-File $diagFile -Append
        
        # System information
        "SYSTEM INFORMATION:" | Out-File $diagFile -Append
        "-" * 80 | Out-File $diagFile -Append
        "Computer: $env:COMPUTERNAME" | Out-File $diagFile -Append
        "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)" | Out-File $diagFile -Append
        "Memory Total: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2))GB" | Out-File $diagFile -Append
        "" | Out-File $diagFile -Append
        
        # Recent log entries
        "RECENT LOG ENTRIES (Last 50 lines):" | Out-File $diagFile -Append
        "-" * 80 | Out-File $diagFile -Append
        if (Test-Path $LogFile) {
            Get-Content $LogFile -Tail 50 | Out-File $diagFile -Append
        }
        
        Write-Log "Diagnostic information saved successfully."
        
        # Clean up old diagnostic files (keep last 30)
        $oldDiags = Get-ChildItem $DiagnosticFolder -Filter "diagnostic_*.txt" | 
                    Sort-Object LastWriteTime -Descending | 
                    Select-Object -Skip 30
        if ($oldDiags) {
            $oldDiags | Remove-Item -Force
            Write-Log "Cleaned up $($oldDiags.Count) old diagnostic file(s)."
        }
    }
    catch {
        Write-Log "Failed to save diagnostic information: $($_.Exception.Message)"
    }
}

function Send-HourlyHeartbeat {
    if (-not $SendHourlyHeartbeat) { return }
    
    $now = Get-Date
    $timeSinceLastHeartbeat = ($now - $script:lastHeartbeatTime).TotalMinutes
    
    # Send heartbeat every 60 minutes
    if ($timeSinceLastHeartbeat -ge 60) {
        $totalUptime = $now - $script:monitorStartTime
        
        $avgResponseTime = if ($script:responseTimes.Count -gt 0) {
            [math]::Round(($script:responseTimes | Measure-Object -Average).Average, 0)
        } else { 0 }
        
        # Always show in seconds
        $avgResponseDisplay = "$([math]::Round($avgResponseTime / 1000, 2))s"
        
        $proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue
        $memoryMB = if ($proc) {
            if ($proc -is [array]) { $proc = $proc[0] }
            [math]::Round($proc.WorkingSet64 / 1MB, 2)
        } else { 0 }
        
        $message = "💚 **Monitor Heartbeat**`n`n" +
                   "**Status:** All systems operational`n" +
                   "**Monitor Uptime:** $($totalUptime.ToString('d\.hh\:mm\:ss'))`n" +
                   "**Memory Usage:** ${memoryMB}MB`n" +
                   "**Avg Response:** $avgResponseDisplay`n" +
                   "**Restarts Today:** $($script:totalRestarts)"
        
        $success = Send-DiscordNotification -Message $message -Color "3066993"
        
        if ($success) {
            $script:lastHeartbeatTime = $now
            Write-Log "💚 Hourly heartbeat sent to Discord" "Success"
        }
    }
}

function Can-RestartNow {
    # Drop any restarts older than 1 hour
    $cutoff = (Get-Date).AddHours(-1)
    $script:restartTimestamps = $script:restartTimestamps | Where-Object { $_ -gt $cutoff }

    if ($script:restartTimestamps.Count -ge $MaxRestartsPerHour) {
        Write-Log "Restart skipped: max of $MaxRestartsPerHour restarts per hour reached. Current count (last hour): $($script:restartTimestamps.Count)."
        
        $monitorUptime = (Get-Date) - $script:monitorStartTime
        Send-DiscordNotification -Message "⚠️ **Restart Rate Limit Reached**`n`nCannot restart cli_debrid - already restarted $MaxRestartsPerHour times in the last hour.`n`n**Monitor Uptime:** $($monitorUptime.ToString('d\.hh\:mm\:ss'))`n**Total Restarts:** $($script:totalRestarts)`n`n**Manual intervention may be required!**" -Color "16776960" -NotificationType "⚠️ Restart rate limit reached" | Out-Null
        return $false
    }

    return $true
}

function Register-RestartTimestamp {
    $now = Get-Date
    # Use ArrayList or proper array addition
    $script:restartTimestamps = $script:restartTimestamps + $now
    # Recalculate count in last hour for logging
    $cutoff = $now.AddHours(-1)
    $recentCount = ($script:restartTimestamps | Where-Object { $_ -gt $cutoff }).Count
    Write-Log "Restart recorded at $now. Restarts in last hour (including this): $recentCount."
}

function Wait-ForHealthyState {
    param([int]$TimeoutSeconds = 60)
    
    Write-Log "Waiting up to $TimeoutSeconds seconds for cli_debrid to become healthy..."
    $elapsed = 0
    $checkInterval = 5
    
    while ($elapsed -lt $TimeoutSeconds) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        
        if (Test-AppHealth -TestUrl $Url) {
            Write-Log "✅ cli_debrid is now responsive! (took $elapsed seconds)"
            return $true
        }
        
        Write-Log "Still waiting for cli_debrid to respond... ($elapsed/$TimeoutSeconds seconds)"
    }
    
    Write-Log "❌ Timeout reached. cli_debrid did not become healthy within $TimeoutSeconds seconds."
    return $false
}

function Restart-CliDebrid {
    param([string]$Reason = "Health check failure")
    
    # Track downtime start
    $downtimeStart = Get-Date
    
    Write-Log "========================================="
    Write-Log "Restart condition met: $Reason"
    Write-Log "========================================="
    
    # Save diagnostic info before restart
    Save-DiagnosticInfo -Reason $Reason
    
    Send-DiscordNotification -Message "🔄 **Restarting cli_debrid**`n`n**Reason:** $Reason`n**Failed Checks:** $failureCount`n`nAttempting restart..." -Color "16753920" -NotificationType "🔄 Restart initiated" | Out-Null

    try {
        # Kill existing cli_debrid.exe
        $proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Log "Stopping existing cli_debrid.exe (PID(s): $($proc.Id -join ', '))..."
            $proc | Stop-Process -Force
            Write-Log "Process(es) terminated."
        }
        else {
            Write-Log "No existing cli_debrid.exe process found."
        }
    }
    catch {
        Write-Log "❌ Error while stopping cli_debrid: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 2

    try {
        Write-Log "Starting cli_debrid.exe from '$ExePath'..."
        Start-Process -FilePath $ExePath -WorkingDirectory $WorkingDir
        Write-Log "cli_debrid.exe started. Waiting $PostRestartWaitTime seconds before health check..."
        Start-Sleep -Seconds $PostRestartWaitTime
        
        # Verify the restart was successful
        if (Wait-ForHealthyState -TimeoutSeconds $PostRestartTimeout) {
            $downtimeEnd = Get-Date
            $downtime = $downtimeEnd - $downtimeStart
            $script:totalDowntime += $downtime
            
            Write-Log "✅ Restart successful! Downtime: $($downtime.ToString('mm\:ss'))"
            
            Send-DiscordNotification -Message "✅ **cli_debrid Restarted Successfully**`n`n**Downtime:** $($downtime.ToString('mm\:ss'))`n**Status:** Responding to health checks`n**Total Restarts Today:** $($script:totalRestarts + 1)" -Color "5763719" -NotificationType "✅ Restart successful" | Out-Null
        }
        else {
            Send-DiscordNotification -Message "❌ **cli_debrid Restart Failed**`n`nThe application was restarted but is still not responding to health checks after $PostRestartTimeout seconds.`n`n**Manual intervention required!**" -Color "15158332" -NotificationType "❌ Restart failed" | Out-Null
        }
        
        # Update tracking variables
        $script:totalRestarts++
    }
    catch {
        Write-Log "❌ Failed to start cli_debrid.exe: $($_.Exception.Message)"
        Send-DiscordNotification -Message "❌ **cli_debrid Start Failed**`n`nError: $($_.Exception.Message)`n`n**Manual intervention required!**" -Color "15158332" -NotificationType "❌ Start failed" | Out-Null
    }
}

# ==========================
# MAIN LOOP
# ==========================

# Initialize tracking variables
$script:lastCPUTime = $null
$script:lastCPUCheck = Get-Date

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-BoxLine -Content "cli_debrid Monitor - Enhanced Edition" -Width 62 -BorderColor Cyan -TextColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "========================================="
Write-Log "cli_debrid monitor started"
Write-Log "URL: $Url"
Write-Log "Check Interval: $([math]::Round($IntervalSeconds/60, 1)) minutes"
Write-Log "Failure Threshold: $FailuresBeforeRestart"
if ($EnableFastCheckAfterFailure) {
    Write-Log "Fast Check: Enabled (${FastCheckIntervalSeconds}s after first failure)"
} else {
    Write-Log "Fast Check: Disabled"
}
Write-Log "Max Restarts/Hour: $MaxRestartsPerHour"
Write-Log "Memory Threshold: ${MaxMemoryMB}MB"
Write-Log "CPU Threshold: ${MaxCPUPercent}%"
Write-Log "Response Time Warning: $([math]::Round($ResponseTimeWarningMs/1000, 1))s"
Write-Log "========================================="
Write-Host ""
Write-Host "🚀 Monitor is now running..." -ForegroundColor Green
Write-Host "   Press Ctrl+C to stop" -ForegroundColor DarkGray
Write-Host ""

Send-DiscordNotification -Message "🚀 **cli_debrid Monitor Started**`n`n**Configuration:**`n- URL: $Url`n- Check Interval: $([math]::Round($IntervalSeconds/60, 1)) minutes`n- Failure Threshold: $FailuresBeforeRestart`n- Max Restarts/Hour: $MaxRestartsPerHour`n- Memory Limit: ${MaxMemoryMB}MB`n- CPU Limit: ${MaxCPUPercent}%`n- Response Warning: $([math]::Round($ResponseTimeWarningMs/1000, 1))s" -Color "3447003" -NotificationType "🚀 Monitor startup" | Out-Null

while ($true) {
    # Check if it's time to send hourly heartbeat
    Send-HourlyHeartbeat
    
    # Perform health checks
    $script:checkCounter++
    
    # Show status update every 10 checks (100 minutes at 10 minute intervals)
    if ($script:checkCounter % 10 -eq 0) {
        $scriptUptime = (Get-Date) - $script:monitorStartTime
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $avgResponseMs = if ($script:responseTimes.Count -gt 0) { 
            [math]::Round(($script:responseTimes | Measure-Object -Average).Average, 0)
        } else { 0 }
        
        # Always show in seconds
        $avgResponseDisplay = "$([math]::Round($avgResponseMs / 1000, 2))s"
        
        Write-Host ""
        Write-Host "╔═════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
        Write-BoxLine -Content "📊 Status Update - Check #$script:checkCounter" -Width 59 -BorderColor DarkCyan -TextColor DarkCyan
        Write-BoxLine -Content "⏰ Current Time: $currentTime" -Width 59 -BorderColor DarkCyan -TextColor DarkCyan
        Write-Host "╠═════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
        Write-BoxLine -Content "Monitor Uptime: $($scriptUptime.ToString('d\.hh\:mm\:ss'))" -Width 59 -BorderColor DarkCyan -TextColor White
        Write-BoxLine -Content "Avg Response Time: $avgResponseDisplay" -Width 59 -BorderColor DarkCyan -TextColor White
        Write-BoxLine -Content "Total Restarts: $script:totalRestarts" -Width 59 -BorderColor DarkCyan -TextColor White
        Write-Host "╚═════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
        Write-Host ""
    }
    
    $isHealthy = Test-AppHealth -TestUrl $Url
    $processHealthy = Test-ProcessHealth

    if ($isHealthy -and $processHealthy) {
        if ($failureCount -gt 0) {
            Write-Log "✅ Health restored. Failure streak reset (was $failureCount)." "Success"
            if ($VerboseDiscordNotifications) {
                Send-DiscordNotification -Message "✅ Health check passed after $failureCount failure(s)." -Color "5763719" -NotificationType "✅ Health restored" | Out-Null
            }
        }
        $failureCount = 0
        
        # Exit fast check mode if we were in it
        if ($script:inFastCheckMode) {
            Write-Log "Exiting fast check mode - returning to normal interval" "Success"
            $script:inFastCheckMode = $false
        }
    }
    else {
        $failureCount++
        
        $failureReason = if (-not $isHealthy) { "URL health check failed" } else { "Process health check failed" }
        Write-Log "❌ $failureReason. Consecutive failures: $failureCount" "Error"
        
        # Enter fast check mode on first failure (if enabled)
        if ($failureCount -eq 1 -and $EnableFastCheckAfterFailure -and -not $script:inFastCheckMode) {
            $script:inFastCheckMode = $true
            Write-Log "⚡ Entering fast check mode - checking every ${FastCheckIntervalSeconds}s" "Warning"
        }
        
        # Determine which threshold to use
        $currentThreshold = if ($script:inFastCheckMode) { 
            $FastCheckFailuresBeforeRestart 
        } else { 
            $FailuresBeforeRestart 
        }

        if ($failureCount -ge $currentThreshold) {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host " RESTART THRESHOLD REACHED" -ForegroundColor Red
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
            Write-Host ""
            
            if (Can-RestartNow) {
                Restart-CliDebrid -Reason $failureReason
                Register-RestartTimestamp
                
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
                Write-Host " RESTART COMPLETE - RESUMING MONITORING" -ForegroundColor Green
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
                Write-Host ""
            }
            else {
                Write-Log "Restart NOT performed due to rate limit. Will continue monitoring." "Warning"
            }

            # Reset failure streak either way so we don't spam restart checks
            $failureCount = 0
            
            # Exit fast check mode after restart
            $script:inFastCheckMode = $false
        }
    }

    # Use fast check interval if in fast check mode, otherwise use normal interval
    $currentInterval = if ($script:inFastCheckMode) { 
        $FastCheckIntervalSeconds 
    } else { 
        $IntervalSeconds 
    }
    
    Show-Countdown -Seconds $currentInterval -Message "Next health check in"
}
