# Linux Rust 开发环境安装指南

> 面向零基础用户，从空白 Linux 系统到能跑 `cargo run` 的完整流程
> 适用于 Ubuntu/Debian、Fedora/RHEL、Arch 等主流发行版

---

## 前置条件

Rust 在 Linux 上编译需要 C/C++ 编译器、链接器和一些基础开发库。

### 检查是否已安装

```bash
gcc --version   # 或 cc --version
pkg-config --version
```

都有输出就可以跳到第二步。

---

## 第一步：安装系统依赖

根据你的发行版选择对应命令：

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev
```

### Fedora / RHEL / CentOS

```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y pkg-config openssl-devel
```

### Arch Linux

```bash
sudo pacman -Syu --noconfirm base-devel pkg-config openssl
```

> `build-essential` / `Development Tools` / `base-devel` 包含了 gcc、make 等编译工具。
> `libssl-dev` / `openssl-devel` 是很多 Rust crate（如网络库）的常见依赖。

---

## 第二步：安装 Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

按提示选择默认选项（输入 `1` 回车），安装完成后加载环境：

```bash
source "$HOME/.cargo/env"
```

验证：

```bash
rustc --version
cargo --version
```

> 不要用 `apt install rustc` 或 `dnf install rust`，系统包管理器的版本通常很旧。始终用 rustup 安装。

---

## 第三步：配置国内镜像（可选但强烈推荐）

### 一键配置脚本

```bash
#!/bin/bash
# ============================================
# Rust 国内镜像配置脚本（字节跳动 RsProxy）
# 用法: bash setup_rust_mirror.sh
# ============================================

# 检测 shell 配置文件
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.profile"
fi

# 1. 设置 rustup 镜像
echo '' >> "$SHELL_RC"
echo '# Rust mirror (rsproxy.cn)' >> "$SHELL_RC"
echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> "$SHELL_RC"
echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> "$SHELL_RC"

# 2. 写入 cargo 镜像配置
mkdir -p "$HOME/.cargo"
cat > "$HOME/.cargo/config.toml" << 'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[net]
git-fetch-with-cli = true
EOF

echo ""
echo "✅ Rust mirror configured: rsproxy.cn (sparse)"
echo "   Shell RC: $SHELL_RC"
echo "⚠️  Run: source $SHELL_RC"
```

保存为 `setup_rust_mirror.sh`，执行：

```bash
bash setup_rust_mirror.sh
source ~/.bashrc  # 或 source ~/.zshrc
```

### 手动配置

1. 在 `~/.bashrc`（或 `~/.zshrc`）末尾添加：

```bash
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
```

2. 创建 `~/.cargo/config.toml`：

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

```bash
rustup component add rustfmt    # 代码格式化
rustup component add clippy     # 代码质量检查
cargo install cargo-watch        # 文件变更自动编译
cargo install sccache            # 编译缓存加速
```

配置 sccache（可选）：

```bash
echo 'export RUSTC_WRAPPER=sccache' >> ~/.bashrc
source ~/.bashrc
```

### 可选：安装 mold 链接器（大幅加速链接阶段）

```bash
# Ubuntu / Debian
sudo apt install -y mold

# Fedora
sudo dnf install -y mold

# Arch
sudo pacman -S mold
```

在项目的 `.cargo/config.toml` 中启用：

```toml
[target.x86_64-unknown-linux-gnu]
linker = "clang"
rustflags = ["-C", "link-arg=-fuse-ld=mold"]
```

> mold 是目前最快的链接器，可以将链接时间缩短 5-10 倍，对大型 Rust 项目效果显著。

---

## 第五步：验证安装

### 一键验证脚本

```bash
#!/bin/bash
echo "🔍 Checking Rust environment..."
echo ""

ALL_GOOD=true

# rustc
if command -v rustc &> /dev/null; then
    echo "  ✅ rustc     : $(rustc --version)"
else
    echo "  ❌ rustc     : NOT INSTALLED"
    ALL_GOOD=false
fi

# cargo
if command -v cargo &> /dev/null; then
    echo "  ✅ cargo     : $(cargo --version)"
else
    echo "  ❌ cargo     : NOT INSTALLED"
    ALL_GOOD=false
fi

# rustup
if command -v rustup &> /dev/null; then
    echo "  ✅ rustup    : $(rustup --version 2>&1 | head -1)"
else
    echo "  ❌ rustup    : NOT INSTALLED"
    ALL_GOOD=false
fi

# gcc / cc
if command -v gcc &> /dev/null; then
    echo "  ✅ gcc       : $(gcc --version | head -1)"
elif command -v cc &> /dev/null; then
    echo "  ✅ cc        : $(cc --version | head -1)"
else
    echo "  ❌ gcc/cc    : NOT INSTALLED (install build-essential)"
    ALL_GOOD=false
fi

# pkg-config
if command -v pkg-config &> /dev/null; then
    echo "  ✅ pkg-config: $(pkg-config --version)"
else
    echo "  ❌ pkg-config: NOT INSTALLED"
    ALL_GOOD=false
fi

# rustfmt
if rustup component list 2>&1 | grep -q "rustfmt.*installed"; then
    echo "  ✅ rustfmt   : installed"
else
    echo "  ⚠️  rustfmt   : missing (rustup component add rustfmt)"
fi

# clippy
if rustup component list 2>&1 | grep -q "clippy.*installed"; then
    echo "  ✅ clippy    : installed"
else
    echo "  ⚠️  clippy    : missing (rustup component add clippy)"
fi

# mold
if command -v mold &> /dev/null; then
    echo "  ✅ mold      : $(mold --version)"
else
    echo "  ⚠️  mold      : not installed (optional, speeds up linking)"
fi

# mirror
if [ -f "$HOME/.cargo/config.toml" ] && grep -q "rsproxy" "$HOME/.cargo/config.toml"; then
    echo "  ✅ mirror    : rsproxy.cn configured"
else
    echo "  ⚠️  mirror    : not configured (downloads may be slow)"
fi

echo ""
if $ALL_GOOD; then
    echo "🎉 All good! Ready to cargo run."
else
    echo "⚠️  Some components missing, see above."
fi
```

---

## 第六步：跑一下项目

```bash
git clone <your-repo-url>
cd flash_im/server
cargo run
```

看到 `Flash IM server listening on http://0.0.0.0:9600` 就成功了。

```bash
curl http://localhost:9600/v
```

---

## 完整流程

```mermaid
flowchart TD
    A([开始]) --> B{已装 gcc + pkg-config?}
    B -->|否| C[apt/dnf/pacman<br/>安装 build-essential]
    B -->|是| D{已装 Rust?}
    C --> D
    D -->|否| E[curl rustup.rs 安装]
    D -->|是| F{配置镜像?}
    E --> SRC[source ~/.cargo/env]
    SRC --> F
    F -->|否| G[运行镜像配置脚本]
    F -->|是| H[安装 rustfmt + clippy]
    G --> H
    H --> MOLD{安装 mold?}
    MOLD -->|可选| MOLD_I[apt/dnf install mold]
    MOLD -->|跳过| I
    MOLD_I --> I[运行验证脚本]
    I --> J{全部通过?}
    J -->|是| K[cargo run]
    J -->|否| L[按提示修复]
    L --> I
    K --> M([完成])

    style M fill:#2d6,stroke:#333,color:#fff
```

---

## 常见问题

### Q: `cargo build` 报 `linker 'cc' not found`

没装编译工具链。回到第一步安装 `build-essential`（Ubuntu）或 `Development Tools`（Fedora）。

### Q: 报 `failed to run custom build command` 提到 openssl

缺少 openssl 开发库：

```bash
# Ubuntu/Debian
sudo apt install -y libssl-dev

# Fedora
sudo dnf install -y openssl-devel
```

### Q: 下载依赖慢或超时

没配国内镜像。回到第三步配置 rsproxy。

### Q: 编译很慢

- 开发时用 `cargo check` 代替 `cargo build`
- 安装 sccache 编译缓存
- 安装 mold 链接器（第四步）
- 使用 `cargo watch -x check` 自动增量检查

### Q: 权限问题 `permission denied`

不要用 `sudo cargo` 或 `sudo rustup`。Rust 工具链安装在用户目录下，不需要 root 权限。如果之前误用了 sudo，修复：

```bash
sudo chown -R $(whoami) ~/.cargo ~/.rustup
```
