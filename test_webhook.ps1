<#
.SYNOPSIS
    Quick local connectivity verification for your webhook.site listener.
.DESCRIPTION
    Sends a test JSON payload to your webhook.site URL to verify that
    it is reachable and receiving data properly before triggering GitHub Actions.
.PARAMETER WebhookUrl
    Your unique webhook.site URL, e.g. https://webhook.site/00000000-0000-0000-0000-000000000000
.EXAMPLE
    .\test_webhook.ps1 -WebhookUrl "https://webhook.site/your-unique-id"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WebhookUrl
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Testing Webhook Connectivity" -ForegroundColor Yellow
Write-Host " Target URL: $WebhookUrl" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$testPayload = @{
    event = "local_preflight_test"
    sender = "Member 1 (Vulnerable Range Lead)"
    project = "Breaking & Hardening the CI/CD Pipeline"
    simulated_token = "FLAG{gh_actions_pwned_dummy_token_98472}"
    timestamp = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $testPayload -ContentType "application/json"
    Write-Host "`n[+] SUCCESS! Webhook received the test payload." -ForegroundColor Green
    Write-Host "Check your browser tab at webhook.site to see the incoming POST request.`n" -ForegroundColor Green
} catch {
    Write-Host "`n[!] Failed to reach webhook URL: $_" -ForegroundColor Red
}
