# 数据库重置：删库重建 + 重新迁移
# 用法:
#   powershell -ExecutionPolicy Bypass -File scripts/db_reset.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/db_reset.ps1 -Database "flash_im" -Password "postgres"

param(
    [string]$PgHost = "localhost",
    [int]$Port = 5432,
    [string]$User = "postgres",
    [string]$Password = "postgres",
    [string]$Database = "flash_im"
)

$env:PGPASSWORD = $Password

Write-Host "Dropping database: $Database ..."
psql -h $PgHost -p $Port -U $User -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$Database' AND pid <> pg_backend_pid();" 2>&1 | Out-Null
psql -h $PgHost -p $Port -U $User -d postgres -c "DROP DATABASE IF EXISTS $Database;"
Write-Host "Creating database: $Database ..."
psql -h $PgHost -p $Port -U $User -d postgres -c "CREATE DATABASE $Database OWNER $User;"
$env:PGPASSWORD = $null

Write-Host ""
$DatabaseUrl = "postgres://${User}:${Password}@${PgHost}:${Port}/${Database}"
& "$PSScriptRoot\db_init.ps1" -DatabaseUrl $DatabaseUrl
