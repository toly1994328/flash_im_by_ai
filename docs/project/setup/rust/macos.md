# macOS Rust 开发环境安装指南

> 面向零基础用户，从空白 macOS 系统到能跑 `cargo run` 的完整流程

---

## 前置条件

Rust 在 macOS 上编译需要 Xcode Command Line Tools（提供 C/C++ 编译器和链接器）。

### 检查是否已安装

```bash
xcode-select -p
```

输出路径（如 `/Library/Developer/CommandLineTools`）就是已安装，报错就需要安装。

---

## 第一步：安装 Xcode Command Line Tools

```bash
xcode-select --install
```

弹出对话框后点击「安装」，等待完成（约 5-10 分钟）。

> 不需要安装完整的 Xcode（~12GB），Command Line Tools（~1.5GB）就够了。

---

## 第二步：安装 Rust

### 方式 A：一键脚本（推荐）

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

### 方式 B：Homebrew 安装

```bash
brew install rustup
rustup-init
```

---

## 第三步：配置国内镜像（可选但强烈推荐）

### 一键配置脚本

```bash
#!/bin/bash
# ============================================
# Rust 国内镜像配置脚本（字节跳动 RsProxy）
# 用法: bash setup_rust_mirror.sh
# ============================================

SHELL_RC="$HOME/.zshrc"
# 如果用 bash，取消下面这行的注释
# SHELL_RC="$HOME/.bashrc"

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
echo "⚠️  Run: source $SHELL_RC"
```

保存为 `setup_rust_mirror.sh`，执行：

```bash
bash setup_rust_mirror.sh
source ~/.zshrc
```

### 手动配置

1. 在 `~/.zshrc`（或 `~/.bashrc`）末尾添加：

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
echo 'export RUSTC_WRAPPER=sccache' >> ~/.zshrc
source ~/.zshrc
```

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

# xcode cli tools
if xcode-select -p &> /dev/null; then
    echo "  ✅ xcode-cli : $(xcode-select -p)"
else
    echo "  ❌ xcode-cli : NOT INSTALLED (xcode-select --install)"
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

看到 `Flash IM server listening on http://0.0.0.0:9600` 就成功了。浏览器打开 http://localhost:9600/v 验证。

---

## 完整流程

```mermaid
flowchart TD
    A([开始]) --> B{已装 Xcode CLI Tools?}
    B -->|否| C[xcode-select --install]
    B -->|是| D{已装 Rust?}
    C --> D
    D -->|否| E[curl rustup.rs 安装]
    D -->|是| F{配置镜像?}
    E --> SRC[source ~/.cargo/env]
    SRC --> F
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

### Q: 提示 `xcrun: error: invalid active developer path`

Xcode CLI Tools 没装或损坏，重新安装：

```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### Q: Apple Silicon (M1/M2/M3) 有兼容问题吗？

没有。rustup 默认安装 `aarch64-apple-darwin` 目标，原生支持 Apple Silicon。

### Q: 下载依赖慢或超时

没配国内镜像。回到第三步配置 rsproxy。

### Q: 编译很慢

- 开发时用 `cargo check` 代替 `cargo build`
- 安装 sccache 编译缓存
- 使用 `cargo watch -x check` 自动增量检查
