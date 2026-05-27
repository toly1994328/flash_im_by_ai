#!/usr/bin/env python3
"""
闪讯 iOS 构建 & 发布脚本

用法：
  python scripts/build_center/build_ios.py              # 构建 IPA
  python scripts/build_center/build_ios.py --upload     # 构建并上传到 App Store Connect
  python scripts/build_center/build_ios.py --upload-only  # 只上传已有的 IPA，不重新构建

上传凭证配置在 client/ios/.env.publish

产物输出：
  scripts/build_center/dest/ios/flash_im.ipa
"""

import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
DEST_BASE = os.path.join(SCRIPT_DIR, "dest", "ios")
PUBLISH_ENV = os.path.join(CLIENT_DIR, "ios", ".env.publish")


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def warn(msg):
    print(f"\033[33m[WARN]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def run(cmd):
    r = subprocess.run(cmd, cwd=CLIENT_DIR, shell=True)
    if r.returncode != 0:
        fail(f"命令失败：{cmd}")


def run_capture(cmd):
    return subprocess.run(cmd, cwd=CLIENT_DIR, shell=True, capture_output=True, text=True)


def file_size(path):
    size = os.path.getsize(path)
    if size < 1024 * 1024:
        return f"{size / 1024:.1f} KB"
    return f"{size / (1024 * 1024):.1f} MB"


def find_ipa(build_dir):
    """递归查找 IPA 文件"""
    for root, dirs, files in os.walk(build_dir):
        for f in files:
            if f.endswith(".ipa"):
                return os.path.join(root, f)
    return None


def load_publish_env():
    """从 client/ios/.env.publish 加载上传凭证"""
    if not os.path.isfile(PUBLISH_ENV):
        fail(
            f"未找到上传凭证文件：{PUBLISH_ENV}\n"
            "\n"
            "       请创建该文件并填写 App Store Connect API Key 信息：\n"
            "         APP_STORE_CONNECT_ISSUER_ID=你的IssuerID\n"
            "         APP_STORE_CONNECT_KEY_ID=你的KeyID\n"
            "         APP_STORE_CONNECT_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8"
        )
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


def upload_to_app_store(ipa_path):
    """使用 xcrun altool 上传 IPA 到 App Store Connect"""
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

    # 确保 API Key 在 altool 能找到的位置
    altool_key_dir = os.path.expanduser("~/.appstoreconnect/private_keys")
    expected_key_path = os.path.join(altool_key_dir, f"AuthKey_{key_id}.p8")
    if not os.path.isfile(expected_key_path):
        os.makedirs(altool_key_dir, exist_ok=True)
        shutil.copy2(key_path, expected_key_path)
        info(f"已复制 API Key 到 {expected_key_path}")

    info("上传中（通过 xcrun altool）...")
    cmd = (
        f"xcrun altool --upload-app"
        f" --type ios"
        f" --file \"{ipa_path}\""
        f" --apiKey \"{key_id}\""
        f" --apiIssuer \"{issuer_id}\""
    )
    r = subprocess.run(cmd, cwd=CLIENT_DIR, shell=True, capture_output=False)

    if r.returncode == 0:
        ok("上传成功！已提交到 App Store Connect")
        info("前往查看处理状态：https://appstoreconnect.apple.com")
    else:
        fail("上传失败，请检查上方日志中的错误信息")


def main():
    do_upload = "--upload" in sys.argv
    upload_only = "--upload-only" in sys.argv

    if upload_only:
        # 只上传，不构建
        dest = os.path.join(DEST_BASE, "flash_im.ipa")
        if not os.path.isfile(dest):
            fail(f"IPA 文件不存在：{dest}\n\n       请先运行构建：python3 scripts/build_center/build_ios.py")

        print()
        print("╔══════════════════════════════════════════╗")
        print("║   闪讯 iOS 上传                          ║")
        print("╚══════════════════════════════════════════╝")
        print()
        info(f"IPA：{dest}")
        info(f"大小：{file_size(dest)}")
        print()
        upload_to_app_store(dest)
        print()
        return

    # 使用 .env.production（如果存在），否则 .env.dev
    env_file = os.path.join(CLIENT_DIR, ".env.production")
    if not os.path.isfile(env_file):
        env_file = os.path.join(CLIENT_DIR, ".env.dev")
    if not os.path.isfile(env_file):
        fail("未找到环境配置文件（.env.production 或 .env.dev）")

    env_name = os.path.basename(env_file)
    dart_defines = f"--dart-define-from-file={env_file}"

    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 iOS 构建                          ║")
    print("╚══════════════════════════════════════════╝")
    print()
    info(f"配置：{env_name}")
    if do_upload:
        info("构建后将上传到 App Store Connect")
    print()

    # ─── 构建 ───

    info("清理...")
    run("flutter clean")
    info("获取依赖...")
    run("flutter pub get")

    cmd = (
        f"flutter build ipa --release"
        f" --obfuscate --split-debug-info=build/debug-info"
        f" --export-method app-store"
        f" {dart_defines}"
    )
    info("构建 IPA...")
    run(cmd)

    # ─── 查找产物 ───

    build_dir = os.path.join(CLIENT_DIR, "build", "ios")
    ipa_path = find_ipa(build_dir)

    if ipa_path:
        os.makedirs(DEST_BASE, exist_ok=True)
        dest = os.path.join(DEST_BASE, "flash_im.ipa")
        shutil.copy2(ipa_path, dest)
        print()
        ok("IPA 构建完成")
        info(f"产物：{dest}")
        info(f"大小：{file_size(dest)}")

        if do_upload:
            print()
            upload_to_app_store(dest)
    else:
        fail("IPA 文件未找到，请检查签名配置")

    print()


if __name__ == "__main__":
    main()
