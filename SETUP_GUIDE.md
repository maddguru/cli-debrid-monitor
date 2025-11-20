# cli_debrid Monitor - Setup Guide & Recommendations

## What's Included in the Enhanced Script

### ✅ Core Features

1. **Discord Webhook Notifications**
   - Sends alerts when cli_debrid becomes unresponsive
   - Confirms successful restarts with health check verification
   - Warns when rate limits are hit (requires manual intervention)
   - Startup notification when monitor begins
   - Color-coded messages (green=success, orange=warning, red=error)

2. **Memory & CPU Monitoring**
   - Automatically restarts if memory exceeds threshold (default: 1024MB)
   - Tracks CPU usage and restarts on sustained high usage
   - Prevents false positives with consecutive high reading requirements

3. **Response Time Tracking**
   - Measures how long each health check takes
   - Warns if responses are consistently slow (default: >5000ms)
   - Detects performance degradation before complete failure

4. **Diagnostic Data Collection**
   - Automatically saves detailed diagnostics when failures occur
   - Captures process info, network connections, response times, system state
   - Keeps last 30 diagnostic files, auto-deletes older ones

5. **Uptime Tracking & Statistics**
   - Tracks how long cli_debrid runs between restarts
   - Calculates total downtime
   - Logs uptime statistics with each restart

6. **Post-Restart Health Verification**
   - Waits 15 seconds after restart before checking
   - Monitors for up to 60 seconds to confirm cli_debrid is healthy
   - Sends success/failure notification based on results

7. **Rate Limiting (Cooldown)**
   - Maximum restarts per hour (default: 2)
   - Sends Discord alert when limit is reached
   - Prevents restart loops

### 🎛️ Configurable Options

At the top of the script, you can adjust:

```powershell
# === Health Check Settings ===
$IntervalSeconds = 30               # How often to check
$FailuresBeforeRestart = 3          # Consecutive failures before restart
$MaxRestartsPerHour = 2             # Maximum restarts in rolling 1-hour window

# === Restart Behavior ===
$PostRestartWaitTime = 15           # Seconds to wait before checking health
$PostRestartTimeout = 60            # How long to wait for healthy state

# === Resource Thresholds ===
$MaxMemoryMB = 1024                 # Memory limit (MB)
$MaxCPUPercent = 80                 # CPU usage limit (%)
$CPUCheckCount = 3                  # Consecutive high CPU readings needed
$ResponseTimeWarningMs = 5000       # Slow response warning threshold (ms)

# === Notifications ===
$VerboseDiscordNotifications = $false  # Set to $true for more notifications
```

## Setup Instructions

### 1. Download and Save the Script
Save `cli_debrid_monitor_enhanced.ps1` to the same folder as `cli_debrid.exe`:
```
C:\YOUR FILE LOCATION\cli_debrid_monitor_enhanced.ps1
```

### 2. Update Configuration
Edit the script and update these settings:
```powershell
# Your Discord webhook URL
$DiscordWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE"

# Path to cli_debrid.exe (verify this is correct)
$ExePath = "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid.exe"
```

### 3. Test the Discord Webhook (Important!)
Before running the monitor, test your webhook:

```powershell
cd "C:\YOUR FILE LOCATION\cli_debrid"
powershell.exe -ExecutionPolicy Bypass -File ".\test_discord_webhook.ps1"
```

You should see:
- ❌ Test 1 may fail (that's okay, we don't use simple messages)
- ✅ Test 2 should succeed (this is what the monitor uses)

### 4. Test the Monitor Script

**Important:** You must use `-ExecutionPolicy Bypass` because Windows blocks downloaded scripts:

```powershell
cd "C:\YOUR FILE LOCATION\cli_debrid"
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

**Alternative:** Unblock the file first, then run normally:
```powershell
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"
.\cli_debrid_monitor_enhanced.ps1
```

Watch for:
- ✅ Startup log messages
- ✅ Discord startup notification
- ✅ Health checks running every 30 seconds
- ✅ Process health monitoring (memory/CPU)
- ❌ No errors in the output

Press `Ctrl+C` to stop the test.

### 5. Run as a Background Service (Recommended)

**Option A: Using Task Scheduler** (Recommended for Windows)

1. Open Task Scheduler (`Win+R` → `taskschd.msc`)
2. Click **Create Task** (not "Basic Task")
3. **General Tab:**
   - Name: `cli_debrid Monitor`
   - Description: `Monitors and auto-restarts cli_debrid`
   - **Important:** Select "Run whether user is logged on or not"
   - Check "Run with highest privileges"
   - Configure for: Windows 10 (or your OS version)

4. **Triggers Tab:**
   - Click **New**
   - Begin the task: **At startup**
   - Delay task for: **30 seconds** (gives Windows time to start)
   - Enabled: **Checked**

5. **Actions Tab:**
   - Click **New**
   - Action: **Start a program**
   - Program/script: `powershell.exe`
   - Add arguments: 
     ```
     -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor_enhanced.ps1"
     ```
   - Start in: `C:\YOUR FILE LOCATION\cli_debrid`

6. **Conditions Tab:**
   - **Uncheck** "Start the task only if the computer is on AC power"
   - **Uncheck** "Stop if the computer switches to battery power"

7. **Settings Tab:**
   - Allow task to be run on demand: **Checked**
   - If the task is already running: **Do not start a new instance**
   - If the task fails, restart every: **1 minute**
   - Attempt to restart up to: **3 times**

8. Click **OK** and enter your Windows password if prompted

9. **Test the task:**
   - Right-click the task → **Run**
   - Check Discord for startup notification
   - Check Task Manager for `powershell.exe` process

**Option B: Using NSSM (Non-Sucking Service Manager)**

NSSM makes the monitor a proper Windows service:

1. Download NSSM from https://nssm.cc/download
2. Extract `nssm.exe` (use 64-bit version)
3. Open Command Prompt as Administrator
4. Run these commands:

```cmd
cd C:\path\to\nssm

nssm install CliDebridMonitor "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "-ExecutionPolicy Bypass -NoProfile -File \"C:\PlexDebrid World\cli_debrid\cli_debrid_monitor_enhanced.ps1\""

nssm set CliDebridMonitor AppDirectory "C:\YOUR FILE LOCATION\cli_debrid"

nssm set CliDebridMonitor DisplayName "cli_debrid Monitor"

nssm set CliDebridMonitor Description "Monitors and auto-restarts cli_debrid application"

nssm set CliDebridMonitor Start SERVICE_AUTO_START

nssm start CliDebridMonitor
```

5. Verify it's running:
```cmd
nssm status CliDebridMonitor
```

6. To stop/remove the service later:
```cmd
nssm stop CliDebridMonitor
nssm remove CliDebridMonitor confirm
```

## Troubleshooting

### Script Won't Run - Execution Policy Error

**Error:** "cannot be loaded because running scripts is disabled"

**Solution 1 (Recommended):** Always use `-ExecutionPolicy Bypass`:
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

**Solution 2:** Unblock the file:
```powershell
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"
```

**Solution 3:** Change execution policy (less secure):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Discord Notifications Not Working

**Test the webhook first:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\test_discord_webhook.ps1"
```

**Common issues:**
- ❌ Webhook URL is incorrect or expired
- ❌ Firewall blocking outbound HTTPS (port 443)
- ❌ Discord webhook was deleted from server
- ❌ Internet connection issues

**To regenerate webhook:**
1. Go to Discord server → Channel Settings → Integrations → Webhooks
2. Delete old webhook
3. Create new webhook
4. Copy URL and update script

### Process Health Check Error

**Error:** "Method invocation failed because [System.Object[]] does not contain a method named 'op_Division'"

**Cause:** Multiple cli_debrid.exe processes running

**Solution:** 
1. Kill duplicate processes in Task Manager
2. The updated script now handles this automatically

### Process Won't Restart

**Common causes:**
- ❌ Exe path is incorrect in script
- ❌ Insufficient permissions
- ❌ cli_debrid is locked by another process

**Check:**
```powershell
# Verify the path exists
Test-Path "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid.exe"

# Check for running processes
Get-Process cli_debrid
```

### Task Scheduler Task Not Running

**Debug steps:**
1. Right-click task → **Run** to test manually
2. Check "Last Run Result" column
   - `0x0` = Success
   - `0x1` = Incorrect function called
   - Other codes = Look up in Event Viewer
3. Task Scheduler → View → **Show All Running Tasks**
4. Check Windows Event Viewer → Windows Logs → Application

**Common issues:**
- Path in "Start in" field is incorrect
- Forgot to use `-ExecutionPolicy Bypass`
- Task is set to run only when user is logged in

### High CPU/Memory Not Triggering Restart

**Check current values:**
```powershell
Get-Process cli_debrid | Select-Object Name, CPU, @{N='Memory(MB)';E={[math]::Round($_.WS/1MB,2)}}
```

**Adjust thresholds in script if needed:**
```powershell
$MaxMemoryMB = 1024    # Lower if triggering too late
$MaxCPUPercent = 80    # Adjust based on your system
```

## Monitoring the Monitor

### Check if Monitor is Running

```powershell
# Look for PowerShell process running the monitor
Get-Process powershell | Where-Object { 
    $_.CommandLine -like "*cli_debrid_monitor*" 
}
```

### View Recent Logs

```powershell
# Last 20 lines
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" -Tail 20

# Follow in real-time
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" -Tail 20 -Wait
```

### Check Diagnostic Files

```powershell
# List recent diagnostic files
Get-ChildItem "C:\YOUR FILE LOCATION\cli_debrid\diagnostics" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 5
```

## Testing the Discord Webhook

Use the included test script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\test_discord_webhook.ps1"
```

Or test manually:

```powershell
$webhook = "YOUR_WEBHOOK_URL"

# Test embed format (what the monitor uses)
$payload = @{
    embeds = @(
        @{
            title = "Test Message"
            description = "✅ This is a test embed"
            color = 3447003
        }
    )
} | ConvertTo-Json -Depth 4

Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType "application/json"
```

## Performance Impact

The script is very lightweight:
- **Memory:** ~30-50MB (PowerShell process)
- **CPU:** <1% (mostly idle, brief spikes during checks)
- **Network:** ~1KB per health check every 30 seconds
- **Disk:** 
  - Log file: ~1-2MB per day
  - Diagnostics: ~100KB per file (max 30 files)

## Security Considerations

1. **Webhook Security:** 
   - Treat webhook URL like a password
   - Don't commit to source control
   - Regenerate if exposed publicly

2. **Execution Policy:**
   - `-ExecutionPolicy Bypass` is safe for your own scripts
   - Only affects the single script execution
   - Doesn't change system-wide policy

3. **Permissions:**
   - Script needs permission to start/stop processes
   - "Run with highest privileges" in Task Scheduler recommended
   - Not required to run as SYSTEM account

## File Structure After Setup

```
C:\YOUR FILE LOCATION\cli_debrid\
├── cli_debrid.exe
├── cli_debrid_monitor_enhanced.ps1
├── test_discord_webhook.ps1
├── cli_debrid_monitor.log
└── diagnostics\
    ├── diagnostic_20241113_144502.txt
    ├── diagnostic_20241113_153421.txt
    └── ... (up to 30 files)
```

## Support & Maintenance

### Daily
- Check Discord for any alerts
- Note any unexpected restarts

### Weekly  
- Review log file for patterns
- Check diagnostic folder if there were issues
- Verify monitor is still running

### Monthly
- Review restart frequency trends
- Adjust thresholds if needed
- Archive old logs if desired

### After Updates
- Windows updates
- cli_debrid updates
- PowerShell updates

## Quick Reference Commands

```powershell
# Start monitor manually
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"

# Test Discord webhook
powershell.exe -ExecutionPolicy Bypass -File ".\test_discord_webhook.ps1"

# View live logs
Get-Content ".\cli_debrid_monitor.log" -Tail 20 -Wait

# Check if monitor is running
Get-Process powershell | Where-Object { $_.CommandLine -like "*cli_debrid_monitor*" }

# Check cli_debrid process health
Get-Process cli_debrid | Select-Object Name, CPU, @{N='Memory(MB)';E={[math]::Round($_.WS/1MB,2)}}

# Kill monitor (if needed)
Get-Process powershell | Where-Object { $_.CommandLine -like "*cli_debrid_monitor*" } | Stop-Process
```

## Next Steps After Setup

1. ✅ Verify Discord notifications are working
2. ✅ Monitor for the first 24 hours
3. ✅ Review logs for any issues
4. ✅ Adjust thresholds based on your environment
5. ✅ Set up Task Scheduler or NSSM for auto-start
6. ✅ Test a manual restart to see notifications

## Getting Help

If you encounter issues:

1. Check the log file first
2. Review diagnostic files if available
3. Test Discord webhook separately
4. Verify all paths in the script are correct
5. Check Windows Event Viewer for errors
