#!/usr/bin/env python3
"""
闪讯客户端启动脚本

用法：
  python scripts/client/run.py                    # Android（自动检测设备）
  python scripts/client/run.py 2                  # Android 第 2 个设备
  python scripts/client/run.py -p windows         # Windows 桌面
  python scripts/client/run.py --env production   # 使用 .env.production 配置
"""

import argparse
import json
import os
import subprocess
import sys
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CLIENT_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", "client"))
EMULATOR_ADDR = "127.0.0.1:7555"


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")
    sys.exit(1)


def list_adb_devices():
    devices = []
    try:
        r = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=10)
        for line in r.stdout.strip().splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == "device":
                devices.append(parts[0])
    except Exception:
        pass
    return devices


def find_android_device():
    try:
        r = subprocess.run(
            "flutter devices --machine",
            capture_output=True, text=True, encoding="utf-8",
            cwd=CLIENT_DIR, timeout=30, shell=True,
        )
        output = r.stdout.strip()
        start = output.find("[")
        if start != -1:
            devices = json.loads(output[start:])
            for d in devices:
                if "android" in d.get("targetPlatform", "").lower():
                    return d["id"]
    except Exception:
        pass
    devices = list_adb_devices()
    return devices[0] if devices else None


def resolve_env_file(env_name):
    """解析环境配置文件路径"""
    env_file = os.path.join(CLIENT_DIR, f".env.{env_name}")
    if not os.path.isfile(env_file):
        fail(f"环境配置文件不存在：{env_file}")
    return env_file


def run_android(index=None, env_file=None, flavor="standard"):
    if index is not None:
        info(f"查找第 {index} 个设备...")
        devices = list_adb_devices()
        if not devices:
            info(f"未找到设备，尝试连接 {EMULATOR_ADDR}...")
            subprocess.run(["adb", "connect", EMULATOR_ADDR], timeout=10)
            time.sleep(3)
            devices = list_adb_devices()
        if not devices:
            fail("未找到 Android 设备")
        if index < 1 or index > len(devices):
            fail(f"设备序号 {index} 超出范围（1~{len(devices)}）")
        device_id = devices[index - 1]
    else:
        info("检测 Android 设备...")
        device_id = find_android_device()
        if not device_id:
            info(f"未找到设备，尝试连接 {EMULATOR_ADDR}...")
            subprocess.run(["adb", "connect", EMULATOR_ADDR], timeout=10)
            time.sleep(5)
            device_id = find_android_device()
        if not device_id:
            fail("未找到 Android 设备，请确认模拟器已启动或 USB 连接真机")

    ok(f"设备：{device_id}")
    cmd = f"flutter run -d {device_id} --flavor {flavor} --dart-define=CHANNEL={flavor}"
    if env_file:
        cmd += f" --dart-define-from-file={env_file}"
    info(f"启动 Flutter（Android，flavor={flavor}）...")
    subprocess.run(cmd, cwd=CLIENT_DIR, shell=True)


def run_windows(env_file=None):
    cmd = "flutter run -d windows"
    if env_file:
        cmd += f" --dart-define-from-file={env_file}"
    info("启动 Flutter（Windows）...")
    subprocess.run(cmd, cwd=CLIENT_DIR, shell=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="闪讯客户端启动脚本")
    parser.add_argument("index", nargs="?", type=int, default=None,
                        help="设备序号（从 1 开始），不传则自动选第一个")
    parser.add_argument("-p", "--platform", choices=["android", "windows"],
                        default="android", help="目标平台（默认 android）")
    parser.add_argument("--env", default="dev",
                        help="环境配置（默认 dev，对应 .env.dev）")
    parser.add_argument("--flavor", choices=["standard", "google"],
                        default="standard", help="Android flavor（默认 standard）")
    args = parser.parse_args()

    env_file = resolve_env_file(args.env)
    info(f"环境：.env.{args.env}")

    if args.platform == "windows":
        run_windows(env_file)
    else:
        run_android(index=args.index, env_file=env_file, flavor=args.flavor)
