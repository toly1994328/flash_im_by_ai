# 启动后端服务：检查 PostgreSQL → 停旧进程 → 构建 → 运行
# 用法:
#   powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1

param(
    [string]$PgInstallDir = "C:\toly\SDK\postgres",
    [string]$ServerDir = "server",
    [string]$ProcessName = "flash-im"
)

$ErrorActionPreference = "Continue"

# 修复 PowerShell 终端 UTF-8 编码（emoji 显示）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:RUSTFLAGS = ""

# ─── 1. 检测并启动 PostgreSQL ───

$pgCtl = Join-Path $PgInstallDir "pgsql\bin\pg_ctl.exe"
$pgData = Join-Path $PgInstallDir "data"
$pgLog = Join-Path $PgInstallDir "pgsql\pg.log"

if (!(Test-Path $pgCtl)) {
    Write-Host "[ERROR] pg_ctl not found: $pgCtl"
    Write-Host "        Please run install_postgres.ps1 first."
    exit 1
}

& $pgCtl -D $pgData status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[PG] Starting PostgreSQL..."
    & $pgCtl -D $pgData -l $pgLog -o "-p 5432" start
    Start-Sleep -Seconds 2
    & $pgCtl -D $pgData status 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[PG] Failed to start. Check log: $pgLog"
        exit 1
    }
    Write-Host "[PG] PostgreSQL started."
} else {
    Write-Host "[PG] PostgreSQL is running."
}

# ─── 2. 停止旧的后端进程 ───

$existing = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "[SERVER] Stopping existing $ProcessName (PID: $($existing.Id))..."
    $existing | Stop-Process -Force
    Start-Sleep -Seconds 1
    Write-Host "[SERVER] Stopped."
} else {
    Write-Host "[SERVER] No existing $ProcessName process."
}

# ─── 3. 构建并运行 ───

$serverPath = Join-Path $PSScriptRoot "..\..\$ServerDir"
$serverPath = (Resolve-Path $serverPath).Path

Write-Host "[SERVER] Building..."
Push-Location $serverPath
$buildOutput = cargo build 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Host $buildOutput
    Write-Host "[SERVER] Build failed."
    Pop-Location
    exit 1
}
Write-Host "[SERVER] Build succeeded."

Write-Host "[SERVER] Starting..."
$env:RUST_BACKTRACE = "0"
cargo run 2>&1 | ForEach-Object { Write-Host $_ }
Pop-Location
