#!/usr/bin/env python3
"""
修复 sqlite3 build hook 下载超时问题。

将本地预存的 sqlite3 二进制复制到 .dart_tool/hooks_runner/shared 目录，
使 hook 不再需要从 GitHub 下载。

用法：flutter build 前执行一次
  python scripts/build_center/fix_sqlite3_cache.py
"""

import os
import shutil
import glob

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
SOURCE_DIR = os.path.join(SCRIPT_DIR, "dest", "sqlite3")
SHARED_DIR = os.path.join(CLIENT_DIR, ".dart_tool", "hooks_runner", "shared", "sqlite3", "build")

# 源文件 → 目标文件名映射
FILES = {
    "sqlite3.dll": "sqlite3.dll",
    "libsqlite3.arm64.android.so": "libsqlite3.so",
}


def main():
    if not os.path.isdir(SHARED_DIR):
        print(f"[SKIP] shared 目录不存在，先执行 flutter pub get: {SHARED_DIR}")
        return

    # 找到所有 download-* 子目录
    download_dirs = glob.glob(os.path.join(SHARED_DIR, "download-*"))
    if not download_dirs:
        print("[SKIP] 没有 download-* 目录")
        return

    for download_dir in download_dirs:
        # 判断需要哪个文件：看里面有 .dll 还是 .so
        existing = os.listdir(download_dir)
        if any("dll" in f for f in existing):
            src_name = "sqlite3.dll"
            dst_name = "sqlite3.dll"
        elif any("so" in f for f in existing):
            src_name = "libsqlite3.arm64.android.so"
            dst_name = "libsqlite3.so"
        else:
            continue

        src_path = os.path.join(SOURCE_DIR, src_name)
        dst_path = os.path.join(download_dir, dst_name)

        if not os.path.isfile(src_path):
            print(f"[WARN] 源文件不存在: {src_path}")
            continue

        # 删除 .tmp 文件
        for f in os.listdir(download_dir):
            if f.endswith(".tmp"):
                os.remove(os.path.join(download_dir, f))

        # 复制
        shutil.copy2(src_path, dst_path)
        print(f"[OK] {src_name} → {download_dir}")

    print("\n完成。sqlite3 缓存已就位，构建时不再需要下载。")


if __name__ == "__main__":
    main()
