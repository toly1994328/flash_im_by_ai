# 启动前端客户端：支持 Android（默认） / Windows 桌面
# 用法:
#   powershell -ExecutionPolicy Bypass -File scripts/client/run.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/client/run.ps1 -Platform windows

param(
    [ValidateSet("windows", "android")]
    [string]$Platform = "android",
    [string]$ClientDir = "client",
    [string]$EmulatorAddr = "127.0.0.1:7555"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$clientPath = Join-Path $PSScriptRoot "..\..\$ClientDir"
$clientPath = (Resolve-Path $clientPath).Path

Push-Location $clientPath

try {
    if ($Platform -eq "windows") {
        Write-Host "`[CLIENT`] Starting Flutter on Windows..."
        flutter run -d windows
    }
    elseif ($Platform -eq "android") {
        Write-Host "`[CLIENT`] Detecting Android devices..."
        $devicesRaw = flutter devices --machine 2>$null | Out-String

        $deviceId = $null
        try {
            $devices = $devicesRaw | ConvertFrom-Json
            foreach ($d in $devices) {
                if ($d.targetPlatform -like "*android*") {
                    $deviceId = $d.id
                    break
                }
            }
        } catch {}

        if (-not $deviceId) {
            Write-Host "`[CLIENT`] No Android device found, trying emulator $EmulatorAddr ..."
            adb connect $EmulatorAddr 2>$null | Out-Null
            Start-Sleep -Seconds 2

            $devicesRaw = flutter devices --machine 2>$null | Out-String
            try {
                $devices = $devicesRaw | ConvertFrom-Json
                foreach ($d in $devices) {
                    if ($d.targetPlatform -like "*android*") {
                        $deviceId = $d.id
                        break
                    }
                }
            } catch {}
        }

        if (-not $deviceId) {
            Write-Host "`[CLIENT`] ERROR: No Android device found" -ForegroundColor Red
            exit 1
        }

        Write-Host "`[CLIENT`] Device found: $deviceId"
        Write-Host "`[CLIENT`] Starting Flutter on Android..."
        flutter run -d $deviceId
    }
}
finally {
    Pop-Location
}
