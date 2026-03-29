# ============================================================
# 重置数据库 + 种子数据 一键脚本
# ============================================================
# Usage:
#   1. 先启动服务: powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1
#   2. 新开终端执行: powershell -ExecutionPolicy Bypass -File scripts/database/reset_and_seed.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

# Step 1: 重置数据库
Write-Host "[1/2] 重置数据库..."
& powershell -ExecutionPolicy Bypass -File "$root\scripts\server\reset_db.ps1"

# Step 2: 等待服务就绪（需要用户已在另一个终端启动服务）
Write-Host "[2/2] 等待服务就绪..."
$ready = $false
for ($i = 0; $i -lt 15; $i++) {
    try {
        $null = Invoke-WebRequest -Uri "http://127.0.0.1:9600/user/profile" -Method GET -ErrorAction Stop
        $ready = $true; break
    } catch {
        if ($_.Exception.Response) { $ready = $true; break }
        Write-Host "  等待中... ($($i+1)/15)"
        Start-Sleep -Seconds 2
    }
}

if (-not $ready) {
    Write-Host "[WARN] 服务未就绪，请确认已启动后端服务" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1"
    exit 1
}

# Step 3: 执行种子数据
Write-Host "执行种子数据..."
& powershell -ExecutionPolicy Bypass -File "$root\scripts\database\im_seed\seed.ps1"

Write-Host ""
Write-Host "完成。"