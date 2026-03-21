param(
    [string]$InstallDir = "C:\toly\SDK\postgres"
)

$ErrorActionPreference = "Stop"
$PG_VERSION = "18.3-1"
$PG_ZIP_URL = "https://get.enterprisedb.com/postgresql/postgresql-$PG_VERSION-windows-x64-binaries.zip"
$PG_DATA = Join-Path $InstallDir "data"
$PG_PORT = 5432
$PG_USER = "postgres"
$PG_PASSWORD = "postgres"

Write-Host "========================================"
Write-Host " PostgreSQL $PG_VERSION install"
Write-Host " Dir: $InstallDir"
Write-Host "========================================"

if (!(Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Host "[1/5] Created: $InstallDir"
}
else {
    Write-Host "[1/5] Exists: $InstallDir"
}

$PG_BIN = Join-Path $InstallDir "pgsql\bin"
$pgCtl = Join-Path $PG_BIN "pg_ctl.exe"
$zipFile = Join-Path $InstallDir "postgresql.zip"

if (!(Test-Path $pgCtl)) {
    Write-Host "[2/5] Downloading PostgreSQL (~200MB)..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $PG_ZIP_URL -OutFile $zipFile -UseBasicParsing
    Write-Host "      Extracting..."
    Expand-Archive -Path $zipFile -DestinationPath $InstallDir -Force
    Remove-Item $zipFile -Force
    Write-Host "      Done"
}
else {
    Write-Host "[2/5] PostgreSQL already exists, skip"
}

$initdb = Join-Path $PG_BIN "initdb.exe"
$psqlExe = Join-Path $PG_BIN "psql.exe"
$pgVersionFile = Join-Path $PG_DATA "PG_VERSION"

if (!(Test-Path $pgVersionFile)) {
    Write-Host "[3/5] Initializing database..."
    & $initdb -D $PG_DATA -U $PG_USER -E UTF8 --locale=C -A trust
    if ($LASTEXITCODE -ne 0) {
        Write-Host "      Init failed!"
        exit 1
    }
    Write-Host "      Init done"
}
else {
    Write-Host "[3/5] Data dir exists, skip"
}

Write-Host "[4/5] Starting PostgreSQL..."
$logFile = Join-Path $InstallDir "pgsql\pg.log"
& $pgCtl -D $PG_DATA status 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      PostgreSQL is already running, skip"
}
else {
    & $pgCtl -D $PG_DATA -l $logFile -o "-p $PG_PORT" start
    Start-Sleep -Seconds 3
    & $pgCtl -D $PG_DATA status 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "      PostgreSQL started!"
    }
    else {
        Write-Host "      Start may have failed. Check log: $logFile"
        exit 1
    }
}

Write-Host "[5/5] Configuring database..."
$env:PGPASSWORD = $PG_PASSWORD
$dbCheck = & $psqlExe -U $PG_USER -p $PG_PORT -tAc "SELECT 1 FROM pg_database WHERE datname='flash_im';" postgres 2>&1
if ($dbCheck -match "1") {
    Write-Host "      Database flash_im already exists, skip"
}
else {
    & $psqlExe -U $PG_USER -p $PG_PORT -c "ALTER USER postgres PASSWORD '$PG_PASSWORD';" postgres
    & $psqlExe -U $PG_USER -p $PG_PORT -c "CREATE DATABASE flash_im OWNER postgres;" postgres

    $hbaPath = Join-Path $PG_DATA "pg_hba.conf"
    $hbaContent = Get-Content $hbaPath -Raw
    if ($hbaContent -match "trust") {
        $hbaContent = $hbaContent.Replace("trust", "md5")
        Set-Content -Path $hbaPath -Value $hbaContent -NoNewline
        & $pgCtl -D $PG_DATA reload
        Write-Host "      Configured"
    }
}
$env:PGPASSWORD = $null

# Set PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -split ";" | Where-Object { $_ -eq $PG_BIN }) {
    Write-Host "[PATH] Already in user PATH, skip"
}
else {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$PG_BIN", "User")
    $env:Path = "$env:Path;$PG_BIN"
    Write-Host "[PATH] Added $PG_BIN to user PATH"
}

Write-Host ""
Write-Host "========================================"
Write-Host " Done!"
Write-Host "========================================"
Write-Host ""
Write-Host " Host:     localhost"
Write-Host " Port:     $PG_PORT"
Write-Host " User:     $PG_USER"
Write-Host " Password: $PG_PASSWORD"
Write-Host " Database: flash_im"
Write-Host ""
Write-Host " Connection string:"
Write-Host " postgres://postgres:postgres@localhost:5432/flash_im"
Write-Host ""
Write-Host " Commands (add to PATH: $PG_BIN):"
Write-Host "   Start:  pg_ctl -D $PG_DATA start"
Write-Host "   Stop:   pg_ctl -D $PG_DATA stop"
Write-Host "   Status: pg_ctl -D $PG_DATA status"
Write-Host "   Connect: psql -U postgres -d flash_im"
