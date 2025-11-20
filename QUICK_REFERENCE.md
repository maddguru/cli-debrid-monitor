# cli_debrid Monitor - Quick Reference Card

## 🚀 Quick Commands

### Check if Monitor is Running
```powershell
Get-Process powershell | Where-Object { $_.CommandLine -like "*cli_debrid_monitor*" }
```

### View Recent Log Entries
```powershell
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" -Tail 20 -Wait
```

### View Current Statistics
```powershell
# Check cli_debrid process
Get-Process cli_debrid | Select-Object Name, CPU, @{N='Memory(MB)';E={[math]::Round($_.WS/1MB,2)}}

# Check network connections
Get-NetTCPConnection -LocalPort 40000
```

### Manually Test Health Check
```powershell
Invoke-WebRequest -Uri "http://localhost:40000/auth/login" -UseBasicParsing
```

### View Diagnostic Files
```powershell
Get-ChildItem "C:\YOUR FILE LOCATION\cli_debrid\diagnostics" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### Test Discord Webhook
```powershell
$webhook = "YOUR_WEBHOOK_URL"
Invoke-RestMethod -Uri $webhook -Method Post -Body '{"content":"Test message"}' -ContentType "application/json"
```

## 📊 Key Metrics to Watch

| Metric | Normal Range | Action If Exceeded |
|--------|--------------|-------------------|
| Memory | < 800MB | Check for memory leaks |
| CPU | < 50% avg | Investigate high CPU usage |
| Response Time | < 2000ms | Performance degradation |
| Restarts per Day | < 2 | Underlying stability issue |
| Failed Health Checks | < 1% | Check connectivity issues |

## 🎨 Discord Notification Types

| Icon | Color | Meaning | Action Required |
|------|-------|---------|----------------|
| 🚀 | Blue | Monitor started | None - informational |
| ✅ | Green | Success/Recovery | None - good news |
| 🟡 | Yellow | Warning | Monitor situation |
| 🟠 | Orange | Restarting | None - automatic |
| 🔴 | Red | Failed | **Manual intervention needed** |

## ⚙️ Common Configuration Tweaks

### Make It More Aggressive
```powershell
$IntervalSeconds = 15              # Check every 15 seconds
$FailuresBeforeRestart = 2         # Restart after 2 failures
$MaxRestartsPerHour = 4            # Allow 4 restarts per hour
```

### Make It More Conservative
```powershell
$IntervalSeconds = 60              # Check every minute
$FailuresBeforeRestart = 5         # Wait for 5 failures
$MaxRestartsPerHour = 1            # Only 1 restart per hour
```

### Reduce Discord Spam
```powershell
$VerboseDiscordNotifications = $false    # Only critical alerts
$ResponseTimeWarningMs = 10000           # Higher threshold
```

### Get More Information
```powershell
$VerboseDiscordNotifications = $true     # All notifications
$ResponseTimeWarningMs = 2000            # Lower threshold
```

## 🔧 Troubleshooting Flowchart

```
Is cli_debrid running?
├─ NO → Check Task Scheduler / NSSM service
│       Check log file for startup errors
│       Verify exe path is correct
│
└─ YES → Is it responding to health checks?
    ├─ NO → Check if port 40000 is accessible
    │       Check firewall settings
    │       Review diagnostic files
    │
    └─ YES → Is monitor detecting issues?
        ├─ NO → Check if monitor is running
        │       Review threshold settings
        │       Test health check manually
        │
        └─ YES → Are restarts working?
            ├─ NO → Check rate limiting
            │       Verify Windows permissions
            │       Review restart logs
            │
            └─ YES → System is working correctly!
```

## 🚨 Emergency Procedures

### Monitor Stopped Working
1. Check Task Scheduler status
2. Review last log entries for errors
3. Restart monitor manually to test
4. Check Windows Event Viewer for crashes

### cli_debrid Won't Restart
1. Kill cli_debrid.exe manually (Task Manager)
2. Start cli_debrid.exe manually
3. Check if monitor picks up the new process
4. Review diagnostic files for clues

### Too Many Restarts
1. Check daily summary for patterns
2. Review diagnostic files from each restart
3. Increase thresholds temporarily
4. Consider underlying cli_debrid issue

### Discord Not Working
1. Test webhook URL manually
2. Check internet connectivity
3. Verify webhook hasn't been deleted
4. Check PowerShell can reach Discord API

## 📋 Maintenance Schedule

### Daily
- [ ] Check Discord for any alerts
- [ ] Note any unexpected restarts

### Weekly
- [ ] Review log file for patterns
- [ ] Check diagnostic folder size
- [ ] Verify monitor is still running

### Monthly
- [ ] Review average uptime trends
- [ ] Adjust thresholds if needed
- [ ] Archive old logs if desired
- [ ] Check for script updates

### As Needed
- [ ] After Windows updates
- [ ] After cli_debrid updates
- [ ] After unusual behavior
- [ ] When changing configuration

## 📱 Discord Channel Setup Tips

### Create Dedicated Channel
1. Create #cli-debrid-monitor channel
2. Get webhook for that channel
3. Mute channel (check periodically)
4. Pin daily summary messages

### Role Mentions for Critical Alerts
```powershell
# Modify script to add role ping on failures
# In Send-DiscordNotification function:
if ($Color -eq "15158332") {  # Red/Error
    $content = "<@&YOUR_ROLE_ID>"  # Add this to payload
}
```

## 🔍 Log Analysis Commands

### Count Restarts Today
```powershell
$today = (Get-Date).Date
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" | 
    Select-String "Restart condition met" | 
    Where-Object { (Get-Date $_.Line.Substring(0,19)) -ge $today } | 
    Measure-Object
```

### Find All Errors
```powershell
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" | 
    Select-String -Pattern "error|failed|❌" -Context 2,2
```

### Calculate Average Response Time
```powershell
$times = Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" | 
    Select-String "Health check took (\d+)ms" | 
    ForEach-Object { [int]$_.Matches.Groups[1].Value }

if ($times.Count -gt 0) {
    "Average: $([math]::Round(($times | Measure-Object -Average).Average, 2))ms"
    "Minimum: $(($times | Measure-Object -Minimum).Minimum)ms"
    "Maximum: $(($times | Measure-Object -Maximum).Maximum)ms"
}
```

### Get Uptime Summary
```powershell
Get-Content "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" | 
    Select-String "Uptime before restart" | 
    Select-Object -Last 10
```

## 🎯 Performance Tuning Matrix

| Your Scenario | Interval | Failures | Max/Hour | Memory | CPU |
|---------------|----------|----------|----------|---------|-----|
| **Stable System** | 60s | 5 | 1 | 1536MB | 90% |
| **Default** | 30s | 3 | 2 | 1024MB | 80% |
| **Unstable System** | 15s | 2 | 4 | 768MB | 70% |
| **Low Resources** | 30s | 3 | 2 | 512MB | 60% |
| **High Performance** | 45s | 4 | 1 | 2048MB | 90% |

## 🆘 When to Seek Help

Contact support or investigate deeper if:
- ❌ Restarts exceed 5 per day consistently
- ❌ Memory keeps growing (memory leak)
- ❌ CPU always high (infinite loop)
- ❌ Response times consistently > 10 seconds
- ❌ Monitor itself crashes frequently
- ❌ Diagnostic files show network errors

## 💾 Backup Important Files

Before making changes, backup:
```powershell
# Create backup folder
$backupPath = "C:\YOUR FILE LOCATION\backup_$(Get-Date -Format 'yyyyMMdd')"
New-Item -Path $backupPath -ItemType Directory -Force

# Copy important files
Copy-Item "C:\YOUR FILE LOCATION\cli_debrid\*.ps1" $backupPath
Copy-Item "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log" $backupPath
Copy-Item "C:\YOUR FILE LOCATION\cli_debrid\diagnostics" $backupPath -Recurse
```

## 📞 Support Checklist

When asking for help, provide:
- [ ] Last 100 lines of log file
- [ ] Recent diagnostic file
- [ ] Your configuration settings
- [ ] Windows version
- [ ] cli_debrid version
- [ ] Description of the problem
- [ ] When problem started
- [ ] What you've tried already

## 🎓 Quick Wins

### Immediate Improvements
1. ✅ Set up Discord webhook - instant visibility
2. ✅ Enable Task Scheduler - automatic recovery
3. ✅ Review first diagnostic file - understand your system

### Next Level
4. ✅ Tune thresholds based on your environment
5. ✅ Set up dedicated Discord channel
6. ✅ Schedule weekly log reviews

### Advanced
7. ✅ Create custom health checks
8. ✅ Add email notifications
9. ✅ Integrate with other monitoring tools

---

## 🔖 Bookmark These

- **Script Location:** `C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor_enhanced.ps1`
- **Log File:** `C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor.log`
- **Diagnostics:** `C:\YOUR FILE LOCATION\cli_debrid\diagnostics\`
- **Discord Webhook:** (store securely)
- **Task Scheduler:** taskschd.msc

## ⚡ Pro Tips

1. **Use Task Scheduler** - Most reliable for auto-start
2. **Check Discord Daily** - Catch issues early
3. **Review Diagnostics** - Understand failure patterns
4. **Tune Thresholds** - One size doesn't fit all
5. **Keep Logs** - Historical data helps troubleshooting
6. **Test Changes** - Run manually before scheduling
7. **Monitor the Monitor** - Ensure it's always running

---

Print this card and keep it handy! 📄✨
