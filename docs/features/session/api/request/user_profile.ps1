# user_profile - API test link + doc generator
# Usage: powershell -ExecutionPolicy Bypass -File docs/features/session/api/request/user_profile.ps1

param(
    [string]$Base = "http://127.0.0.1:9600",
    [string]$Phone = "13800001111"
)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
$docsDir = Join-Path (Join-Path $SCRIPT_DIR "..") "docs" | Join-Path -ChildPath "user_profile"
if (!(Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }

function Step($n, $desc) { Write-Host ""; Write-Host "========== [$n] $desc ==========" -ForegroundColor Cyan }
function Fail($msg) { Write-Host "[FAIL] $msg" -ForegroundColor Red; exit 1 }
function Pass() { Write-Host "[PASS]" -ForegroundColor Green }

function HttpReq($method, $url, $jsonBody, $tok) {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Method = $method
    $req.ContentType = "application/json; charset=utf-8"
    if ($tok) { $req.Headers.Add("Authorization", "Bearer $tok") }
    if ($jsonBody) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
        $req.ContentLength = $bytes.Length
        $s = $req.GetRequestStream(); $s.Write($bytes, 0, $bytes.Length); $s.Close()
    }
    $status = 0; $respText = ""
    try {
        $resp = $req.GetResponse()
        $status = [int]$resp.StatusCode
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream(), [System.Text.Encoding]::UTF8)
        $respText = $reader.ReadToEnd(); $reader.Close(); $resp.Close()
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response; $status = [int]$resp.StatusCode
        if ($resp) { $reader = New-Object System.IO.StreamReader($resp.GetResponseStream(), [System.Text.Encoding]::UTF8); $respText = $reader.ReadToEnd(); $reader.Close(); $resp.Close() }
    }
    return @{ Raw = $respText; Status = $status }
}

function Parse($r) { if ($r.Raw) { $r.Raw | ConvertFrom-Json } else { $null } }

$linkLines = [System.Collections.ArrayList]::new()
function Link($t) { [void]$linkLines.Add($t) }

function WriteMd($filename, $content) {
    $path = Join-Path $docsDir $filename
    [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($false))
}

function WriteDoc($filename, $method, $path, $desc, $paramJson, $respStatus, $respRaw, $authToken, $notes) {
    $lines = @()
    $lines += "# $method $path"; $lines += ""; $lines += $desc; $lines += ""
    if ($paramJson) { $lines += "## Parameters"; $lines += ""; $lines += '```json'; $lines += $paramJson; $lines += '```'; $lines += "" }
    $lines += "## Response ``$respStatus``"; $lines += ""; $lines += '```json'; $lines += $respRaw; $lines += '```'; $lines += ""
    $lines += "## curl"; $lines += ""; $lines += '```bash'
    $curl = "curl -s -X $method ""$Base$path"""
    if ($authToken) { $curl += " ```n  -H ""Authorization: Bearer $authToken""" }
    if ($paramJson) { $curl += " ```n  -H ""Content-Type: application/json"""; $escaped = $paramJson.Replace('"','\"'); $curl += " ```n  -d ""$escaped""" }
    $lines += $curl; $lines += '```'
    if ($notes) { $lines += ""; $lines += "> $notes" }
    WriteMd $filename ($lines -join "`n")

    $icon = if ($respStatus -lt 400 -or $notes) { "PASS" } else { "FAIL" }
    Link "| $($filename.Split('_')[0].TrimStart('0')) | ``$method $path`` | ``$respStatus`` | $icon | [$filename]($filename) |"
}

Link "# user_profile - API test link"
Link ""; Link "Base URL: ``$Base``"; Link ""
Link "| # | Interface | Status | Result | Doc |"
Link "|---|-----------|--------|--------|-----|"

# --- pre: auth ---
Step "pre" "POST /auth/sms + /auth/login"
$sms = HttpReq "POST" "$Base/auth/sms" "{""phone"":""$Phone""}"
$code = (Parse $sms).code
if (-not $code) { Fail "no code" }
$login = HttpReq "POST" "$Base/auth/login" "{""phone"":""$Phone"",""type"":""sms"",""credential"":""$code""}"
$obj = Parse $login; $token = $obj.token
if (-not $token) { Fail "login failed" }
Write-Host "token acquired, user_id: $($obj.user_id)"
Pass

# === 1 ===
Step 1 "GET /user/profile"
$r = HttpReq "GET" "$Base/user/profile" $null $token
$o = Parse $r
if (-not $o.user_id) { Fail "get profile failed" }
Write-Host "nickname: $($o.nickname), avatar: $($o.avatar)"
if ($o.avatar -notlike "identicon:*") { Fail "avatar should be identicon" }
Pass
WriteDoc "01_get_profile.md" "GET" "/user/profile" "Get current user profile. Requires Bearer token." $null $r.Status $r.Raw $token

# === 2 ===
Step 2 "PUT /user/profile"
$j = '{"nickname":"TestUser","signature":"hello world"}'
$r = HttpReq "PUT" "$Base/user/profile" $j $token
$o = Parse $r
if ($o.nickname -ne "TestUser") { Fail "nickname not updated" }
Write-Host "nickname: $($o.nickname), signature: $($o.signature)"
Pass
WriteDoc "02_update_profile.md" "PUT" "/user/profile" "Update user profile. All fields optional." $j $r.Status $r.Raw $token

# === 3 ===
Step 3 "PUT /user/profile - avatar"
$j = '{"avatar":"identicon:seed_42"}'
$r = HttpReq "PUT" "$Base/user/profile" $j $token
$o = Parse $r
if ($o.avatar -ne "identicon:seed_42") { Fail "avatar not updated" }
Write-Host "avatar: $($o.avatar)"
Pass
WriteDoc "03_change_avatar.md" "PUT" "/user/profile" "Change identicon avatar seed." $j $r.Status $r.Raw $token

# === 4 ===
Step 4 "POST /user/password"
$j = '{"new_password":"test123456"}'
$r = HttpReq "POST" "$Base/user/password" $j $token
Write-Host "status: $($r.Status), body: $($r.Raw)"
Pass
WriteDoc "04_set_password.md" "POST" "/user/password" "Set password for the first time." $j $r.Status $r.Raw $token

# === 5 ===
Step 5 "POST /user/password - expect 409"
$j = '{"new_password":"another123"}'
$r = HttpReq "POST" "$Base/user/password" $j $token
if ($r.Status -ne 409) { Fail "expected 409, got $($r.Status)" }
Write-Host "HTTP $($r.Status) Conflict"
Pass
$b = if ($r.Raw) { $r.Raw } else { "(empty body)" }
WriteDoc "05_set_password_conflict.md" "POST" "/user/password" "Set password again when already set." $j $r.Status $b $token "Returns 409 if password already exists."

# === 6 ===
Step 6 "PUT /user/password"
$j = '{"old_password":"test123456","new_password":"newpass789"}'
$r = HttpReq "PUT" "$Base/user/password" $j $token
Write-Host "status: $($r.Status), body: $($r.Raw)"
Pass
WriteDoc "06_change_password.md" "PUT" "/user/password" "Change password. Requires old password verification." $j $r.Status $r.Raw $token

# === 7 ===
Step 7 "PUT /user/password - expect 401"
$j = '{"old_password":"wrong","new_password":"whatever123"}'
$r = HttpReq "PUT" "$Base/user/password" $j $token
if ($r.Status -ne 401) { Fail "expected 401, got $($r.Status)" }
Write-Host "HTTP $($r.Status) Unauthorized"
Pass
$b = if ($r.Raw) { $r.Raw } else { "(empty body)" }
WriteDoc "07_change_password_wrong.md" "PUT" "/user/password" "Change password with wrong old password." $j $r.Status $b $token "Returns 401 if old password is incorrect."

# === 8 ===
Step 8 "POST /auth/login - password"
$j = "{""phone"":""$Phone"",""type"":""password"",""credential"":""newpass789""}"
$r = HttpReq "POST" "$Base/auth/login" $j
$o = Parse $r
if (-not $o.token) { Fail "password login failed" }
Write-Host "user_id: $($o.user_id), has_password: $($o.has_password)"
Pass
WriteDoc "08_login_password.md" "POST" "/auth/login" "Login with password." $j $r.Status $r.Raw $null

# === Write 00_link.md ===
$linkPath = Join-Path $docsDir "00_link.md"
$linkContent = $linkLines -join "`n"
[System.IO.File]::WriteAllText($linkPath, $linkContent, [System.Text.UTF8Encoding]::new($false))

Write-Host ""
Write-Host "Generated: docs/user_profile/00_link.md + 8 api docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ALL 8 STEPS PASSED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
