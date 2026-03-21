param(
    [string]$InstallDir = "C:\toly\SDK\postgres"
)

$PG_BIN = Join-Path $InstallDir "pgsql\bin"
$PG_DATA = Join-Path $InstallDir "data"
$pgCtl = Join-Path $PG_BIN "pg_ctl.exe"
$logFile = Join-Path $InstallDir "pgsql\pg.log"
$PG_PORT = 5432

if (!(Test-Path $pgCtl)) {
    Write-Host "pg_ctl not found: $pgCtl"
    Write-Host "Please run install_postgres.ps1 first."
    exit 1
}

$status = & $pgCtl -D $PG_DATA status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "PostgreSQL is already running."
    exit 0
}

Write-Host "Starting PostgreSQL..."
& $pgCtl -D $PG_DATA -l $logFile -o "-p $PG_PORT" start
Start-Sleep -Seconds 2

$status = & $pgCtl -D $PG_DATA status 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "PostgreSQL started successfully on port $PG_PORT."
}
else {
    Write-Host "Failed to start. Check log: $logFile"
    exit 1
}
