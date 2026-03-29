# ============================================================
# IM Seed Data Script
# ============================================================
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/database/im_seed/seed.ps1
#
# Prerequisites:
#   1. Database reset: scripts/server/reset_db.ps1
#   2. Server running: scripts/server/start.ps1
#
# Creates 52 test users + 51 private conversations for user "朱红"
# ============================================================

$ErrorActionPreference = "Stop"

$baseUrl = "http://127.0.0.1:9600"
$seedFile = Join-Path $PSScriptRoot "seed-data.json"
$seed = Get-Content $seedFile -Raw | ConvertFrom-Json

$phonePrefix = $seed.phone_prefix
$password = $seed.default_password
$primaryIdx = $seed.primary_user_idx
$users = $seed.users

Write-Host "[SEED] Registering $($users.Count) users..."

$tokens = @{}
$userIds = @{}

foreach ($u in $users) {
    $phone = "$phonePrefix$($u.phone_suffix)"
    $name = $u.name

    try {
        # Send SMS
        $smsResp = Invoke-RestMethod -Uri "$baseUrl/auth/sms" -Method POST `
            -ContentType "application/json" -Body "{`"phone`":`"$phone`"}"
        $code = $smsResp.code

        # Login (auto-registers if new)
        $loginResp = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST `
            -ContentType "application/json" `
            -Body "{`"phone`":`"$phone`",`"type`":`"sms`",`"credential`":`"$code`"}"
        $token = $loginResp.token
        $userId = $loginResp.user_id
        $tokens[$u.idx] = $token
        $userIds[$u.idx] = $userId

        # Set password
        try {
            Invoke-RestMethod -Uri "$baseUrl/user/password" -Method POST `
                -ContentType "application/json" `
                -Headers @{ Authorization = "Bearer $token" } `
                -Body "{`"new_password`":`"$password`"}"
        } catch {}

        # Update profile (nickname + signature + avatar with color)
        $colorHex = $u.color
        $avatarValue = "identicon:$($u.idx):$colorHex"
        $body = @{ nickname = $name; signature = $u.bio; avatar = $avatarValue } | ConvertTo-Json
        $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        Invoke-RestMethod -Uri "$baseUrl/user/profile" -Method PUT `
            -ContentType "application/json; charset=utf-8" `
            -Headers @{ Authorization = "Bearer $token" } `
            -Body $bodyBytes | Out-Null

        Write-Host "  [$($u.idx)] $name ($phone) -> user_id=$userId"
    } catch {
        Write-Host "  [$($u.idx)] FAILED: $name ($phone) - $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "[SEED] Creating conversations for $($users[$primaryIdx - 1].name)..."

$primaryToken = $tokens[$primaryIdx]
$primaryUserId = $userIds[$primaryIdx]
$convCount = 0

foreach ($u in $users) {
    if ($u.idx -eq $primaryIdx) { continue }

    $peerId = $userIds[$u.idx]
    if (-not $peerId) { continue }

    try {
        Invoke-RestMethod -Uri "$baseUrl/conversations" -Method POST `
            -ContentType "application/json" `
            -Headers @{ Authorization = "Bearer $primaryToken" } `
            -Body "{`"peer_user_id`":$peerId}" | Out-Null
        $convCount++
    } catch {
        Write-Host "  FAILED: conversation with $($u.name) - $_" -ForegroundColor Red
    }
}

Write-Host "[SEED] Done. Created $convCount conversations."
Write-Host "[SEED] Login as $($users[$primaryIdx - 1].name): phone=$phonePrefix$($users[$primaryIdx - 1].phone_suffix) password=$password"
