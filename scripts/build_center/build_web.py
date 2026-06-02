"""
闪讯 Web 构建 + 部署脚本

用法：
  python scripts/build_center/build_web.py                              # 仅构建（WASM 模式）
  python scripts/build_center/build_web.py --deploy root@182.61.150.114 # 构建 + 部署

产物输出：
  scripts/build_center/dest/web/flash_im_web.tar.gz
"""

import sys
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
CLIENT_DIR = PROJECT_ROOT / "client"
DEST_DIR = SCRIPT_DIR / "dest" / "web"
ARCHIVE_NAME = "flash_im_web.tar.gz"

# 服务器配置
REMOTE_DIR = "~/server/flash_im/static/im"


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

    info("构建 Flutter Web release (WASM 模式)...")
    run("flutter build web --wasm --release --tree-shake-icons --base-href /im/ --dart-define-from-file=.env.production", cwd=CLIENT_DIR)

    build_dir = CLIENT_DIR / "build" / "web"
    if not (build_dir / "index.html").exists():
        fail(f"构建产物未找到: {build_dir / 'index.html'}")

    # 压缩
    info("压缩产物...")
    DEST_DIR.mkdir(parents=True, exist_ok=True)
    archive_path = DEST_DIR / ARCHIVE_NAME
    run(f'tar -czf "{archive_path}" -C "{build_dir}" .', cwd=CLIENT_DIR)

    size = archive_path.stat().st_size / (1024 * 1024)
    ok(f"构建完成: {archive_path} ({size:.1f} MB)")

    return archive_path


def deploy(archive_path, remote_target):
    print()
    info(f"部署到 {remote_target}:{REMOTE_DIR}")

    info("上传压缩包...")
    run(f'scp "{archive_path}" {remote_target}:/tmp/{ARCHIVE_NAME}')

    info("远程解压...")
    remote_cmds = f"mkdir -p {REMOTE_DIR} && rm -rf {REMOTE_DIR}/* && tar -xzf /tmp/{ARCHIVE_NAME} -C {REMOTE_DIR} && rm -f /tmp/{ARCHIVE_NAME}"
    run(f'ssh {remote_target} "{remote_cmds}"')

    host = remote_target.split('@')[-1]
    ok(f"部署完成! 访问: http://{host}:9600/im/")


def main():
    archive_path = build()

    if "--deploy" in sys.argv:
        idx = sys.argv.index("--deploy")
        if idx + 1 >= len(sys.argv):
            fail("请指定服务器: --deploy root@your-server-ip")
        remote_target = sys.argv[idx + 1]
        deploy(archive_path, remote_target)
    else:
        print()
        info("仅构建完成，使用 --deploy <server> 可自动部署到服务器")


if __name__ == "__main__":
    main()
