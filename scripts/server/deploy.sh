#!/bin/bash
#
# 闪讯 IM 服务端一键部署脚本
#
# 用法：
#   1. 把项目代码上传到服务器（git clone 或 scp）
#   2. 在服务器上执行：bash scripts/server/deploy.sh
#
# 支持：Ubuntu 22.04 / 24.04（其他 Debian 系发行版应该也行）
# 需要：root 权限
#
# 脚本会做以下事情：
#   - 检测并安装缺失的依赖（Rust、PostgreSQL、protoc 等）
#   - 创建数据库并执行迁移
#   - 编译 Release 二进制
#   - 配置 systemd 服务（开机自启 + 崩溃重启）
#   - 放行防火墙端口
#

set -e

# 非交互模式，避免 apt 弹出对话框卡住脚本
export DEBIAN_FRONTEND=noninteractive

# ─── 颜色输出 ───

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }

# ─── 配置 ───

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
MIGRATIONS_DIR="$SERVER_DIR/migrations"
ENV_FILE="$SERVER_DIR/.env"

DB_NAME="flash_im"
DB_USER="postgres"
DB_PASS="${FLASH_DB_PASS:-postgres}"
DB_HOST="localhost"
DB_PORT="5432"
SERVER_PORT="9600"
JWT_SECRET="${FLASH_JWT_SECRET:-$(openssl rand -hex 32)}"

SERVICE_NAME="flash-im"
BINARY_PATH="$SERVER_DIR/target/release/flash-im"

# ─── 前置检查 ───

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   闪讯 IM 服务端一键部署                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# 必须是 root
if [ "$EUID" -ne 0 ]; then
  fail "请用 root 权限运行：sudo bash scripts/server/deploy.sh"
fi

# 必须是 Debian/Ubuntu 系
if ! command -v apt &> /dev/null; then
  fail "此脚本仅支持 apt 包管理器（Ubuntu/Debian）"
fi

# 检测 swap，内存不足时自动创建
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
SWAP_SIZE=$(free -m | awk '/^Swap:/{print $2}')
if [ "$SWAP_SIZE" -eq 0 ] && [ "$TOTAL_MEM" -lt 4096 ]; then
  warn "内存 ${TOTAL_MEM}MB 且无 swap，Rust 编译可能 OOM，正在创建 2G swap..."
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile &> /dev/null
  swapon /swapfile
  if ! grep -q '/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
  fi
  ok "swap 已创建并启用（2G）"
fi

info "项目目录：$PROJECT_ROOT"
info "服务端目录：$SERVER_DIR"
echo ""

# ─── 第 1 步：检测并安装系统依赖 ───

info "━━━ 第 1 步：检测系统依赖 ━━━"

NEED_APT_UPDATE=false
PACKAGES_TO_INSTALL=""

check_package() {
  if dpkg -s "$1" &> /dev/null; then
    ok "$1 已安装"
  else
    warn "$1 未安装，将自动安装"
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $1"
    NEED_APT_UPDATE=true
  fi
}

check_package "build-essential"
check_package "pkg-config"
check_package "libssl-dev"
check_package "protobuf-compiler"
check_package "postgresql"
check_package "postgresql-contrib"
check_package "git"

if [ -n "$PACKAGES_TO_INSTALL" ]; then
  echo ""
  info "正在更新包索引..."
  apt update
  info "安装缺失的包：$PACKAGES_TO_INSTALL"
  apt install -y $PACKAGES_TO_INSTALL
  ok "系统依赖安装完成"
fi

echo ""

# ─── 第 2 步：检测 Rust ───

info "━━━ 第 2 步：检测 Rust 环境 ━━━"

# 尝试加载 cargo 环境
export PATH="$HOME/.cargo/bin:$PATH"

if command -v rustc &> /dev/null; then
  RUST_VER=$(rustc --version)
  ok "Rust 已安装：$RUST_VER"
else
  warn "Rust 未安装，正在安装..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
  ok "Rust 安装完成：$(rustc --version)"
fi

echo ""

# ─── 第 3 步：配置 PostgreSQL ───

info "━━━ 第 3 步：配置数据库 ━━━"

# 确保 PostgreSQL 在运行
systemctl start postgresql 2>/dev/null || true
systemctl enable postgresql 2>/dev/null || true

if systemctl is-active --quiet postgresql; then
  ok "PostgreSQL 正在运行"
else
  fail "PostgreSQL 启动失败"
fi

# 设置密码
sudo -u postgres psql -c "ALTER USER $DB_USER PASSWORD '$DB_PASS';" &> /dev/null
ok "数据库用户密码已设置"

# 创建数据库（如果不存在）
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
  ok "数据库 '$DB_NAME' 已存在"
else
  sudo -u postgres createdb "$DB_NAME"
  ok "数据库 '$DB_NAME' 已创建"
fi

# 执行迁移
info "执行数据库迁移..."
MIGRATION_COUNT=0
for f in "$MIGRATIONS_DIR"/*.sql; do
  if [ -f "$f" ]; then
    FILENAME=$(basename "$f")
    sudo -u postgres psql -d "$DB_NAME" -f "$f" &> /dev/null
    MIGRATION_COUNT=$((MIGRATION_COUNT + 1))
  fi
done
ok "已执行 $MIGRATION_COUNT 个迁移文件"

echo ""

# ─── 第 4 步：生成 .env 配置 ───

info "━━━ 第 4 步：生成配置文件 ━━━"

if [ -f "$ENV_FILE" ]; then
  warn ".env 已存在，跳过生成（如需重新生成请先删除）"
else
  cat > "$ENV_FILE" << EOF
DATABASE_URL=postgres://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME
JWT_SECRET=$JWT_SECRET
SERVER_PORT=$SERVER_PORT
EOF
  ok ".env 已生成"
fi

# 创建上传目录
mkdir -p "$SERVER_DIR/uploads"
ok "uploads 目录就绪"

echo ""

# ─── 第 5 步：编译 ───

info "━━━ 第 5 步：编译 Release 版本 ━━━"
info "首次编译可能需要 10~15 分钟，请耐心等待..."
echo ""

cd "$SERVER_DIR"
cargo build --release 2>&1 | tail -5

if [ -f "$BINARY_PATH" ]; then
  ok "编译成功：$BINARY_PATH"
  BINARY_SIZE=$(du -h "$BINARY_PATH" | cut -f1)
  info "二进制大小：$BINARY_SIZE"
else
  fail "编译失败，请检查上方错误信息"
fi

echo ""

# ─── 第 6 步：配置 systemd 服务 ───

info "━━━ 第 6 步：配置系统服务 ━━━"

cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Flash IM Server
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
WorkingDirectory=$SERVER_DIR
ExecStart=$BINARY_PATH
Restart=always
RestartSec=5
Environment=RUST_LOG=info

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable $SERVICE_NAME &> /dev/null
systemctl restart $SERVICE_NAME

# 等待 2 秒检查是否启动成功
sleep 2

if systemctl is-active --quiet $SERVICE_NAME; then
  ok "服务已启动并设为开机自启"
else
  warn "服务启动可能失败，查看日志：journalctl -u $SERVICE_NAME -n 20"
fi

echo ""

# ─── 第 7 步：防火墙 ───

info "━━━ 第 7 步：防火墙配置 ━━━"

if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
  ufw allow $SERVER_PORT/tcp &> /dev/null
  ok "ufw 已放行端口 $SERVER_PORT"
else
  ok "ufw 未启用，跳过（所有端口默认开放）"
fi

warn "如果是云服务器，请记得在控制台安全组中放行 $SERVER_PORT 端口"

echo ""

# ─── 完成 ───

echo "╔══════════════════════════════════════════╗"
echo "║   ✅ 部署完成！                          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
info "服务地址：http://$(hostname -I | awk '{print $1}'):$SERVER_PORT"
echo ""
info "常用命令："
echo "  查看状态：systemctl status $SERVICE_NAME"
echo "  查看日志：journalctl -u $SERVICE_NAME -f"
echo "  重启服务：systemctl restart $SERVICE_NAME"
echo "  停止服务：systemctl stop $SERVICE_NAME"
echo ""
info "更新部署："
echo "  cd $PROJECT_ROOT && git pull"
echo "  cd server && cargo build --release"
echo "  systemctl restart $SERVICE_NAME"
echo ""
