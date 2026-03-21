# 数据库初始化：通过 sqlx migrate 执行迁移
# 用法:
#   powershell -ExecutionPolicy Bypass -File scripts/db_init.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/db_init.ps1 -DatabaseUrl "postgres://user:pass@host:5432/dbname"

param(
    [string]$DatabaseUrl = "postgres://postgres:postgres@localhost:5432/flash_im"
)

$ErrorActionPreference = "Stop"
$env:DATABASE_URL = $DatabaseUrl

# 检测 sqlx-cli，未安装则自动安装
if (!(Get-Command sqlx -ErrorAction SilentlyContinue)) {
    Write-Host "sqlx-cli not found, installing..."
    cargo install sqlx-cli --no-default-features --features postgres
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install sqlx-cli."
        exit 1
    }
    Write-Host "sqlx-cli installed."
}

Write-Host "Running sqlx migrations..."
sqlx migrate run --source server/migrations
if ($LASTEXITCODE -ne 0) {
    Write-Host "Migration failed."
    exit 1
}
Write-Host "Migrations completed."
