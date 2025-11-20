# cli_debrid Monitor v1.0.0 - Initial Release 🎉

**Enhanced monitoring and auto-restart system for cli_debrid with Discord notifications**

## 🚀 Quick Start

1. **Download** `cli_debrid_monitor_v1.0.0.zip` from Assets below
2. **Extract** to your cli_debrid directory: `C:\YOUR FILE LOCATION\cli_debrid\`
3. **Edit** `cli_debrid_monitor_enhanced.ps1`:
   ```powershell
   $DiscordWebhook = "YOUR_WEBHOOK_URL_HERE"
   $ExePath = "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid.exe"
   ```
4. **Run:**
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
   ```

See `docs/SETUP_GUIDE.md` for complete setup instructions including Task Scheduler configuration.

---

## ✨ Key Features

### 🔄 Automatic Monitoring & Restart
- Health checks every 10 minutes (configurable)
- Automatic restart after 3 consecutive failures
- Rate limiting (max 2 restarts per hour)
- Post-restart health verification

### ⚡ Fast Check Mode (NEW!)
- Switches to 60-second checks after first failure
- **90% faster recovery** (2 minutes vs 30 minutes)
- Automatically returns to normal interval when healthy
- Configurable thresholds and intervals

### 💚 Hourly Heartbeat
- Regular "I'm alive" status updates
- System health statistics
- Memory usage and response times
- Peace of mind monitoring

### 📊 Resource Monitoring
- **Memory threshold:** 1024MB (configurable)
- **CPU threshold:** 80% (configurable)
- **Response time warning:** 5 seconds (configurable)
- Automatic restart on threshold violations

### 🎨 Beautiful Console Output
- Color-coded messages with emoji indicators
- Live countdown timer between checks
- Status boxes every 100 minutes
- Quiet mode option for cleaner logs
- Perfect box alignment with emoji support

### 🔔 Discord Integration
- Comprehensive notifications for all events
- Master on/off toggle
- Hourly heartbeat messages
- Performance degradation alerts
- Restart sequence notifications
- Descriptive notification logging

### 💾 Diagnostics & Logging
- Automatic diagnostic data capture during failures
- Detailed log files with timestamps
- Response time statistics
- Uptime tracking
- Restart history

---

## 📋 What's Included

### Scripts
- **cli_debrid_monitor_enhanced.ps1** - Main monitoring script
- **test_discord_webhook.ps1** - Test Discord webhook configuration
- **test_restart_mechanism.ps1** - Test restart functionality

### Documentation (docs/)
- **SETUP_GUIDE.md** - Complete setup instructions


---

## 🎯 Configuration Highlights

### Recommended Settings (Default)
```powershell
$IntervalSeconds = 600                    # 10 minutes
$FailuresBeforeRestart = 3                # 3 failures
$EnableFastCheckAfterFailure = $true      # Fast mode ON
$FastCheckIntervalSeconds = 60            # 60 seconds
$MaxRestartsPerHour = 2                   # 2 restarts/hour
$SendHourlyHeartbeat = $true              # Heartbeat ON
$ShowRoutineHealthChecks = $false         # Quiet mode ON
```

### For Critical Systems
```powershell
$IntervalSeconds = 300                    # 5 minutes
$FailuresBeforeRestart = 2                # 2 failures
$FastCheckIntervalSeconds = 30            # 30 seconds
$MaxRestartsPerHour = 4                   # 4 restarts/hour
```

### For Testing
```powershell
$IntervalSeconds = 60                     # 1 minute
$EnableDiscordNotifications = $false      # No Discord spam
$ShowRoutineHealthChecks = $true          # See everything
```

---

## 📊 Discord Notification Examples

**Startup:**
```
🚀 cli_debrid Monitor Started

Configuration:
- Check Interval: 10 minutes
- Failure Threshold: 3
- Memory Limit: 1024MB
- CPU Limit: 80%
```

**Hourly Heartbeat:**
```
💚 Monitor Heartbeat

Status: All systems operational
Monitor Uptime: 15.08:23:45
Memory Usage: 186MB
Avg Response: 2.15s
Restarts Today: 0
```

**Performance Warning:**
```
⚠️ Performance Degradation Detected

Health checks are consistently slow:
- Current: 6.5s
- Threshold: 5.0s
- Slow responses: 3 in a row
```

**Restart Sequence:**
```
🔄 Restarting cli_debrid
Reason: URL health check failed
Failed Checks: 3

✅ cli_debrid Restarted Successfully
Downtime: 00:42
Status: Responding to health checks
Total Restarts Today: 1
```

---

## 🏗️ Architecture Understanding

### cli_debrid Multi-Process Design
cli_debrid runs **3 processes by design** (not a bug!):
1. **Main Python interpreter** - Core application
2. **Flask web server** - Web UI (port 40000)
3. **Metadata battery service** - Metadata service (port 5001)

The monitor:
- ✅ Correctly handles all 3 processes
- ✅ Monitors main process health
- ✅ Restarts all processes together
- ✅ No false warnings about multiple processes


---

## 🔧 Installation Methods

### Method 1: Manual Run
```powershell
cd "C:\YOUR FILE LOCATION\cli_debrid"
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

### Method 2: Task Scheduler (Recommended for 24/7)
1. Open Task Scheduler
2. Create Task → Configure:
   - **Trigger:** At startup (30s delay)
   - **Action:** Start `powershell.exe`
   - **Arguments:** `-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor_enhanced.ps1"`
   - **Settings:** Run whether user is logged on or not

See `SETUP_GUIDE.md` for step-by-step instructions.

---

## 🧪 Testing Your Setup

### 1. Test Discord Webhook
```powershell
.\test_discord_webhook.ps1
```
Should send a test message to Discord.

### 2. Test Restart Mechanism
```powershell
.\test_restart_mechanism.ps1
```
Simulates a restart (kills and restarts cli_debrid).

### 3. Verify Monitor Operation
Watch for:
- ✅ Startup notification in Discord
- ✅ Countdown timer working
- ✅ Health checks completing
- ✅ Status box after 10 checks

---

## 🎨 Console Output Preview

```
╔════════════════════════════════════════════════════════════╗
║         cli_debrid Monitor - Enhanced Edition              ║
╚════════════════════════════════════════════════════════════╝

2025-11-19 10:00:00    cli_debrid monitor started
2025-11-19 10:00:00    Check Interval: 10 minutes
2025-11-19 10:00:00    Fast Check: Enabled (60s after first failure)

🚀 Monitor is now running...

2025-11-19 10:00:02    📤 🚀 Monitor startup sent to Discord
2025-11-19 10:00:04    Health check: 2.05s
2025-11-19 10:00:04    Process health - Memory: 186MB
2025-11-19 10:00:04    CPU: 45.3%

💤 Next health check in: 09:58
```

---

## ⚠️ Important Notes

### Discord Webhook Required
You **must** configure a Discord webhook URL. The monitor will not send notifications without it (though it will still work for monitoring).

**Get a webhook:**
1. Discord → Server Settings → Integrations → Webhooks
2. Create Webhook → Copy URL
3. Paste in script configuration


### Execution Policy
If you get "script cannot be loaded" error:
```powershell
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"
```
Or use `-ExecutionPolicy Bypass` when running.

---

## 📈 Performance Metrics

### Fast Check Mode Recovery Speed
| Scenario | Without Fast Check | With Fast Check | Improvement |
|----------|-------------------|-----------------|-------------|
| 3 Failures | 30 minutes | 2-3 minutes | **90% faster** |
| Detection + Restart | ~31 minutes | ~3 minutes | **90% faster** |

### Resource Usage
- **CPU:** Negligible (~0.1% during checks)
- **Memory:** ~50-100MB for PowerShell process
- **Network:** Minimal (health checks + Discord notifications)
- **Disk:** Small log files (~1-10MB depending on activity)

---

## 🐛 Troubleshooting

### Script Won't Start
```powershell
# Check execution policy
Get-ExecutionPolicy

# Unblock file
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"

# Run with bypass
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

### Discord Not Working
```powershell
# Test webhook
.\test_discord_webhook.ps1

# Verify webhook URL format
# Should be: https://discord.com/api/webhooks/[ID]/[TOKEN]
```

### Monitor Not Detecting Failures
- Check `$Url` points to correct cli_debrid URL
- Verify cli_debrid is actually running
- Check firewall isn't blocking localhost connections
- Review log file for errors

---

## 📝 Version History

**v1.0.0** - Initial Release (November 2025)
- Complete monitoring system
- Discord integration
- Fast check mode
- Hourly heartbeat
- Resource monitoring

---

## 🙏 Credits

- Designed for [cli_debrid](https://github.com/godver3/cli_debrid) by godver3
- Built for reliable media server operations
- Inspired by enterprise monitoring solutions

---

## 📄 License

MIT License - see LICENSE file for details

---

## 🎉 Enjoy!

Your cli_debrid is now monitored with automatic recovery, beautiful notifications, and comprehensive diagnostics!

**Questions?** Check the [docs/](docs/) folder or open an issue!

---

**Download the release below and start monitoring!** ⬇️
