#!/usr/bin/env python3
"""
数据处理：重置数据库 + 启动服务 + seed + 停止服务，一键完成。
用法: python scripts/server/data_handler.py

流程:
  1. reset_db.py  — 重置数据库 + 迁移
  2. 检测服务是否已在运行，没有则启动
  3. seed.py      — 灌入种子数据
  4. 如果是本脚本启动的服务，停止它
"""

import os
import subprocess
import sys
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))

RESET_DB = os.path.join(SCRIPT_DIR, "reset_db.py")
START = os.path.join(SCRIPT_DIR, "start.py")
SEED = os.path.join(SCRIPT_DIR, "im_seed", "seed.py")

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
RESET = "\033[0m"


def run_step(name, cmd):
    print(f"\n{CYAN}[{name}]{RESET}")
    r = subprocess.run([sys.executable] + cmd, cwd=PROJECT_ROOT)
    if r.returncode != 0:
        print(f"{RED}[{name}] 失败{RESET}")
        sys.exit(1)


def is_server_running():
    """检测服务是否已在运行"""
    try:
        import socket
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        s.connect(("127.0.0.1", 9600))
        s.close()
        return True
    except Exception:
        return False


def wait_for_server(timeout=120):
    """轮询等待服务就绪"""
    import socket
    print(f"\n{CYAN}[等待服务就绪]{RESET}", end="", flush=True)
    for i in range(timeout):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(1)
            s.connect(("127.0.0.1", 9600))
            s.close()
            print(f" ✅ ({i+1}s)")
            return True
        except Exception:
            print(".", end="", flush=True)
            time.sleep(1)
    print(f" {RED}超时{RESET}")
    return False


if __name__ == "__main__":
    # 1. 重置数据库
    run_step("重置数据库", [RESET_DB])

    # 2. 检测服务状态
    server_proc = None
    if is_server_running():
        print(f"\n{CYAN}[服务] 已在运行，跳过启动{RESET}")
    else:
        print(f"\n{CYAN}[服务] 未运行，启动中...{RESET}")
        server_proc = subprocess.Popen(
            [sys.executable, START],
            cwd=PROJECT_ROOT,
        )
        if not wait_for_server():
            server_proc.terminate()
            print(f"{RED}服务启动超时，退出{RESET}")
            sys.exit(1)

    # 3. Seed
    run_step("灌入种子数据", [SEED])

    # 4. 只停止本脚本启动的服务
    if server_proc:
        print(f"\n{CYAN}[服务] 停止（本脚本启动的）{RESET}")
        server_proc.terminate()
        try:
            server_proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            server_proc.kill()
    else:
        print(f"\n{CYAN}[服务] 保持运行（非本脚本启动）{RESET}")

    print(f"\n{GREEN}{'=' * 40}")
    print(f"  数据准备完成")
    print(f"{'=' * 40}{RESET}")
