#!/usr/bin/env python3
"""
闪讯 Windows 构建脚本

用法：
  python scripts/build_center/windows/build.py              # 只构建
  python scripts/build_center/windows/build.py --pack       # 构建 + Inno Setup 安装包
  python scripts/build_center/windows/build.py --msix       # 构建 + MSIX 打包
  python scripts/build_center/windows/build.py --pack --msix  # 全部
"""

import json
import os
import re
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_CENTER = os.path.dirname(SCRIPT_DIR)
PROJECT_ROOT = os.path.normpath(os.path.join(BUILD_CENTER, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
CONFIG_FILE = os.path.join(BUILD_CENTER, "build.json")
ISS_FILE = os.path.join(SCRIPT_DIR, "flash_im.iss")
DEST_DIR = os.path.join(BUILD_CENTER, "dest", "windows")
PUBSPEC_PATH = os.path.join(CLIENT_DIR, "pubspec.yaml")


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")

def ok(msg):
    print(f"\033[32m[OK]\033[0m {msg}")

def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)

def run(cmd, cwd=None):
    r = subprocess.run(cmd, cwd=cwd, shell=True)
    if r.returncode != 0:
        fail(f"命令失败: {cmd}")


def read_pubspec():
    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        return f.read()


def write_pubspec(content):
    with open(PUBSPEC_PATH, "w", encoding="utf-8") as f:
        f.write(content)


def get_version(content):
    """从 pubspec.yaml 读取版本号（不含 build number）"""
    m = re.search(r'^version:\s*(\S+)', content, re.MULTILINE)
    if m:
        # 去掉 +build_number 部分
        return m.group(1).split("+")[0]
    return "0.0.0"


def ensure_msix_dep(content):
    """确保 dev_dependencies 中有 msix"""
    if "msix:" in content:
        return content
    # 在 dev_dependencies 块末尾追加
    content = re.sub(
        r'(dev_dependencies:\s*\n(?:  .+\n)*)',
        r'\1  msix: ^3.16.0\n',
        content
    )
    info("已自动添加 msix 到 dev_dependencies")
    return content


def ensure_msix_config(content, version):
    """确保有 msix_config 节，并同步版本号"""
    # 版本转为 4 段格式
    parts = version.split(".")
    while len(parts) < 4:
        parts.append("0")
    msix_version = ".".join(parts[:4])

    if "msix_config:" in content:
        # 更新 msix_version
        content = re.sub(
            r'(msix_version:\s*)\S+',
            rf'\g<1>{msix_version}',
            content
        )
        info(f"已同步 msix_version: {msix_version}")
    else:
        # 追加整个 msix_config
        config_block = f"""
msix_config:
  display_name: 闪讯
  publisher_display_name: toly
  publisher: CN=toly, O=toly1994, C=CN
  identity_name: com.toly1994.flashIm
  msix_version: {msix_version}
  logo_path: assets/images/logo.png
  certificate_path: ../scripts/build_center/windows/flash_im.pfx
  certificate_password: flash123
  install_certificate: false
"""
        content += config_block
        info(f"已自动添加 msix_config (version: {msix_version})")

    return content


def main():
    pack = "--pack" in sys.argv
    msix = "--msix" in sys.argv

    # 读取配置
    inno_path = ""
    if os.path.isfile(CONFIG_FILE):
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)
        inno_path = config.get("windows", {}).get("inno_setup", "")

    # 读取版本号
    pubspec = read_pubspec()
    version = get_version(pubspec)

    print()
    info(f"版本: {version}")
    info("Flutter build windows --release ...")
    run("flutter build windows --release --dart-define-from-file=.env.production", cwd=CLIENT_DIR)
    ok("构建完成")

    release_dir = os.path.join(CLIENT_DIR, "build", "windows", "x64", "runner", "Release")
    if not os.path.isfile(os.path.join(release_dir, "flash_im.exe")):
        fail("构建产物不存在")
    info(f"产物: {release_dir}")

    # Inno Setup 打包
    if pack:
        if not inno_path or not os.path.isfile(inno_path):
            fail(f"Inno Setup 未找到: {inno_path}\n  请在 build.json 中配置 windows.inno_setup 路径")
        if os.path.isdir(DEST_DIR):
            shutil.rmtree(DEST_DIR)
        os.makedirs(DEST_DIR, exist_ok=True)
        info("Inno Setup 打包...")
        run(f'"{inno_path}" /DVersion={version} "{ISS_FILE}"')
        ok(f"安装程序: {DEST_DIR}/flash_im.exe")

    # MSIX 打包
    if msix:
        info("准备 MSIX 打包...")
        pubspec = read_pubspec()
        pubspec = ensure_msix_dep(pubspec)
        pubspec = ensure_msix_config(pubspec, version)
        write_pubspec(pubspec)

        run("flutter pub get", cwd=CLIENT_DIR)
        run("echo y | dart run msix:create", cwd=CLIENT_DIR)

        # 复制 msix 产物到集中输出目录
        release_dir = os.path.join(CLIENT_DIR, "build", "windows", "x64", "runner", "Release")
        for f in os.listdir(release_dir):
            if f.endswith(".msix"):
                src = os.path.join(release_dir, f)
                if not os.path.isdir(DEST_DIR):
                    os.makedirs(DEST_DIR, exist_ok=True)
                dst = os.path.join(DEST_DIR, f)
                shutil.copy2(src, dst)
                ok(f"MSIX 产物: {dst}")
                break
        else:
            ok("MSIX 打包完成（产物在 build 目录）")

    if not pack and not msix:
        info("跳过打包。加 --pack 或 --msix 参数。")

    print()
    ok("完成!")


if __name__ == "__main__":
    main()
