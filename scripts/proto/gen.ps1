# ============================================================
# Protobuf 协议代码生成脚本
# ============================================================
#
# 使用方式:
#   powershell -ExecutionPolicy Bypass -File scripts/proto/gen.ps1
#
# 功能:
#   1. 自动安装 protoc 编译器（首次运行时）-> C:\toly\SDK\protoc\
#   2. 自动安装 protoc-gen-dart 插件（首次运行时）
#   3. 生成 Rust 代码  -> server/modules/im-ws/src/generated/
#   4. 生成 Dart 代码  -> client/modules/flash_im_core/lib/src/data/proto/
#
# 何时运行:
#   修改 proto/ 目录下的 .proto 文件后执行此脚本
#
# ============================================================

$ErrorActionPreference = "Stop"

$protocVersion = "31.0"
$protoDir = "proto"
$dartOut = "client/modules/flash_im_core/lib/src/data/proto"
$protocInstallDir = "C:\toly\SDK\protoc"
$protocBin = "$protocInstallDir\bin\protoc.exe"
$dartPubBin = "$env:LOCALAPPDATA\Pub\Cache\bin"

# ===== 检查 protoc =====
if (-not (Test-Path $protocBin)) {
    Write-Host "[安装] 正在下载 protoc v$protocVersion..."
    $protocZip = "protoc-$protocVersion-win64.zip"
    $protocUrl = "https://github.com/protocolbuffers/protobuf/releases/download/v$protocVersion/$protocZip"
    $tempZip = "$env:TEMP\$protocZip"

    Invoke-WebRequest -Uri $protocUrl -OutFile $tempZip
    if (Test-Path $protocInstallDir) { Remove-Item -Recurse -Force $protocInstallDir }
    New-Item -ItemType Directory -Force -Path $protocInstallDir | Out-Null
    Expand-Archive -Path $tempZip -DestinationPath $protocInstallDir
    Remove-Item $tempZip

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $binDir = "$protocInstallDir\bin"
    if ($userPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
    }
    Write-Host "[安装] protoc 已安装到: $protocInstallDir"
    Write-Host "[安装] 版本: $(& $protocBin --version 2>&1)"
} else {
    Write-Host "[就绪] protoc: $(& $protocBin --version 2>&1)"
    Write-Host "       位置: $protocInstallDir"
}

# ===== 检查 protoc-gen-dart =====
$dartPluginBin = "$dartPubBin\protoc-gen-dart.bat"
if (-not (Test-Path $dartPluginBin)) {
    Write-Host "[安装] 正在安装 protoc-gen-dart..."
    dart pub global activate protoc_plugin
    Write-Host "[安装] protoc-gen-dart 已安装到: $dartPubBin"
} else {
    Write-Host "[就绪] protoc-gen-dart"
    Write-Host "       位置: $dartPubBin"
}

if ($env:Path -notlike "*$dartPubBin*") {
    $env:Path = "$env:Path;$dartPubBin"
}

Write-Host ""

# ===== 后端 (Rust) =====
Write-Host "[后端] 编译 im-ws（触发 prost-build 生成 Rust 代码）..."
Push-Location server
$env:PROTOC = $protocBin
cargo build -p im-ws
Pop-Location
Write-Host "[后端] 完成 -> server/modules/im-ws/src/generated/"

# ===== 前端 (Dart) =====
Write-Host "[前端] 生成 Dart proto 代码..."
New-Item -ItemType Directory -Force -Path $dartOut | Out-Null
& $protocBin --proto_path=$protoDir --dart_out=$dartOut "$protoDir/ws.proto"
Write-Host "[前端] 完成 -> $dartOut"

Write-Host ""
Write-Host "前后端协议代码已同步更新。"