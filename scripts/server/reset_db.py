#!/usr/bin/env python3
"""
重置数据库：启动 PostgreSQL → 删除 → 创建 → 执行迁移脚本
用法: python scripts/server/reset_db.py

支持 Windows / macOS / Linux
"""

import os
import platform
import shutil
import subprocess
import sys
import time

SYSTEM = platform.system()
DB_NAME = "flash_im"
PG_USER = "postgres"
PG_PASS = "postgres"
PG_HOST = "127.0.0.1"
PG_PORT = "5432"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
MIGRATIONS_DIR = os.path.join(PROJECT_ROOT, "server", "migrations")

MIGRATIONS = [
    "20250320_001_auth.sql",
    "20260329_002_conversations.sql",
    "20260330_003_messages.sql",
    "20260407_004_friends.sql",
    "20260412_005_group.sql",
    "20260419_006_group_join.sql",
    "20260420_007_group_manage.sql",
]

# ─── 平台相关路径 ───

if SYSTEM == "Windows":
    PG_DIR = r"C:\toly\SDK\postgres"
    PG_CTL = os.path.join(PG_DIR, "pgsql", "bin", "pg_ctl.exe")
    PSQL = os.path.join(PG_DIR, "pgsql", "bin", "psql.exe")
    PG_DATA = os.path.join(PG_DIR, "data")
    PG_LOG = os.path.join(PG_DIR, "pgsql", "pg.log")
else:
    PG_CTL = shutil.which("pg_ctl")
    PSQL = shutil.which("psql")
    if SYSTEM == "Darwin":
        PG_DATA = os.path.expanduser("~/Library/Application Support/Postgres/var-17")
        if not os.path.isdir(PG_DATA):
            PG_DATA = "/usr/local/var/postgres"
    else:
        PG_DATA = "/var/lib/postgresql/data"
    PG_LOG = "/tmp/pg.log"

env = os.environ.copy()
env["PGPASSWORD"] = PG_PASS
env["PGCLIENTENCODING"] = "UTF8"


def run(cmd, check=True):
    r = subprocess.run(cmd, capture_output=True, text=True, env=env, encoding="utf-8")
    if check and r.returncode != 0:
        print(f"[ERROR] {' '.join(cmd)}")
        print(r.stderr or r.stdout)
        sys.exit(1)
    return r


def psql(sql=None, file=None):
    if not PSQL:
        print("[ERROR] psql not found in PATH")
        sys.exit(1)
    cmd = [PSQL, "-U", PG_USER, "-h", PG_HOST, "-p", PG_PORT, "-w"]
    if sql:
        cmd += ["-c", sql]
    if file:
        cmd += ["-d", DB_NAME, "-f", file]
    return run(cmd, check=False)


# ─── 1. 确保 PostgreSQL 运行 ───

def ensure_postgres():
    print("[PG] Checking PostgreSQL...")
    if not PG_CTL or not os.path.exists(PG_CTL):
        print("[PG] pg_ctl not found, assuming PostgreSQL is managed externally.")
        return

    r = run([PG_CTL, "-D", PG_DATA, "status"], check=False)
    if r.returncode != 0:
        print("[PG] Starting PostgreSQL...")
        run([PG_CTL, "-D", PG_DATA, "-l", PG_LOG, "-o", "-p 5432", "start"])
        time.sleep(2)
        print("[PG] Started.")
    else:
        print("[PG] Already running.")


# ─── 2. 重置数据库 ───

def reset_database():
    print(f"[DB] Dropping '{DB_NAME}'...")
    psql(f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
         f"WHERE datname='{DB_NAME}' AND pid <> pg_backend_pid();")
    psql(f"DROP DATABASE IF EXISTS {DB_NAME};")

    print(f"[DB] Creating '{DB_NAME}'...")
    r = psql(f"CREATE DATABASE {DB_NAME};")
    if r.returncode != 0:
        print("[ERROR] Failed to create database")
        sys.exit(1)


# ─── 3. 执行迁移 ───

def run_migrations():
    print("[DB] Running migrations...")
    for name in MIGRATIONS:
        path = os.path.normpath(os.path.join(MIGRATIONS_DIR, name))
        if not os.path.exists(path):
            print(f"  [WARN] {name} not found, skipping")
            continue
        r = psql(file=path)
        status = "OK" if r.returncode == 0 else "FAIL"
        print(f"  [{status}] {name}")
        if r.returncode != 0:
            print(r.stderr)
            sys.exit(1)


if __name__ == "__main__":
    ensure_postgres()
    reset_database()
    run_migrations()
    print("[DB] Reset complete.")
