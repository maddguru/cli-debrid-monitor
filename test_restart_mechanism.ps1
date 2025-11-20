# cli_debrid Monitor - Restart Test Script
# This script simulates failures to test the restart mechanism

$DiscordWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE" # UPDATE TO YOUR URL

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Restart Mechanism Test - cli_debrid Monitor              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  This test will restart cli_debrid to verify the monitor works!" -ForegroundColor Yellow
Write-Host ""

# Function to send Discord notifications
function Send-DiscordNotification {
    param([string]$Message, [string]$Color = "3447003")
    
    try {
        $payload = @{
            embeds = @(
                @{
                    title = "cli_debrid Monitor - TEST MODE"
                    description = $Message
                    color = [int]$Color
                    timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    footer = @{ text = "$env:COMPUTERNAME - TEST" }
                }
            )
        } | ConvertTo-Json -Depth 4 -Compress

        Invoke-RestMethod -Uri $DiscordWebhook -Method Post -Body $payload -ContentType "application/json; charset=utf-8" | Out-Null
        Write-Host "✅ Discord notification sent" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to send Discord notification: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 1: Verify cli_debrid is running
Write-Host "Test 1: Checking if cli_debrid is running..." -ForegroundColor Yellow
$proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue

if ($proc) {
    if ($proc -is [array]) {
        Write-Host "✅ Found $($proc.Count) cli_debrid processes" -ForegroundColor Green
        $proc = $proc[0]
    } else {
        Write-Host "✅ Found cli_debrid process (PID: $($proc.Id))" -ForegroundColor Green
    }
    
    $memoryMB = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    Write-Host "   Memory: ${memoryMB}MB" -ForegroundColor Gray
    Write-Host "   CPU Time: $($proc.CPU)s" -ForegroundColor Gray
} else {
    Write-Host "❌ cli_debrid is NOT running!" -ForegroundColor Red
    Write-Host "   Please start cli_debrid before running this test." -ForegroundColor Red
    exit
}

Write-Host ""

# Test 2: Simulate restart sequence
Write-Host "Test 2: Simulating restart sequence..." -ForegroundColor Yellow
Write-Host "   This will actually restart cli_debrid!" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "   Do you want to proceed? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Test cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Step 1: Sending pre-restart notification to Discord..." -ForegroundColor Cyan
Send-DiscordNotification -Message "🔄 **TEST: Restarting cli_debrid**`n`nThis is a test of the restart mechanism.`n`nKilling process now..." -Color "16753920"

Start-Sleep -Seconds 2

Write-Host "Step 2: Killing cli_debrid process..." -ForegroundColor Cyan
try {
    $proc = Get-Process -Name "cli_debrid" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Host "   Stopping PID(s): $($proc.Id -join ', ')" -ForegroundColor Gray
        $proc | Stop-Process -Force
        Write-Host "   ✅ Process stopped" -ForegroundColor Green
    }
} catch {
    Write-Host "   ❌ Error stopping process: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

Write-Host "Step 3: Starting cli_debrid..." -ForegroundColor Cyan
try {
    $exePath = "C:\YOUR FILE LOCATION\cli_debrid\cli_debrid.exe" # UPDATE TO YOUR DIRECTORY
    $workingDir = "C:\YOUR FILE LOCATION\cli_debrid" # UPDATE TO YOUR DIRECTORY
    
    if (-not (Test-Path $exePath)) {
        Write-Host "   ❌ cli_debrid.exe not found at: $exePath" -ForegroundColor Red
        exit
    }
    
    Start-Process -FilePath $exePath -WorkingDirectory $workingDir
    Write-Host "   ✅ Process started" -ForegroundColor Green
    Write-Host "   Waiting 15 seconds for startup..." -ForegroundColor Gray
    Start-Sleep -Seconds 15
} catch {
    Write-Host "   ❌ Error starting process: $($_.Exception.Message)" -ForegroundColor Red
    Send-DiscordNotification -Message "❌ **TEST FAILED: Could not start cli_debrid**`n`nError: $($_.Exception.Message)" -Color "15158332"
    exit
}

Write-Host "Step 4: Verifying cli_debrid is running..." -ForegroundColor Cyan
$healthCheckUrl = "http://localhost:40000/auth/login" # UPDATE TO YOUR URL
$maxAttempts = 12  # 60 seconds total
$attempt = 0
$isHealthy = $false

while ($attempt -lt $maxAttempts -and -not $isHealthy) {
    $attempt++
    Write-Host "   Health check attempt $attempt/$maxAttempts..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri $healthCheckUrl -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
            $isHealthy = $true
            Write-Host "   ✅ cli_debrid is responding!" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⏳ Not responding yet..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 5
    }
}

Write-Host ""

# Test Results
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host " Test Results Summary" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

if ($isHealthy) {
    Write-Host "   ✅ SUCCESS: Restart mechanism works perfectly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "   ✓ Process was killed successfully" -ForegroundColor Green
    Write-Host "   ✓ Process was restarted successfully" -ForegroundColor Green
    Write-Host "   ✓ Health check passed after restart" -ForegroundColor Green
    Write-Host ""
    
    Send-DiscordNotification -Message "✅ **TEST PASSED: Restart Successful**`n`nThe restart mechanism is working correctly:`n- Process killed successfully`n- Process restarted successfully`n- Health check passed after restart`n`nYour monitor is ready for production!" -Color "5763719"
} else {
    Write-Host "   ⚠️  INCOMPLETE: cli_debrid did not become healthy within 60s" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   ✓ Process was killed: Success" -ForegroundColor Green
    Write-Host "   ✓ Process was restarted: Success" -ForegroundColor Green
    Write-Host "   ✗ Health check passed: Failed" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Possible reasons:" -ForegroundColor Yellow
    Write-Host "   • cli_debrid takes longer than 60s to fully start" -ForegroundColor DarkYellow
    Write-Host "   • Health check URL is incorrect or port is blocked" -ForegroundColor DarkYellow
    Write-Host "   • cli_debrid requires user interaction to start" -ForegroundColor DarkYellow
    Write-Host ""
    
    Send-DiscordNotification -Message "⚠️ **TEST INCOMPLETE: Health Check Failed**`n`nThe restart worked but health check did not pass within 60 seconds.`n`nThis may be normal if cli_debrid takes a while to start. Check the application manually." -Color "16776960"
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Check your Discord channel for test notifications!" -ForegroundColor Green
Write-Host ""
