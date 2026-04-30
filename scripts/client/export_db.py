#!/usr/bin/env python3
"""
导出安卓模拟器上的本地缓存数据库到当前目录
用法: export_db [userId]
默认 userId=1
"""

import os
import subprocess
import sys

PACKAGE = "com.toly1994.flash_im"
DB_DIR = "app_flutter"

def main():
    user_id = sys.argv[1] if len(sys.argv) > 1 else "1"
    db_name = f"im_cache_{user_id}.db"
    remote_path = f"{DB_DIR}/{db_name}"
    local_path = os.path.join(os.getcwd(), db_name)

    print(f"📦 Exporting {db_name} ...")

    result = subprocess.run(
        ["adb", "exec-out", "run-as", PACKAGE, "cat", remote_path],
        capture_output=True,
    )

    if result.returncode != 0:
        print(f"❌ Failed: {result.stderr.decode().strip()}")
        sys.exit(1)

    if len(result.stdout) == 0:
        print(f"❌ File is empty, database may not exist on device")
        sys.exit(1)

    with open(local_path, "wb") as f:
        f.write(result.stdout)

    print(f"✅ Exported to {local_path} ({len(result.stdout):,} bytes)")

if __name__ == "__main__":
    main()
