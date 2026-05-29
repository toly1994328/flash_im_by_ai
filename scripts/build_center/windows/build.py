#!/usr/bin/env python3
"""
闪讯 Windows 构建脚本

用法：
  python scripts/build_center/windows/build.py          # 只构建
  python scripts/build_center/windows/build.py --pack   # 构建 + 打包安装程序
"""

import os
import subprocess
import sys
import json
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BUILD_CENTER = os.path.dirname(SCRIPT_DIR)
PROJECT_ROOT = os.path.normpath(os.path.join(BUILD_CENTER, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
CONFIG_FILE = os.path.join(BUILD_CENTER, "build.json")
ISS_FILE = os.path.join(SCRIPT_DIR, "flash_im.iss")
DEST_DIR = os.path.join(BUILD_CENTER, "dest", "windows")


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


def main():
    pack = "--pack" in sys.argv

    # 读取配置
    inno_path = ""
    if os.path.isfile(CONFIG_FILE):
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            config = json.load(f)
        inno_path = config.get("windows", {}).get("inno_setup", "")

    # 读取版本号
    pubspec_path = os.path.join(CLIENT_DIR, "pubspec.yaml")
    version = "unknown"
    with open(pubspec_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("version:"):
                version = line.split(":")[1].strip()
                break

    print()
    info(f"版本: {version}")
    info("Flutter build windows --release ...")
    run("flutter build windows --release --dart-define-from-file=.env.production", cwd=CLIENT_DIR)
    ok("构建完成")

    release_dir = os.path.join(CLIENT_DIR, "build", "windows", "x64", "runner", "Release")
    if not os.path.isfile(os.path.join(release_dir, "flash_im.exe")):
        fail("构建产物不存在")
    info(f"产物: {release_dir}")

    # 打包
    if pack:
        if not inno_path or not os.path.isfile(inno_path):
            fail(f"Inno Setup 未找到: {inno_path}\n  请在 build.json 中配置 windows.inno_setup 路径")
        if os.path.isdir(DEST_DIR):
            shutil.rmtree(DEST_DIR)
        os.makedirs(DEST_DIR, exist_ok=True)
        info("Inno Setup 打包...")
        run(f'"{inno_path}" /DVersion={version} "{ISS_FILE}"')
        ok(f"安装程序已生成: {DEST_DIR}")

    print()
    ok("完成!")


if __name__ == "__main__":
    main()
