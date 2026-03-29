# 重置数据库：删除 → 创建 → 执行迁移脚本
# 用法:
#   powershell -ExecutionPolicy Bypass -File scripts/server/reset_db.ps1

param(
    [string]$PgInstallDir = "C:\toly\SDK\postgres",
    [string]$DbName = "flash_im",
    [string]$PgUser = "postgres"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$psqlExe = Join-Path $PgInstallDir "pgsql\bin\psql.exe"

if (!(Test-Path $psqlExe)) {
    Write-Host "[ERROR] psql not found: $psqlExe"
    exit 1
}

$env:PGPASSWORD = "postgres"
$env:PGCLIENTENCODING = "UTF8"

$migrationFile = Join-Path $PSScriptRoot "..\..\server\migrations\20250320_001_auth.sql"
$migrationFile = (Resolve-Path $migrationFile).Path

Write-Host "[DB] Dropping database '$DbName'..."
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DbName' AND pid <> pg_backend_pid();" 2>$null
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -c "DROP DATABASE IF EXISTS $DbName;"

Write-Host "[DB] Creating database '$DbName'..."
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -c "CREATE DATABASE $DbName;"

Write-Host "[DB] Running migration..."
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -d $DbName -f $migrationFile

$migrationFile2 = Join-Path $PSScriptRoot "..\..\server\migrations\20260329_002_conversations.sql"
$migrationFile2 = (Resolve-Path $migrationFile2).Path
& $psqlExe -U $PgUser -h 127.0.0.1 -p 5432 -w -d $DbName -f $migrationFile2

Write-Host "[DB] Database reset complete."
