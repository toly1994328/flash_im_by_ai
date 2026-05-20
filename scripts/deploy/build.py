#!/usr/bin/env python3
"""
闪讯 IM — 本地交叉编译脚本（跨平台）

在本地编译出 Linux x86_64 的 Release 二进制，可选上传到服务器。

用法：
  python scripts/deploy/build.py                        # 只编译
  python scripts/deploy/build.py root@47.96.123.45     # 编译并上传

前置条件：
  - 已安装 Rust：https://rustup.rs
  - 已安装 cross：cargo install cross
  - Docker 正在运行（cross 依赖 Docker 做交叉编译）

支持平台：Windows / macOS / Linux
"""

import os
import platform
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
SERVER_DIR = os.path.join(PROJECT_ROOT, "server")
TARGET = "x86_64-unknown-linux-gnu"
BINARY_NAME = "flash-im"
BINARY_PATH = os.path.join(SERVER_DIR, "target", TARGET, "release", BINARY_NAME)
REMOTE_DIR = "/opt/flash_im/server"

SYSTEM = platform.system()


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[OK]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def run(cmd, **kwargs):
    """运行命令，失败时退出"""
    r = subprocess.run(cmd, **kwargs)
    if r.returncode != 0:
        fail(f"命令失败：{' '.join(cmd) if isinstance(cmd, list) else cmd}")
    return r


def check_tool(name):
    """检查命令是否存在"""
    return shutil.which(name) is not None


def file_size_human(path):
    """返回文件大小的可读格式"""
    size = os.path.getsize(path)
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size < 1024:
            return f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} TB"


def main():
    remote_host = sys.argv[1] if len(sys.argv) > 1 else None

    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 IM — 本地交叉编译                 ║")
    print("╚══════════════════════════════════════════╝")
    print()
    info(f"本机系统：{SYSTEM}")
    info(f"目标平台：{TARGET}")
    print()

    # ─── 检查工具 ───

    if not check_tool("cargo"):
        fail("cargo 未安装，请先安装 Rust：https://rustup.rs")

    if not check_tool("cross"):
        info("cross 未安装，正在安装...")
        run(["cargo", "install", "cross"])

    # 检查 Docker
    try:
        r = subprocess.run(["docker", "info"], capture_output=True, timeout=10)
        if r.returncode != 0:
            raise Exception()
    except Exception:
        print()
        machine = platform.machine().lower()
        if SYSTEM == "Darwin":
            if "arm" in machine or "aarch64" in machine:
                url = "https://desktop.docker.com/mac/main/arm64/Docker.dmg"
                chip = "Apple Silicon (M1/M2/M3/M4)"
            else:
                url = "https://desktop.docker.com/mac/main/amd64/Docker.dmg"
                chip = "Intel Chip"
            hint = f"  macOS {chip}：\n    下载安装：{url}\n    安装后打开 Docker Desktop，等状态栏鲸鱼图标变绿。"
        elif SYSTEM == "Windows":
            if "arm" in machine or "aarch64" in machine:
                url = "https://desktop.docker.com/win/main/arm64/Docker%20Desktop%20Installer.exe"
                chip = "ARM64"
            else:
                url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
                chip = "AMD64"
            hint = f"  Windows {chip}：\n    下载安装：{url}\n    安装后启动 Docker Desktop，等系统托盘图标变绿。"
        else:
            hint = "  Linux：\n    curl -fsSL https://get.docker.com | sh\n    sudo systemctl start docker"

        fail(
            "Docker 未运行。cross 需要 Docker 来做交叉编译。\n"
            "\n"
            f"       请安装并启动 Docker：\n"
            f"       {hint}\n"
            "\n"
            "       启动后重新运行此脚本。"
        )

    ok("工具检查通过（cargo + cross + docker）")
    print()

    # ─── 编译 ───

    info("开始编译（Release 模式），可能需要几分钟...")
    print()

    run(["cross", "build", "--release", "--target", TARGET], cwd=SERVER_DIR)

    if not os.path.isfile(BINARY_PATH):
        fail("编译失败，未找到二进制文件")

    print()
    ok("编译成功！")
    info(f"二进制路径：{BINARY_PATH}")
    info(f"文件大小：{file_size_human(BINARY_PATH)}")
    print()

    # ─── 上传（可选） ───

    if remote_host:
        info(f"上传到 {remote_host}:{REMOTE_DIR} ...")

        # 创建远程目录
        run(["ssh", remote_host, f"mkdir -p {REMOTE_DIR}/target/release"])

        # 上传二进制
        remote_path = f"{remote_host}:{REMOTE_DIR}/target/release/{BINARY_NAME}"
        run(["scp", BINARY_PATH, remote_path])

        ok("上传完成！")
        print()
        info("接下来在服务器上执行部署脚本：")
        print(f"  ssh {remote_host}")
        print(f"  cd /opt/flash_im && bash scripts/deploy/deploy.sh")
    else:
        info("编译完成。手动上传：")
        if SYSTEM == "Windows":
            print(f"  scp {BINARY_PATH} root@你的服务器IP:{REMOTE_DIR}/target/release/{BINARY_NAME}")
        else:
            print(f"  scp {BINARY_PATH} root@你的服务器IP:{REMOTE_DIR}/target/release/{BINARY_NAME}")
        print()
        info("然后在服务器上执行部署脚本：")
        print("  bash scripts/deploy/deploy.sh")

    print()


if __name__ == "__main__":
    main()
