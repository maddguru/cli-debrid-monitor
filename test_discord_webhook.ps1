# Discord Webhook Test Script
# This will help identify if there's an issue with the webhook URL

$DiscordWebhook = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE" # UPDATE TO YOUR URL

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    Discord Webhook Test - cli_debrid Monitor               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Simple content message
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host " Test 1: Simple Message Format" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host " Test 1: Simple Message Format" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
try {
    $simplePayload = @{
        content = "✅ Test message from PowerShell - Simple format"
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $DiscordWebhook -Method Post -Body $simplePayload -ContentType "application/json"
    Write-Host "   ✅ TEST 1 PASSED" -ForegroundColor Green
    Write-Host "      Simple message sent successfully" -ForegroundColor DarkGray
}
catch {
    Write-Host "   ❌ TEST 1 FAILED" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host "      Note: This format is not used by the monitor" -ForegroundColor DarkYellow
}

Start-Sleep -Seconds 2

# Test 2: Embed message (like the monitor uses)
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host " Test 2: Embed Format (Used by Monitor)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
try {
    $embedPayload = @{
        embeds = @(
            @{
                title = "cli_debrid Monitor Test"
                description = "✅ Test embed message from PowerShell"
                color = 3447003
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                footer = @{
                    text = $env:COMPUTERNAME
                }
            }
        )
    } | ConvertTo-Json -Depth 4 -Compress

    Invoke-RestMethod -Uri $DiscordWebhook -Method Post -Body $embedPayload -ContentType "application/json; charset=utf-8"
    Write-Host "   ✅ TEST 2 PASSED" -ForegroundColor Green
    Write-Host "      Embed message sent successfully" -ForegroundColor DarkGray
    Write-Host "      This is the format used by the monitor!" -ForegroundColor Green
}
catch {
    Write-Host "   ❌ TEST 2 FAILED" -ForegroundColor Red
    Write-Host "      Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    
    # Try to get more details
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "      Discord API Response: $responseBody" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host " Test Complete!" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 Check your Discord channel for test messages!" -ForegroundColor Green
Write-Host ""
