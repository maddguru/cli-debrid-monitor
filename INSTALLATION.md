# Installation Guide

Quick installation instructions for cli_debrid Monitor.

## 📥 Download

Download the latest release from: [Releases](../../releases)

## 📂 Installation

### Step 1: Extract Files

Extract the ZIP file to your cli_debrid directory:
```
C:\YOUR FILE LOCATION\cli_debrid\
```

**Resulting structure:**
```
C:\YOUR FILE LOCATION\cli_debrid\
├── cli_debrid.exe (your existing file)
├── cli_debrid_monitor_enhanced.ps1 (new)
├── test_discord_webhook.ps1 (new)
├── test_restart_mechanism.ps1 (new)
└── docs\ (new)
```

### Step 2: Configure Discord Webhook

1. **Get Discord Webhook URL:**
   - Open Discord
   - Go to Server Settings → Integrations → Webhooks
   - Click "New Webhook"
   - Name it: `cli_debrid Monitor`
   - Choose channel for notifications
   - Copy webhook URL

2. **Edit the script:**
   - Open `cli_debrid_monitor_enhanced.ps1` in a text editor
   - Find line 13: `$DiscordWebhook = "YOUR_WEBHOOK_URL_HERE"`
   - Replace with your webhook URL
   - Save the file

### Step 3: Verify Paths

Check that these paths are correct in the script:

```powershell
# Line 9 - Path to cli_debrid.exe
$ExePath = "C:\YOUR FILE LOCATION\cli_debrid.exe"

# If your path is different, update it
```

### Step 4: Test the Monitor

```powershell
# Navigate to cli_debrid directory
cd "C:\YOUR FILE LOCATION\cli_debrid"

# Run the monitor
powershell.exe -ExecutionPolicy Bypass -File ".\cli_debrid_monitor_enhanced.ps1"
```

**You should see:**
- ✅ Startup banner
- ✅ Configuration loaded
- ✅ Discord notification sent
- ✅ Health checks running

**Press `Ctrl+C` to stop.**

### Step 5: Test Discord Webhook

```powershell
.\test_discord_webhook.ps1
```

Check Discord - you should receive a test message!

### Step 6: Setup as Background Service (Optional)

See [SETUP_GUIDE.md](docs/SETUP_GUIDE.md) for complete Task Scheduler setup.

**Quick version:**
1. Open Task Scheduler (`taskschd.msc`)
2. Create Basic Task
3. Trigger: At startup
4. Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid_monitor_enhanced.ps1"`
   - Start in: `C:\YOUR FILE LOCATION\cli_debrid`
5. Settings: Run whether user is logged on or not

## ⚙️ Configuration (Optional)

All configuration is at the top of `cli_debrid_monitor_enhanced.ps1`:

```powershell
# Essential settings (change if needed)
$IntervalSeconds = 600              # Check every 10 minutes
$FailuresBeforeRestart = 3          # 3 failures before restart
$MaxMemoryMB = 1024                 # Memory limit
$MaxCPUPercent = 80                 # CPU limit

# Features (enable/disable)
$EnableDiscordNotifications = $true     # Discord notifications
$SendHourlyHeartbeat = $true            # Hourly status updates
$ShowRoutineHealthChecks = $false       # Quiet mode
$EnableFastCheckAfterFailure = $true    # Fast recovery mode
```

## 🧪 Testing

### Test 1: Discord Notifications
```powershell
.\test_discord_webhook.ps1
```
✅ Should send test message to Discord

### Test 2: Restart Mechanism
```powershell
.\test_restart_mechanism.ps1
```
✅ Should restart cli_debrid and verify it comes back up

### Test 3: Monitor Operation
Run the monitor and watch for:
- ✅ Startup notification in Discord
- ✅ Health checks completing every 10 minutes
- ✅ Status box after 100 minutes
- ✅ Hourly heartbeat in Discord

## 🐛 Troubleshooting

### "Script cannot be loaded"
```powershell
# Unblock the file
Unblock-File -Path ".\cli_debrid_monitor_enhanced.ps1"
```

### Discord not working
- Verify webhook URL is correct
- Check webhook hasn't been deleted in Discord
- Run `.\test_discord_webhook.ps1` to verify

### Monitor not detecting failures
- Verify `$Url = "http://localhost:40000/auth/login"` is correct
- Check cli_debrid is actually running
- Try accessing the URL in a browser

### Multiple process warning
This is **normal**! cli_debrid runs 3 processes by design. See `docs/CLI_DEBRID_MULTIPLE_PROCESSES_EXPLAINED.md`

## 📚 Next Steps

1. ✅ Read [SETUP_GUIDE.md](/SETUP_GUIDE.md) for detailed setup
2. ✅ Set up Task Scheduler for 24/7 monitoring

## 🎉 Done!

Your cli_debrid is now monitored with automatic restart, Discord notifications, and comprehensive diagnostics!

**Need help?** Open an issue on GitHub or check the documentation in the `docs/` folder.
