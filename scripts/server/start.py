#!/usr/bin/env python3
"""
启动后端服务：检查 PostgreSQL → 停旧进程 → cargo build → cargo run
用法: python scripts/server/start.py

支持 Windows / macOS / Linux
"""

import os
import platform
import shutil
import subprocess
import sys
import time

SYSTEM = platform.system()  # "Windows" / "Darwin" / "Linux"
PROCESS_NAME = "flash-im"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SERVER_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", "server"))

# ─── PostgreSQL 路径（按平台） ───

if SYSTEM == "Windows":
    PG_DIR = r"C:\toly\SDK\postgres"
    PG_CTL = os.path.join(PG_DIR, "pgsql", "bin", "pg_ctl.exe")
    PG_DATA = os.path.join(PG_DIR, "data")
    PG_LOG = os.path.join(PG_DIR, "pg_start.log")
else:
    # macOS (Homebrew) / Linux: pg_ctl 通常在 PATH 中
    PG_CTL = shutil.which("pg_ctl")
    if SYSTEM == "Darwin":
        PG_DATA = os.path.expanduser("~/Library/Application Support/Postgres/var-17")
        if not os.path.isdir(PG_DATA):
            PG_DATA = "/usr/local/var/postgres"
    else:
        PG_DATA = "/var/lib/postgresql/data"
    PG_LOG = "/tmp/pg.log"


def run(cmd, encoding="utf-8", **kwargs):
    return subprocess.run(cmd, capture_output=True, text=(encoding is not None),
                          encoding=encoding, **kwargs)


# ─── 1. 检测并启动 PostgreSQL ───

def ensure_postgres():
    if not PG_CTL or not os.path.exists(PG_CTL):
        print("[PG] pg_ctl not found, assuming PostgreSQL is managed externally.")
        return

    pg_isready = os.path.join(os.path.dirname(PG_CTL), "pg_isready.exe" if SYSTEM == "Windows" else "pg_isready")

    # 先检查是否已经可用
    if os.path.exists(pg_isready):
        r = run([pg_isready, "-p", "5432", "-t", "2"])
        if r.returncode == 0:
            print("[PG] PostgreSQL is ready.")
            return

    # 不可用：尝试停止 → 清理 → 启动
    print("[PG] PostgreSQL not ready, restarting...")
    subprocess.run([PG_CTL, "-D", PG_DATA, "stop", "-m", "immediate"],
                   timeout=10, capture_output=True)
    time.sleep(1)

    # 强制杀掉所有残留 postgres 进程（Windows 上共享内存不会自动释放）
    if SYSTEM == "Windows":
        subprocess.run(["taskkill", "/F", "/IM", "postgres.exe"],
                       capture_output=True, timeout=5)
        time.sleep(2)

    # 清理残留 PID 文件
    pid_file = os.path.join(PG_DATA, "postmaster.pid")
    if os.path.exists(pid_file):
        os.remove(pid_file)
        print("[PG] Removed stale postmaster.pid")

    # 启动
    print("[PG] Starting PostgreSQL...")
    if SYSTEM == "Windows":
        subprocess.Popen([PG_CTL, "-D", PG_DATA, "-l", PG_LOG, "-o", "-p 5432", "start"])
    else:
        subprocess.run([PG_CTL, "-D", PG_DATA, "-l", PG_LOG, "-o", "-p 5432", "start"], timeout=15)

    # 等待就绪
    for i in range(15):
        if os.path.exists(pg_isready):
            r = run([pg_isready, "-p", "5432", "-t", "1"])
            if r.returncode == 0:
                print("[PG] PostgreSQL is ready.")
                return
        elif _is_port_listening(5432):
            print("[PG] PostgreSQL is ready.")
            return
        time.sleep(1)
    print("[PG] WARNING: PostgreSQL may not have started. Check pg.log.")


def _is_port_listening(port):
    """检查端口是否被占用"""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        return s.connect_ex(("127.0.0.1", port)) == 0


# ─── 2. 停止旧进程 ───

def stop_existing():
    if SYSTEM == "Windows":
        try:
            r = run(["tasklist", "/FI", f"IMAGENAME eq {PROCESS_NAME}.exe", "/NH"],
                    encoding=None)
            output = r.stdout.decode("gbk", errors="ignore") if r.stdout else ""
        except Exception:
            output = ""

        if PROCESS_NAME in output:
            print(f"[SERVER] Stopping existing {PROCESS_NAME}...")
            run(["taskkill", "/F", "/IM", f"{PROCESS_NAME}.exe"], encoding=None)
            time.sleep(1)
            print("[SERVER] Stopped.")
        else:
            print(f"[SERVER] No existing {PROCESS_NAME} process.")
    else:
        # macOS / Linux: pkill
        r = run(["pgrep", "-f", PROCESS_NAME])
        if r.returncode == 0 and r.stdout.strip():
            print(f"[SERVER] Stopping existing {PROCESS_NAME}...")
            run(["pkill", "-f", PROCESS_NAME])
            time.sleep(1)
            print("[SERVER] Stopped.")
        else:
            print(f"[SERVER] No existing {PROCESS_NAME} process.")


# ─── 3. 构建并运行 ───

def build_and_run():
    env = os.environ.copy()
    env["RUSTFLAGS"] = ""
    env["RUST_BACKTRACE"] = "0"

    print("[SERVER] Building...")
    r = subprocess.run(["cargo", "build"], cwd=SERVER_DIR, env=env,
                       capture_output=True, text=True, encoding="utf-8")
    if r.returncode != 0:
        print(r.stdout)
        print(r.stderr)
        print("[SERVER] Build failed.")
        sys.exit(1)
    print("[SERVER] Build succeeded.")

    print("[SERVER] Starting...")
    try:
        subprocess.run(["cargo", "run"], cwd=SERVER_DIR, env=env)
    except KeyboardInterrupt:
        print("\n[SERVER] Stopped.")


if __name__ == "__main__":
    ensure_postgres()
    stop_existing()
    build_and_run()
