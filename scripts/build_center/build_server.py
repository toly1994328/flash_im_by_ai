#!/usr/bin/env python3
"""
闪讯 IM — 本地交叉编译脚本（跨平台）

在本地编译出 Linux x86_64 的 Release 二进制，可选上传到服务器。

用法：
  python scripts/build_center/build_server.py                        # 只编译
  python scripts/build_center/build_server.py root@82.157.176.209     # 编译并上传
  python scripts/build_center/build_server.py --upload-only root@82.157.176.209  # 只上传不编译

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
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
SERVER_DIR = os.path.join(PROJECT_ROOT, "server")
TARGET = "x86_64-unknown-linux-gnu"
BINARY_NAME = "flash-im"
BINARY_PATH = os.path.join(SERVER_DIR, "target", TARGET, "release", BINARY_NAME)
REMOTE_DIR = "~/server/flash_im"

SYSTEM = platform.system()


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}", flush=True)


def ok(msg):
    print(f"\033[32m[OK]\033[0m {msg}", flush=True)


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
    upload_only = "--upload-only" in sys.argv
    deploy_all = "--deploy" in sys.argv
    args = [a for a in sys.argv[1:] if a not in ("--upload-only", "--deploy")]
    remote_host = args[0] if args else None

    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 IM — 本地交叉编译                 ║")
    print("╚══════════════════════════════════════════╝")
    print()
    info(f"本机系统：{SYSTEM}")
    info(f"目标平台：{TARGET}")
    print()

    # ─── 检查工具 ───

    if not upload_only:
        if not check_tool("cargo"):
            fail("cargo 未安装，请先安装 Rust：https://rustup.rs")

        if not check_tool("cross"):
            info("cross 未安装，正在安装...")
            run(["cargo", "install", "cross"])

    if not upload_only:
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

    if upload_only:
        info("跳过编译（--upload-only）")
        if SYSTEM == "Windows":
            binary_path = os.path.join(SERVER_DIR, "target", "release", BINARY_NAME)
        else:
            binary_path = BINARY_PATH
        if not os.path.isfile(binary_path):
            fail(f"二进制文件不存在：{binary_path}，请先编译")
    else:
        info(f"目标平台：{TARGET}")
        info("开始编译（Release 模式），可能需要几分钟...")
        print()

        if SYSTEM == "Windows":
            info("Windows 环境，使用 Docker 容器编译...")
            server_dir_posix = SERVER_DIR.replace("\\", "/")
            proto_dir_posix = os.path.join(PROJECT_ROOT, "proto").replace("\\", "/")
            run([
                "docker", "run", "--rm",
                "-v", f"{server_dir_posix}:/project",
                "-v", f"{proto_dir_posix}:/proto",
                "-w", "/project",
                "rust:latest",
                "bash", "-c",
                "apt-get update -qq && apt-get install -y -qq protobuf-compiler > /dev/null 2>&1 && cargo build --release",
            ])
            binary_path = os.path.join(SERVER_DIR, "target", "release", BINARY_NAME)
        else:
            run(["cross", "build", "--release", "--target", TARGET], cwd=SERVER_DIR)
            binary_path = BINARY_PATH

        if not os.path.isfile(binary_path):
            fail("编译失败，未找到二进制文件")

    print()
    ok("编译成功！")
    info(f"二进制路径：{binary_path}")
    info(f"文件大小：{file_size_human(binary_path)}")
    print()

    # ─── 上传（可选） ───

    if remote_host:
        info(f"上传到 {remote_host}:{REMOTE_DIR} ...")

        # 停止服务
        info("停止远程服务...")
        subprocess.run(["ssh", remote_host, "systemctl stop flash-im"], capture_output=True, timeout=15)

        # 创建远程目录
        run(["ssh", remote_host, f"mkdir -p {REMOTE_DIR}"])

        # 上传二进制（远程文件名固定为 flash-im）
        remote_path = f"{remote_host}:{REMOTE_DIR}/{BINARY_NAME}"
        run(["scp", binary_path, remote_path])

        # 完整部署时同步附属文件
        if deploy_all or (not upload_only):
            # 同步 migrations 目录
            migrations_dir = os.path.join(SERVER_DIR, "migrations")
            if os.path.isdir(migrations_dir):
                info("同步 migrations 到远程...")
                run(["scp", "-r", migrations_dir, f"{remote_host}:{REMOTE_DIR}/"])

            # 同步 static 目录
            static_dir = os.path.join(SERVER_DIR, "static")
            if os.path.isdir(static_dir):
                info("同步 static 到远程...")
                run(["scp", "-r", static_dir, f"{remote_host}:{REMOTE_DIR}/"])

            # 同步部署脚本（.env、flash.sh、db.sh）
            deploy_dir = os.path.join(PROJECT_ROOT, "scripts", "deploy")
            env_file = os.path.join(SERVER_DIR, ".env")
            flash_script = os.path.join(deploy_dir, "flash.sh")
            db_script = os.path.join(deploy_dir, "db.sh")

            if os.path.isfile(env_file):
                info("同步 .env 到远程...")
                run(["scp", env_file, f"{remote_host}:{REMOTE_DIR}/"])

            if os.path.isfile(flash_script):
                info("同步 flash.sh 到远程...")
                run(["scp", flash_script, f"{remote_host}:{REMOTE_DIR}/"])
                run(["ssh", remote_host, f"chmod +x {REMOTE_DIR}/flash.sh"])

            if os.path.isfile(db_script):
                info("同步 db.sh 到远程...")
                run(["scp", db_script, f"{remote_host}:{REMOTE_DIR}/"])
                run(["ssh", remote_host, f"chmod +x {REMOTE_DIR}/db.sh"])

            # 同步 seed 目录
            seed_dir = os.path.join(PROJECT_ROOT, "scripts", "server", "im_seed")
            if os.path.isdir(seed_dir):
                info("同步 im_seed 到远程...")
                run(["scp", "-r", seed_dir, f"{remote_host}:{REMOTE_DIR}/"])

        # 赋予可执行权限并重启服务
        time.sleep(2)  # 等待 SSH 连接释放，避免被服务器限流
        info("重启远程服务...")
        run(["ssh", remote_host, f"chmod +x {REMOTE_DIR}/{BINARY_NAME} && systemctl restart flash-im"])

        ok("部署完成！")
    else:
        info("编译完成。上传到服务器：")
        print(f"  python scripts/build_center/build_server.py root@你的服务器IP")

    print()


if __name__ == "__main__":
    main()
