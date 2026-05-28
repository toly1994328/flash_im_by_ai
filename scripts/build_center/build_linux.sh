#!/bin/bash
set -e

# ═══════════════════════════════════════════
# 闪讯 Linux 构建脚本（AppImage）
#
# 用法：
#   bash scripts/build_center/build_linux.sh              # 构建 AppImage
#   bash scripts/build_center/build_linux.sh --run        # 构建后直接运行
#
# 产物输出：
#   scripts/build_center/dest/linux/FlashIM-x86_64.AppImage
# ═══════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLIENT_DIR="$PROJECT_ROOT/client"
DEST_DIR="$SCRIPT_DIR/dest/linux"
APPDIR="$DEST_DIR/AppDir"
APP_NAME="FlashIM"
BINARY_NAME="flash_im"

info() { echo -e "\033[34m[INFO]\033[0m $1"; }
ok()   { echo -e "\033[32m[ OK ]\033[0m $1"; }
fail() { echo -e "\033[31m[FAIL]\033[0m $1"; exit 1; }

echo
echo "╔══════════════════════════════════════════╗"
echo "║   闪讯 Linux 构建（AppImage）             ║"
echo "╚══════════════════════════════════════════╝"
echo

# 1. 构建 Flutter release
info "清理构建缓存..."
cd "$CLIENT_DIR"
flutter clean
info "获取依赖..."
flutter pub get
info "构建 Linux release..."
flutter build linux --release --dart-define-from-file=.env.production

BUNDLE_DIR="$CLIENT_DIR/build/linux/x64/release/bundle"
if [ ! -f "$BUNDLE_DIR/$BINARY_NAME" ]; then
    fail "构建产物未找到：$BUNDLE_DIR/$BINARY_NAME"
fi

# 2. 准备 AppDir 结构
info "准备 AppDir..."
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# 复制 bundle 内容
cp "$BUNDLE_DIR/$BINARY_NAME" "$APPDIR/usr/bin/"
cp -r "$BUNDLE_DIR/data" "$APPDIR/usr/bin/"
cp -r "$BUNDLE_DIR/lib/"* "$APPDIR/usr/lib/"

# 复制图标
ICON_SRC="$CLIENT_DIR/assets/images/logo.png"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$BINARY_NAME.png"
    cp "$ICON_SRC" "$APPDIR/$BINARY_NAME.png"
fi

# 3. 创建 .desktop 文件
cat > "$APPDIR/$BINARY_NAME.desktop" << EOF
[Desktop Entry]
Name=闪讯
Comment=即时通讯
Exec=$BINARY_NAME
Icon=$BINARY_NAME
Type=Application
Categories=Network;InstantMessaging;
EOF

# 4. 创建 AppRun
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH}"
exec "$HERE/usr/bin/flash_im" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# 5. 下载 appimagetool（如果不存在）
APPIMAGETOOL="$DEST_DIR/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
    info "下载 appimagetool..."
    mkdir -p "$DEST_DIR"
    wget -q -O "$APPIMAGETOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGETOOL"
fi

# 6. 打包 AppImage
info "打包 AppImage..."
mkdir -p "$DEST_DIR"
ARCH=x86_64 "$APPIMAGETOOL" "$APPDIR" "$DEST_DIR/$APP_NAME-x86_64.AppImage" 2>/dev/null

if [ -f "$DEST_DIR/$APP_NAME-x86_64.AppImage" ]; then
    ok "AppImage 构建完成"
    info "产物：$DEST_DIR/$APP_NAME-x86_64.AppImage"
    info "大小：$(du -h "$DEST_DIR/$APP_NAME-x86_64.AppImage" | cut -f1)"
else
    fail "AppImage 打包失败"
fi

# 清理 AppDir
rm -rf "$APPDIR"

# 可选：构建后运行
if [ "$1" = "--run" ]; then
    info "启动 AppImage..."
    "$DEST_DIR/$APP_NAME-x86_64.AppImage"
fi

echo
