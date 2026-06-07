#!/usr/bin/env python3
"""
闪讯 Android 构建脚本

用法：
  python scripts/build_center/build_android.py              # 构建 APK（standard flavor，默认 .env.production）
  python scripts/build_center/build_android.py --aab        # 构建 AAB（google flavor，Google Play）
  python scripts/build_center/build_android.py --dev        # 使用 .env.dev 配置
  python scripts/build_center/build_android.py --env staging  # 使用自定义环境
  python scripts/build_center/build_android.py --flavor google  # 手动指定 flavor

产物输出：
  scripts/build_center/dest/android/arm64-v8a/flash_im.apk
  scripts/build_center/dest/android/armeabi-v7a/flash_im.apk
  scripts/build_center/dest/android/aab/flash_im.aab
"""

import os
import shutil
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
CLIENT_DIR = os.path.join(PROJECT_ROOT, "client")
DEST_BASE = os.path.join(SCRIPT_DIR, "dest", "android")

# 架构映射：flutter 参数 → APK 文件关键字 → 产物文件夹名
PLATFORMS = [
    {"flag": "android-arm64", "keyword": "arm64", "folder": "arm64-v8a"},
]


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def run(cmd):
    r = subprocess.run(cmd, cwd=CLIENT_DIR, shell=True)
    if r.returncode != 0:
        fail(f"命令失败：{cmd}")


def file_size(path):
    size = os.path.getsize(path)
    if size < 1024 * 1024:
        return f"{size / 1024:.1f} KB"
    return f"{size / (1024 * 1024):.1f} MB"


def main():
    args = sys.argv[1:]
    build_aab = "--aab" in args

    # Flavor 决策：--aab 默认 google，否则默认 standard，可通过 --flavor 覆盖
    if "--flavor" in args:
        flavor = args[args.index("--flavor") + 1]
    elif build_aab:
        flavor = "google"
    else:
        flavor = "standard"

    # 环境配置（默认 production）
    env = "production"
    if "--dev" in args:
        env = "dev"
    elif "--env" in args:
        env = args[args.index("--env") + 1]

    env_file = os.path.join(CLIENT_DIR, f".env.{env}")
    if not os.path.isfile(env_file):
        fail(f"环境配置文件不存在：{env_file}")

    dart_defines = f"--dart-define-from-file={env_file} --dart-define=CHANNEL={flavor}"

    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 Android 构建                      ║")
    print("╚══════════════════════════════════════════╝")
    print()
    info(f"环境：.env.{env}")
    info(f"Flavor：{flavor}")
    info("清理构建缓存...")
    run("flutter clean")
    info("获取依赖...")
    run("flutter pub get")

    if build_aab:
        dest_dir = os.path.join(DEST_BASE, "aab")
        os.makedirs(dest_dir, exist_ok=True)

        info(f"构建 AAB（flavor={flavor}，Google Play 格式）...")
        run(
            f"flutter build appbundle --flavor {flavor} --release"
            f" --obfuscate --split-debug-info=build/debug-info"
            f" {dart_defines} -v"
        )
        # flavor 会影响产物路径：app-{flavor}-release.aab
        output = os.path.join(
            CLIENT_DIR, "build", "app", "outputs", "bundle",
            f"{flavor}Release", f"app-{flavor}-release.aab"
        )
        if os.path.isfile(output):
            dest = os.path.join(dest_dir, "flash_im.aab")
            shutil.copy2(output, dest)
            ok("AAB 构建完成")
            info(f"产物：{dest}")
            info(f"大小：{file_size(dest)}")
        else:
            fail(f"AAB 文件未找到：{output}")
    else:
        # 同时构建 arm64 和 armeabi-v7a
        target_platforms = ",".join(p["flag"] for p in PLATFORMS)
        cmd = (
            f"flutter build apk --flavor {flavor} --release"
            f" --target-platform {target_platforms}"
            f" --split-per-abi"
            f" --obfuscate --split-debug-info=build/debug-info"
            f" {dart_defines} -v"
        )
        info(f"构建 APK（flavor={flavor}，{', '.join(p['folder'] for p in PLATFORMS)}）...")
        run(cmd)

        output_dir = os.path.join(CLIENT_DIR, "build", "app", "outputs", "flutter-apk")
        for platform in PLATFORMS:
            dest_dir = os.path.join(DEST_BASE, platform["folder"])
            os.makedirs(dest_dir, exist_ok=True)

            found = False
            for f in sorted(os.listdir(output_dir)):
                if f.endswith(".apk") and platform["keyword"] in f:
                    src = os.path.join(output_dir, f)
                    dest = os.path.join(dest_dir, "flash_im.apk")
                    shutil.copy2(src, dest)
                    ok(f"{platform['folder']} 构建完成")
                    info(f"产物：{dest}")
                    info(f"大小：{file_size(dest)}")
                    found = True
                    break
            if not found:
                fail(f"{platform['folder']} APK 文件未找到")

    # 计算所有产物的元信息
    info("计算安装包元信息...")
    calc_script = os.path.join(SCRIPT_DIR, "upload", "calculate.py")
    for platform in PLATFORMS:
        apk_path = os.path.join(DEST_BASE, platform["folder"], "flash_im.apk")
        if os.path.isfile(apk_path):
            subprocess.run([sys.executable, calc_script, apk_path, "android"])

    print()


if __name__ == "__main__":
    main()
