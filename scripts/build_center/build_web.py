"""
闪讯 Web 构建 + 部署脚本

用法：
  python scripts/build_center/build_web.py                          # 仅构建
  python scripts/build_center/build_web.py --deploy 192.168.1.75    # 构建 + 部署

产物输出：
  scripts/build_center/dest/web/flash_im_web.tar.gz
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
CLIENT_DIR = PROJECT_ROOT / "client"
DEST_DIR = SCRIPT_DIR / "dest" / "web"
ARCHIVE_NAME = "flash_im_web.tar.gz"

# 服务器配置
SERVER_USER = "root"
REMOTE_DIR = "~/server/flash_im/static/web"


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def run(cmd, cwd=None):
    result = subprocess.run(cmd, shell=True, cwd=cwd)
    if result.returncode != 0:
        fail(f"命令执行失败: {cmd}")


def build():
    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 Web 构建                          ║")
    print("╚══════════════════════════════════════════╝")
    print()

    # 1. 构建 Flutter Web
    info("构建 Flutter Web release...")
    run("flutter build web --release --base-href /im/ --dart-define-from-file=.env.production", cwd=CLIENT_DIR)

    build_dir = CLIENT_DIR / "build" / "web"
    if not (build_dir / "index.html").exists():
        fail(f"构建产物未找到: {build_dir / 'index.html'}")

    # 2. 压缩
    info("压缩产物...")
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    archive_path = DEST_DIR / ARCHIVE_NAME

    # 用 tar 压缩 build/web 目录内容
    run(f'tar -czf "{archive_path}" -C "{build_dir}" .', cwd=CLIENT_DIR)

    size = archive_path.stat().st_size / (1024 * 1024)
    ok(f"构建完成: {archive_path}")
    info(f"大小: {size:.1f} MB")

    return archive_path


def deploy(archive_path, server_host):
    print()
    info(f"部署到 {SERVER_USER}@{server_host}:{REMOTE_DIR}")

    # 3. 上传
    info("上传压缩包...")
    run(f'scp "{archive_path}" {SERVER_USER}@{server_host}:/tmp/{ARCHIVE_NAME}')

    # 4. 远程解压 + 清理
    info("远程解压...")
    remote_cmds = f"mkdir -p {REMOTE_DIR} && rm -rf {REMOTE_DIR}/* && tar -xzf /tmp/{ARCHIVE_NAME} -C {REMOTE_DIR} && rm -f /tmp/{ARCHIVE_NAME}"
    run(f'ssh {SERVER_USER}@{server_host} "{remote_cmds}"')

    ok(f"部署完成! 访问: http://{server_host}:9600/im/")


def main():
    archive_path = build()

    if "--deploy" in sys.argv:
        idx = sys.argv.index("--deploy")
        if idx + 1 >= len(sys.argv):
            fail("请指定服务器地址: --deploy <server_ip>")
        server_host = sys.argv[idx + 1]
        deploy(archive_path, server_host)
    else:
        print()
        info("仅构建完成，使用 --deploy <server_ip> 可自动部署到服务器")


if __name__ == "__main__":
    main()
