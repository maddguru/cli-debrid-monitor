# Changelog

All notable changes to the cli_debrid Monitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-19

### Initial Release

#### 🎉 Core Features
- **Automatic Health Monitoring** - Checks cli_debrid health every 10 minutes (configurable)
- **Automatic Restart** - Restarts cli_debrid after 3 consecutive failures
- **Discord Integration** - Comprehensive notifications for all events
- **Resource Monitoring** - Memory and CPU usage tracking with configurable thresholds
- **Response Time Tracking** - Monitors and alerts on slow responses
- **Diagnostic Data Collection** - Captures system state during failures

#### ⚡ Advanced Features
- **Fast Check Mode** - Automatically switches to 60-second checks after first failure for 90% faster recovery
- **Hourly Heartbeat** - Regular status updates to Discord showing system health
- **Rate Limiting** - Prevents restart loops with configurable max restarts per hour
- **Live Countdown Timer** - Visual countdown showing time until next health check
- **Smart Retry Logic** - 3-attempt retry for Discord notifications with exponential backoff

#### 🎨 User Experience
- **Colorful Console Output** - Beautiful, color-coded console with emoji indicators
- **Quiet Mode** - Optional suppression of routine health checks for cleaner logs
- **Status Boxes** - Periodic status updates showing uptime, response times, and restarts
- **Perfect Box Alignment** - Enhanced Write-BoxLine function with emoji-aware width calculation
- **Descriptive Notifications** - Clear logging of what Discord notifications were sent

#### 🔧 Configuration Options
- **Discord Master Toggle** - Enable/disable all Discord notifications
- **Configurable Intervals** - Customize check frequency, failure thresholds, and more
- **Resource Thresholds** - Set custom memory and CPU limits
- **Fast Check Settings** - Configure fast mode interval and failure threshold
- **Notification Verbosity** - Control Discord notification frequency

#### 📊 Monitoring & Diagnostics
- **Monitor Uptime Tracking** - Shows how long the monitor has been running
- **Restart Statistics** - Tracks total restarts and provides detailed history
- **Response Time Analytics** - Average, min, max response time tracking
- **Diagnostic Files** - Comprehensive system state capture during failures
- **Log Files** - Detailed logging of all events with timestamps

#### 🔔 Discord Notifications
- **Startup Notification** - Confirms monitor started with configuration details
- **Hourly Heartbeat** - Regular health status updates
- **Performance Warnings** - Alerts for slow responses, high memory, high CPU
- **Restart Sequence** - Notifications for restart initiation, success, and failure
- **Rate Limit Alerts** - Warnings when restart limits are reached
- **Health Restored** - Confirmation when issues are resolved

#### 🧪 Testing Tools
- **test_discord_webhook.ps1** - Verify Discord webhook configuration
- **test_restart_mechanism.ps1** - Test restart functionality safely

#### 🏗️ Architecture Understanding
- **Multi-Process Support** - Correctly handles cli_debrid's 3-process architecture
  - Process 1: Main Python interpreter
  - Process 2: Flask web server
  - Process 3: Metadata battery service
- **Smart Process Handling** - Monitors main process, restarts all processes together
- **No False Warnings** - Understands that 3 processes is normal, expected behavior

#### ⚙️ Technical Features
- **PowerShell 5.1+ Compatible** - Works on Windows 10/11
- **Execution Policy Handling** - Can run with -ExecutionPolicy Bypass
- **Working Directory Management** - Properly handles paths and directories
- **Error Handling** - Comprehensive try-catch blocks with detailed error messages
- **Modular Functions** - Well-organized, reusable function structure

#### 🎯 Default Configuration
```powershell
$IntervalSeconds = 600                    # 10 minutes
$FailuresBeforeRestart = 3                # 3 failures
$EnableFastCheckAfterFailure = $true      # Fast mode enabled
$FastCheckIntervalSeconds = 60            # 60 seconds
$MaxRestartsPerHour = 2                   # 2 restarts/hour
$MaxMemoryMB = 1024                       # 1GB memory
$MaxCPUPercent = 80                       # 80% CPU
$ResponseTimeWarningMs = 5000             # 5 seconds
$PostRestartWaitTime = 30                 # 30 seconds
$SendHourlyHeartbeat = $true              # Heartbeat enabled
$ShowRoutineHealthChecks = $false         # Quiet mode
$EnableDiscordNotifications = $true       # Discord enabled
```

#### 🐛 Known Issues
- None at initial release

#### 📝 Notes
- Requires Discord webhook URL configuration
- Designed specifically for cli_debrid multi-process architecture
- Logs stored in script directory (not application directory)
- Status boxes display every 10 checks (100 minutes with default settings)

---

## Future Enhancements (Planned)

### Potential Features for v1.1.0+
- Multiple application monitoring from single script
- Configurable notification templates
- python version

---

**Note:** This is the initial release. Future versions will be documented here as they are released.
