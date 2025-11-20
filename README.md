# cli_debrid Monitor - Enhanced Edition

**Enhanced monitoring and auto-restart system for cli_debrid with Discord notifications, health checks, and comprehensive diagnostics.**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![Release](https://img.shields.io/github/v/release/maddguru/cli-debrid-monitor)](https://github.com/maddguru/cli-debrid-monitor/releases)

## ✨ Features

### Core Monitoring
- 🔄 **Automatic Restart** - Restarts cli_debrid on health check failures
- 💚 **Hourly Heartbeat** - Regular "I'm alive" notifications to Discord
- 📊 **Resource Monitoring** - Memory and CPU usage tracking with thresholds
- ⏱️ **Response Time Tracking** - Detects performance degradation
- 💾 **Diagnostic Data** - Captures system state during failures
- 🕐 **Live Countdown** - Shows time until next health check

### Advanced Features
- ⚡ **Fast Check Mode** - Switches to 60-second checks after first failure (90% faster recovery)
- 🎨 **Colorful Console** - Beautiful, easy-to-read output with emoji indicators
- 🔁 **Smart Retry Logic** - Handles transient Discord notification failures
- 📈 **Uptime Statistics** - Tracks reliability metrics over time
- 🤫 **Quiet Mode** - Optional suppression of routine health checks for cleaner logs
- 🔔 **Discord Integration** - Comprehensive notifications with master on/off toggle

## 🚀 Quick Start

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or later
- [cli_debrid](https://github.com/godver3/cli_debrid) installed
- Discord webhook URL 

### Installation

1. **Download the latest release** from [Releases](../../releases)

2. **Extract to cli_debrid directory:**
   ```
   C:\YOUR FILE LOCATION\cli_debrid\
   ```

3. **Edit configuration** in `cli_debrid_monitor_enhanced.ps1`:
   ```powershell
   # Required: Update these settings
   $DiscordWebhook = "YOUR_WEBHOOK_URL_HERE"
   $ExePath = "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid.exe"
   ```

4. **Test the monitor:**
   ```powershell
   cd "C:\YOUR FILE LOCATION\cli_debrid"
   powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
   ```

### Setup as Background Service

**Using Task Scheduler (Recommended):**

1. Open Task Scheduler (`Win+R` → `taskschd.msc`)
2. Create Basic Task → Name: "cli_debrid Monitor"
3. Trigger: **At startup** (with 30-second delay)
4. Action: **Start a program**
   - Program: `powershell.exe`
   - Arguments: `-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor_enhanced.ps1"`
   - Start in: `C:\YOUR FILE LOCATION\cli_debrid`
5. Settings: 
   - ✅ Run whether user is logged on or not
   - ❌ Start only if on AC power

See [SETUP_GUIDE.md](/SETUP_GUIDE.md) for detailed instructions.

## 📋 Configuration

### Essential Settings

```powershell
# Health Check Settings
$IntervalSeconds = 600              # Check every 10 minutes
$FailuresBeforeRestart = 3          # 3 failures before restart
$MaxRestartsPerHour = 2             # Rate limiting

# Fast Check Mode (after first failure)
$EnableFastCheckAfterFailure = $true    # Enable fast mode
$FastCheckIntervalSeconds = 60          # Check every 60 seconds after failure
$FastCheckFailuresBeforeRestart = 3     # Total failures needed

# Resource Thresholds
$MaxMemoryMB = 1024                 # Memory limit (MB)
$MaxCPUPercent = 80                 # CPU usage limit (%)
$ResponseTimeWarningMs = 5000       # Slow response threshold (5 seconds)

# Notifications
$EnableDiscordNotifications = $true     # Master toggle for Discord
$SendHourlyHeartbeat = $true            # Hourly status updates
$ShowRoutineHealthChecks = $false       # Hide routine checks (quiet mode)
$VerboseDiscordNotifications = $false   # Only important alerts
```

## 🎨 What You'll See

### Console Output (Quiet Mode)
```
╔════════════════════════════════════════════════════════════╗
║         cli_debrid Monitor - Enhanced Edition              ║
╚════════════════════════════════════════════════════════════╝

2025-11-19 10:00:00    cli_debrid monitor started
2025-11-19 10:00:00    Check Interval: 10 minutes
2025-11-19 10:00:00    Fast Check: Enabled (60s after first failure)
2025-11-19 10:00:00    Memory Threshold: 1024MB

🚀 Monitor is now running...

💤 Next health check in: 09:59

╔═════════════════════════════════════════════════════════╗
║ 📊 Status Update - Check #10                            ║
║ ⏰ Current Time: 2025-11-19 11:40:00                    ║
╠═════════════════════════════════════════════════════════╣
║ Monitor Uptime: 1.01:40:00                              ║
║ Avg Response Time: 2.06s                                ║
║ Total Restarts: 0                                       ║
╚═════════════════════════════════════════════════════════╝
```

### Discord Notifications

**Startup:**
```
🚀 cli_debrid Monitor Started

Configuration:
- Check Interval: 10 minutes
- Failure Threshold: 3
- Memory Limit: 1024MB
```

**Hourly Heartbeat:**
```
💚 Monitor Heartbeat

Status: All systems operational
Monitor Uptime: 3.15:24:33
Memory Usage: 186MB
Avg Response: 2.15s
Restarts Today: 0
```

**On Issues:**
```
⚠️ Performance Degradation Detected
⚠️ High Memory Usage Detected
🔄 Restarting cli_debrid
✅ cli_debrid Restarted Successfully
```

## 🧪 Testing

### Test Discord Webhook
```powershell
.\test_discord_webhook.ps1
```

### Test Restart Mechanism
```powershell
.\test_restart_mechanism.ps1
```

## 📁 File Structure

```
cli-debrid-monitor/
├── cli_debrid_monitor_enhanced.ps1    # Main monitor script
├── test_discord_webhook.ps1           # Test Discord notifications
├── test_restart_mechanism.ps1         # Test restart functionality
├── README.md                          # This file
├── LICENSE                            # MIT License
└── SETUP_GUIDE.md                     # Detailed setup instructions

```

## 🎯 Use Cases

### Production Server (Recommended)
```powershell
$IntervalSeconds = 600                    # 10 minutes
$FailuresBeforeRestart = 3                # Patient
$EnableFastCheckAfterFailure = $true      # Fast recovery
$ShowRoutineHealthChecks = $false         # Clean logs
```

### Critical Service (Aggressive)
```powershell
$IntervalSeconds = 300                    # 5 minutes
$FailuresBeforeRestart = 2                # Quick restart
$EnableFastCheckAfterFailure = $true      # Fast mode
$FastCheckIntervalSeconds = 30            # Check every 30s
```

### Testing/Development
```powershell
$IntervalSeconds = 60                     # 1 minute
$EnableDiscordNotifications = $false      # No spam
$ShowRoutineHealthChecks = $true          # See everything
```

## 🔧 Troubleshooting

### Script Won't Run
```powershell
# Unblock the file
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"

# Or use bypass
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

### Discord Notifications Not Working
```powershell
# Test webhook
.\test_discord_webhook.ps1

# Verify webhook URL is correct in script
$DiscordWebhook = "https://discord.com/api/webhooks/..."
```

### Multiple Process Warning
This is **normal**! cli_debrid runs 3 processes by design:
- Process 1: Main Python interpreter
- Process 2: Flask web server
- Process 3: Metadata battery service


## 📊 Key Features Explained

### Fast Check Mode ⚡

Automatically switches to rapid health checks after first failure:

**Normal Mode:**
- Check every 10 minutes
- Takes 30 minutes to detect 3 failures

**Fast Check Mode:**
- First failure detected → switches to 60-second checks
- Only takes 2-3 minutes to confirm problem and restart

**Result:** 90% faster failure recovery!


### Quiet Mode 🤫

Suppress routine health checks for cleaner console/logs:

```powershell
$ShowRoutineHealthChecks = $false  # Clean output
```

**Hidden:**
- Health check times
- Memory readings
- CPU percentages (when normal)

**Always Shown:**
- Warnings and errors
- Restarts
- Status boxes

### Hourly Heartbeat 💚

Regular "I'm alive" notifications:

```powershell
$SendHourlyHeartbeat = $true
```

**Benefits:**
- Confirm monitor is running
- Regular health statistics
- Early warning if monitor stops

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 📄 License

This project will be free for the community to use.

## 📞 Support

- **Setup Issues:** Review [SETUP_GUIDE.md](/SETUP_GUIDE.md)
- **Issues:** Open an issue on GitHub

## 🎉 Features at a Glance

| Feature | Description | Benefit |
|---------|-------------|---------|
| 🔄 Auto-Restart | Automatic restart on failure | Hands-free recovery |
| ⚡ Fast Check | 60s checks after failure | 90% faster recovery |
| 💚 Heartbeat | Hourly status updates | Peace of mind |
| 📊 Resource Monitor | Memory/CPU tracking | Early problem detection |
| 🎨 Beautiful UI | Color-coded output | Easy to scan |
| 🤫 Quiet Mode | Suppress routine logs | Clean output |
| 🔔 Discord | Comprehensive notifications | Stay informed |
| 📈 Statistics | Uptime tracking | Reliability metrics |
| 💾 Diagnostics | Failure data capture | Troubleshooting |
| 🔁 Smart Retry | Notification retry logic | Reliable alerts |

## 🙏 Acknowledgments

- Built for reliable [cli_debrid](https://github.com/godver3/cli_debrid) monitoring
- Inspired by enterprise monitoring solutions
- Designed mostly for Windows users that may have experienced issues with Windows processes freezing cli_debrid.
As stated before, I am not even close to being a developer so I used my particular set of skills to instruct AI to bring this and a few other ideas to life. I had an idea of creating a simple, monitoring solution for Windows users they may be experiencing freezing. And here we are.

**Made with ❤️ for cli_debrid community**

**Version:** 1.0.0  
**Last Updated:** November 2025
