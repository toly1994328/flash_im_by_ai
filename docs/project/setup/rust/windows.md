# Windows Rust 开发环境安装指南

> 面向零基础用户，从空白 Windows 系统到能跑 `cargo run` 的完整流程

---

## 前置条件

Rust 在 Windows 上编译需要 C/C++ 链接器。有两条路：

| 方案 | 说明 | 磁盘占用 |
|------|------|---------|
| Visual Studio Build Tools（推荐） | 微软官方 C++ 构建工具 | ~3-5 GB |
| MinGW (MSYS2) | GNU 工具链 | ~1 GB |

本文使用推荐方案。

### 检查是否已安装

PowerShell 中执行：

```powershell
& "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
  -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property displayName
```

有输出（如 `Visual Studio Build Tools 2022`）就是已安装，没输出或报错就需要安装。

---

## 第一步：安装 Visual Studio Build Tools

### 方式 A：脚本一键安装（推荐）

以管理员身份打开 PowerShell，执行：

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools `
  --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

> 安装过程约 5-10 分钟，期间没有界面弹出，耐心等待命令执行完毕即可。

### 方式 B：手动安装

1. 打开 https://visualstudio.microsoft.com/visual-cpp-build-tools/
2. 下载 Build Tools
3. 运行安装程序，勾选「使用 C++ 的桌面开发」
4. 点击安装，等待完成

---

## 第二步：安装 Rust

### 方式 A：winget 安装（推荐）

```powershell
winget install Rustlang.Rustup
```

安装完成后，关闭并重新打开 PowerShell，验证：

```powershell
rustc --version
cargo --version
```

### 方式 B：官网安装器

1. 打开 https://rustup.rs
2. 下载 `rustup-init.exe`
3. 双击运行，按提示选择默认选项（直接回车）
4. 安装完成后重新打开终端

---

## 第三步：配置国内镜像（可选但强烈推荐）

国内访问 crates.io 较慢，配置镜像可以大幅加速依赖下载。

### 一键配置脚本

保存为 `setup_rust_mirror.ps1`，右键「使用 PowerShell 运行」：

```powershell
# ============================================
# Rust 国内镜像配置脚本（字节跳动 RsProxy）
# ============================================

# 1. 设置 rustup 镜像
[System.Environment]::SetEnvironmentVariable("RUSTUP_DIST_SERVER", "https://rsproxy.cn", "User")
[System.Environment]::SetEnvironmentVariable("RUSTUP_UPDATE_ROOT", "https://rsproxy.cn/rustup
---

## 第三步：配置国内镜像（可选但强烈推荐）

国内访问 crates.io 较慢，配置镜像可以大幅加速依赖下载。

### 一键配置脚本

保存为 `setup_rust_mirror.ps1`，右键「使用 PowerShell 运行」：

```powershell
# Rust 国内镜像配置脚本（字节跳动 RsProxy）

# 1. 设置 rustup 镜像
[System.Environment]::SetEnvironmentVariable("RUSTUP_DIST_SERVER", "https://rsproxy.cn", "User")
[System.Environment]::SetEnvironmentVariable("RUSTUP_UPDATE_ROOT", "https://rsproxy.cn/rustup", "User")

# 2. 创建 cargo 配置目录
$cargoConfigDir = "$env:USERPROFILE\.cargo"
if (-not (Test-Path $cargoConfigDir)) {
    New-Item -ItemType Directory -Path $cargoConfigDir -Force | Out-Null
}

# 3. 写入 cargo 镜像配置
$configContent = @"
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[net]
git-fetch-with-cli = true
"@

Set-Content -Path "$cargoConfigDir\config.toml" -Value $configContent -Encoding UTF8

Write-Host ""
Write-Host "Rust mirror configured: rsproxy.cn (sparse)" -ForegroundColor Green
Write-Host "Please restart your terminal." -ForegroundColor Yellow
```

### 手动配置

1. 设置环境变量（系统设置 → 环境变量 → 用户变量 → 新建）：
   - `RUSTUP_DIST_SERVER` = `https://rsproxy.cn`
   - `RUSTUP_UPDATE_ROOT` = `https://rsproxy.cn/rustup`

2. 创建文件 `%USERPROFILE%\.cargo\config.toml`，写入：

```toml
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[net]
git-fetch-with-cli = true
```

---

## 第四步：安装常用工具

```powershell
rustup component add rustfmt    # 代码格式化
rustup component add clippy     # 代码质量检查
cargo install cargo-watch        # 文件变更自动编译
cargo install sccache            # 编译缓存加速
```

配置 sccache（可选）：

```powershell
[System.Environment]::SetEnvironmentVariable("RUSTC_WRAPPER", "sccache", "User")
```

---

## 第五步：验证安装

### 一键验证脚本

```powershell
Write-Host "Checking Rust environment..." -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# rustc
if (Get-Command rustc -ErrorAction SilentlyContinue) {
    Write-Host "  rustc     : $(rustc --version)" -ForegroundColor Green
} else {
    Write-Host "  rustc     : NOT INSTALLED" -ForegroundColor Red
    $allGood = $false
}

# cargo
if (Get-Command cargo -ErrorAction SilentlyContinue) {
    Write-Host "  cargo     : $(cargo --version)" -ForegroundColor Green
} else {
    Write-Host "  cargo     : NOT INSTALLED" -ForegroundColor Red
    $allGood = $false
}

# rustup
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    $ver = & rustup --version 2>&1 | Select-Object -First 1
    Write-Host "  rustup    : $ver" -ForegroundColor Green
} else {
    Write-Host "  rustup    : NOT INSTALLED" -ForegroundColor Red
    $allGood = $false
}

# rustfmt
if (& rustup component list 2>&1 | Select-String "rustfmt.*installed") {
    Write-Host "  rustfmt   : installed" -ForegroundColor Green
} else {
    Write-Host "  rustfmt   : missing (rustup component add rustfmt)" -ForegroundColor Yellow
}

# clippy
if (& rustup component list 2>&1 | Select-String "clippy.*installed") {
    Write-Host "  clippy    : installed" -ForegroundColor Green
} else {
    Write-Host "  clippy    : missing (rustup component add clippy)" -ForegroundColor Yellow
}

# mirror
$configPath = "$env:USERPROFILE\.cargo\config.toml"
if ((Test-Path $configPath) -and ((Get-Content $configPath -Raw) -match "rsproxy")) {
    Write-Host "  mirror    : rsproxy.cn configured" -ForegroundColor Green
} else {
    Write-Host "  mirror    : not configured (downloads may be slow)" -ForegroundColor Yellow
}

Write-Host ""
if ($allGood) { Write-Host "All good! Ready to cargo run." -ForegroundColor Green }
else { Write-Host "Some components missing, see above." -ForegroundColor Yellow }
```

---

## 第六步：跑一下项目

```powershell
git clone <your-repo-url>
cd flash_im/server
cargo run
```

看到 `Flash IM server listening on http://0.0.0.0:9600` 就成功了。浏览器打开 http://localhost:9600/v 验证。

---

## 完整流程

```mermaid
flowchart TD
    A([开始]) --> B{已装 VS Build Tools?}
    B -->|否| C[winget install<br/>VS Build Tools]
    B -->|是| D{已装 Rust?}
    C --> D
    D -->|否| E[winget install<br/>Rustlang.Rustup]
    D -->|是| F{配置镜像?}
    E --> RESTART[重启终端]
    RESTART --> F
    F -->|否| G[运行镜像配置脚本]
    F -->|是| H[安装 rustfmt + clippy]
    G --> H
    H --> I[运行验证脚本]
    I --> J{全部通过?}
    J -->|是| K[cargo run]
    J -->|否| L[按提示修复]
    L --> I
    K --> M([完成])

    style M fill:#2d6,stroke:#333,color:#fff
```

---

## 常见问题

### Q: `cargo build` 报 `linker 'link.exe' not found`

VS Build Tools 没装好。重新执行第一步，确保勾选了「使用 C++ 的桌面开发」。

### Q: 下载依赖特别慢或超时

没配国内镜像。回到第三步配置 rsproxy。

### Q: `cargo run` 报端口被占用

```powershell
netstat -ano | findstr :9600
taskkill /PID <PID> /F
```

### Q: 编译很慢

- 开发时用 `cargo check` 代替 `cargo build`
- 安装 sccache 编译缓存
- 使用 `cargo watch -x check` 自动增量检查
