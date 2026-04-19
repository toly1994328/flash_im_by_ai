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
    PG_LOG = os.path.join(PG_DIR, "pgsql", "pg.log")
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
        # macOS/Linux 可能通过 brew services 或 systemd 管理
        print("[PG] pg_ctl not found, assuming PostgreSQL is managed externally.")
        return

    r = run([PG_CTL, "-D", PG_DATA, "status"])
    if r.returncode != 0:
        print("[PG] Starting PostgreSQL...")
        # 不捕获输出，避免 pg_ctl 阻塞
        subprocess.run(
            [PG_CTL, "-D", PG_DATA, "-l", PG_LOG, "-o", "-p 5432", "start"],
            timeout=15,
        )
        time.sleep(2)
        print("[PG] PostgreSQL started.")
    else:
        print("[PG] PostgreSQL is running.")


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
