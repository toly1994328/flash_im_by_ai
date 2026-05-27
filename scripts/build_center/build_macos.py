#!/usr/bin/env python3
"""
闪讯 macOS 构建 & 分发脚本

用法：
  python3 scripts/build_center/build_macos.py                # 仅构建 .app
  python3 scripts/build_center/build_macos.py --dmg          # 构建 + 签名 + 打包 DMG + 公证
  python3 scripts/build_center/build_macos.py --dmg --no-sign  # 构建 + 打包 DMG（跳过签名和公证）
  python3 scripts/build_center/build_macos.py --dmg --no-notarize  # 构建 + 签名 + 打包 DMG（跳过公证）
  python3 scripts/build_center/build_macos.py --upload       # 构建 + 上传到 App Store Connect

核心流程（基于实际成功经验）：
  构建 → 在原始目录签名 .app → 打包 DMG → 直接公证 DMG

凭证配置在 client/ios/.env.publish：
  DEVELOPER_ID_SIGN_IDENTITY     — 签名身份（必须包含 "Developer ID Application: " 前缀！）
  APPLE_ID                       — 公证用 Apple ID
  TEAM_ID                        — 公证用 Team ID
  APP_SPECIFIC_PASSWORD          — 公证用 App 专用密码
  APP_STORE_CONNECT_ISSUER_ID    — App Store Connect API（上传用）
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_KEY_PATH

产物输出：
  scripts/build_center/dest/macos/flash_im.dmg
"""

import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
DEST_BASE = os.path.join(SCRIPT_DIR, "dest", "macos")
PUBLISH_ENV = os.path.join(CLIENT_DIR, "ios", ".env.publish")
DMG_NAME = "flash_im.dmg"


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def warn(msg):
    print(f"\033[33m[WARN]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def run(cmd, cwd=None, capture=False):
    r = subprocess.run(cmd, cwd=cwd or CLIENT_DIR, shell=True,
                       capture_output=capture, text=True)
    if r.returncode != 0:
        if capture:
            fail(f"命令失败：{cmd}\n{r.stderr or r.stdout}")
        else:
            fail(f"命令失败：{cmd}")
    return r


def file_size(path):
    size = os.path.getsize(path)
    if size < 1024 * 1024:
        return f"{size / 1024:.1f} KB"
    return f"{size / (1024 * 1024):.1f} MB"


def load_publish_env():
    """从 client/ios/.env.publish 加载凭证"""
    if not os.path.isfile(PUBLISH_ENV):
        return
    with open(PUBLISH_ENV) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if value:
                    os.environ.setdefault(key, value)


def find_app():
    """查找构建产物 .app（在原始构建目录中）"""
    release_dir = os.path.join(CLIENT_DIR, "build", "macos", "Build", "Products", "Release")
    if not os.path.isdir(release_dir):
        return None
    for item in os.listdir(release_dir):
        if item.endswith(".app"):
            return os.path.join(release_dir, item)
    return None


def build():
    """构建 macOS Release"""
    env_file = os.path.join(CLIENT_DIR, ".env.production")
    if not os.path.isfile(env_file):
        env_file = os.path.join(CLIENT_DIR, ".env.dev")
    if not os.path.isfile(env_file):
        fail("未找到环境配置文件")

    env_name = os.path.basename(env_file)
    info(f"配置：{env_name}")

    info("清理...")
    run("flutter clean")
    info("获取依赖...")
    run("flutter pub get")
    info("构建 macOS Release...")
    run(f"flutter build macos --release --dart-define-from-file={env_file}")

    app_path = find_app()
    if not app_path:
        fail("构建产物 .app 未找到")

    ok("构建完成")
    info(f"产物：{app_path}")
    return app_path


def sign_app(app_path):
    """在原始构建目录签名（保留符号链接，确保成功）"""
    load_publish_env()
    identity = os.environ.get("DEVELOPER_ID_SIGN_IDENTITY")
    if not identity:
        fail(
            "未配置签名身份。请在 client/ios/.env.publish 中添加：\n"
            "         DEVELOPER_ID_SIGN_IDENTITY=Developer ID Application: 你的名字 (TeamID)"
        )

    info(f"签名中（{identity}）...")

    # 先签名所有框架
    frameworks_dir = os.path.join(app_path, "Contents", "Frameworks")
    if os.path.isdir(frameworks_dir):
        for item in sorted(os.listdir(frameworks_dir)):
            item_path = os.path.join(frameworks_dir, item)
            if item.endswith(".framework"):
                info(f"  签名：{item}")
                r = subprocess.run(
                    f'codesign --force --options runtime --timestamp '
                    f'--sign "{identity}" "{item_path}"',
                    shell=True
                )
                if r.returncode != 0:
                    fail(f"框架签名失败：{item}")

    # 再深度签名整个应用
    info("  签名：flash_im.app")
    r = subprocess.run(
        f'codesign --force --deep --options runtime --timestamp '
        f'--sign "{identity}" "{app_path}"',
        shell=True
    )
    if r.returncode != 0:
        fail("App 签名失败")

    ok("签名完成")


def create_dmg(app_path):
    """打包 DMG（带自定义背景和图标位置）"""
    os.makedirs(DEST_BASE, exist_ok=True)
    dmg_path = os.path.join(DEST_BASE, DMG_NAME)
    if os.path.isfile(dmg_path):
        os.remove(dmg_path)

    bg_path = os.path.join(SCRIPT_DIR, "background.png")
    info("打包 DMG...")

    # 检测 create-dmg，没有则尝试安装
    has_create_dmg = shutil.which("create-dmg")
    if not has_create_dmg:
        info("未检测到 create-dmg，尝试安装...")
        r = subprocess.run("brew install create-dmg", shell=True)
        if r.returncode == 0:
            has_create_dmg = shutil.which("create-dmg")
        else:
            warn("create-dmg 安装失败，将使用 hdiutil 兜底")

    if has_create_dmg and os.path.isfile(bg_path):
        # 使用 create-dmg 生成带自定义背景的 DMG
        cmd = (
            f'create-dmg'
            f' --volname "闪讯"'
            f' --background "{bg_path}"'
            f' --window-pos 360 100'
            f' --window-size 800 600'
            f' --icon-size 80'
            f' --icon "flash_im.app" 230 285'
            f' --app-drop-link 570 285'
            f' --no-internet-enable'
            f' "{dmg_path}" "{app_path}"'
        )
        r = subprocess.run(cmd, shell=True)
        if r.returncode != 0:
            warn("create-dmg 失败，回退到 hdiutil")
            run(f'hdiutil create -volname "闪讯" -srcfolder "{app_path}" '
                f'-ov -format UDZO "{dmg_path}"', cwd=DEST_BASE)
    else:
        # 回退到 hdiutil
        run(f'hdiutil create -volname "闪讯" -srcfolder "{app_path}" '
            f'-ov -format UDZO "{dmg_path}"', cwd=DEST_BASE)

    ok("DMG 打包完成")
    info(f"产物：{dmg_path}")
    info(f"大小：{file_size(dmg_path)}")
    return dmg_path


def notarize_dmg(dmg_path):
    """直接公证 DMG 文件"""
    load_publish_env()
    apple_id = os.environ.get("APPLE_ID")
    team_id = os.environ.get("TEAM_ID")
    password = os.environ.get("APP_SPECIFIC_PASSWORD")

    if not all([apple_id, team_id, password]):
        fail(
            "公证凭证不完整。请在 client/ios/.env.publish 中添加：\n"
            "         APPLE_ID=your@email.com\n"
            "         TEAM_ID=你的TeamID\n"
            "         APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx"
        )

    info("提交公证（可能需要几分钟）...")
    cmd = (
        f'xcrun notarytool submit "{dmg_path}"'
        f' --apple-id "{apple_id}"'
        f' --team-id "{team_id}"'
        f' --password "{password}"'
        f' --wait'
    )
    r = subprocess.run(cmd, shell=True)

    if r.returncode != 0:
        fail("公证失败，请检查凭证和网络")

    ok("公证完成")


def upload_to_app_store(skip_archive=False):
    """通过 Xcode 自动签名 + Archive + 上传到 App Store Connect"""
    load_publish_env()

    issuer_id = os.environ.get("APP_STORE_CONNECT_ISSUER_ID")
    key_id = os.environ.get("APP_STORE_CONNECT_KEY_ID")
    key_path = os.environ.get("APP_STORE_CONNECT_KEY_PATH")

    if not all([issuer_id, key_id, key_path]):
        fail(
            "上传凭证不完整，请检查 client/ios/.env.publish 中以下字段：\n"
            "         APP_STORE_CONNECT_ISSUER_ID\n"
            "         APP_STORE_CONNECT_KEY_ID\n"
            "         APP_STORE_CONNECT_KEY_PATH"
        )

    key_path = os.path.expanduser(key_path)
    if not os.path.isfile(key_path):
        fail(f"API Key 文件不存在：{key_path}")

    # 确保 Key 在 altool/notarytool 能找到的位置
    altool_key_dir = os.path.expanduser("~/.appstoreconnect/private_keys")
    expected_key_path = os.path.join(altool_key_dir, f"AuthKey_{key_id}.p8")
    if not os.path.isfile(expected_key_path):
        os.makedirs(altool_key_dir, exist_ok=True)
        shutil.copy2(key_path, expected_key_path)

    workspace = os.path.join(CLIENT_DIR, "macos", "Runner.xcworkspace")
    archive_path = os.path.join(DEST_BASE, "flash_im.xcarchive")
    export_path = os.path.join(DEST_BASE, "export")

    # 1. Archive（Xcode 自动签名）
    if not skip_archive:
        info("Archive 中（Xcode 自动签名）...")
        team_id = os.environ.get("TEAM_ID", "")
        archive_cmd = (
            f'xcodebuild archive'
            f' -workspace "{workspace}"'
            f' -scheme Runner'
            f' -configuration Release'
            f' -archivePath "{archive_path}"'
            f' -destination "generic/platform=macOS"'
            f' DEVELOPMENT_TEAM="{team_id}"'
            f' FLUTTER_BUILD_MODE=release'
        )
        r = subprocess.run(archive_cmd, shell=True, cwd=CLIENT_DIR)
        if r.returncode != 0:
            fail("Archive 失败")
        ok("Archive 完成")
    else:
        if not os.path.isdir(archive_path):
            fail(f"未找到已有 Archive：{archive_path}\n请先执行 --upload 完整构建")

    # 2. 创建 ExportOptions.plist
    team_id = os.environ.get("TEAM_ID", "")
    export_options = os.path.join(DEST_BASE, "ExportOptions.plist")
    with open(export_options, "w") as f:
        f.write(f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>{team_id}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>3rd Party Mac Developer Application</string>
    <key>installerSigningCertificate</key>
    <string>3rd Party Mac Developer Installer</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.toly1994.flashIm</key>
        <string>闪讯Mac</string>
    </dict>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
''')

    # 3. Export + Upload（自动上传到 App Store Connect）
    info("上传到 App Store Connect...")
    export_cmd = (
        f'xcodebuild -exportArchive'
        f' -archivePath "{archive_path}"'
        f' -exportOptionsPlist "{export_options}"'
        f' -exportPath "{export_path}"'
        f' -allowProvisioningUpdates'
        f' -authenticationKeyPath "{key_path}"'
        f' -authenticationKeyID "{key_id}"'
        f' -authenticationKeyIssuerID "{issuer_id}"'
    )
    r = subprocess.run(export_cmd, shell=True, cwd=CLIENT_DIR)

    if r.returncode == 0:
        ok("上传成功！已提交到 App Store Connect")
        info("前往查看处理状态：https://appstoreconnect.apple.com")
    else:
        fail("上传失败，请检查上方日志中的错误信息")


def main():
    do_dmg = "--dmg" in sys.argv
    do_upload = "--upload" in sys.argv
    upload_only = "--upload-only" in sys.argv
    no_sign = "--no-sign" in sys.argv
    no_notarize = "--no-notarize" in sys.argv

    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 macOS 构建                        ║")
    print("╚══════════════════════════════════════════╝")
    print()

    if do_dmg:
        if no_sign:
            info("模式：构建 + 打包 DMG（跳过签名和公证）")
        elif no_notarize:
            info("模式：构建 + 签名 + 打包 DMG（跳过公证）")
        else:
            info("模式：构建 + 签名 + 打包 DMG + 公证")
    elif do_upload:
        info("模式：构建 + 上传 App Store Connect")
    elif upload_only:
        info("模式：仅上传（使用已有 Archive）")
    else:
        info("模式：仅构建")
    print()

    # 清理旧产物（upload-only 不清理）
    if not upload_only and os.path.isdir(DEST_BASE):
        shutil.rmtree(DEST_BASE)
        info("已清理旧产物")

    if do_upload:
        # App Store 模式：先 flutter build 生成必要文件，再 xcodebuild archive
        os.makedirs(DEST_BASE, exist_ok=True)
        info("清理...")
        run("flutter clean")
        info("获取依赖...")
        run("flutter pub get")
        env_file = os.path.join(CLIENT_DIR, ".env.production")
        if not os.path.isfile(env_file):
            env_file = os.path.join(CLIENT_DIR, ".env.dev")
        info("预构建（生成 Xcode 所需文件）...")
        run(f"flutter build macos --release --dart-define-from-file={env_file}")
        print()
        upload_to_app_store()
    elif upload_only:
        # 仅上传：使用已有的 archive
        os.makedirs(DEST_BASE, exist_ok=True)
        upload_to_app_store(skip_archive=True)
    else:
        # 构建
        app_path = build()
        print()

        if do_dmg:
            # 签名（在原始构建目录，保留符号链接）
            if not no_sign:
                sign_app(app_path)
                print()

            # 打包 DMG
            dmg_path = create_dmg(app_path)
            print()

            # 直接公证 DMG
            if not no_sign and not no_notarize:
                notarize_dmg(dmg_path)

    print()


if __name__ == "__main__":
    main()
