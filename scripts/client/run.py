#!/usr/bin/env python3
"""
启动前端客户端：支持 Android（默认）/ Windows 桌面
用法:
  python scripts/client/run.py
  python scripts/client/run.py --platform windows
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


def find_android_device():
    """从 flutter devices --machine 中找到第一个 Android 设备 ID"""
    try:
        r = subprocess.run(
            "flutter devices --machine",
            capture_output=True, text=True, encoding="utf-8", cwd=CLIENT_DIR,
            timeout=30, shell=True,
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

    # fallback: 从 adb devices 直接取
    return find_adb_device()


def find_adb_device():
    """从 adb devices 输出中找到第一个在线设备"""
    try:
        r = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=10)
        for line in r.stdout.strip().splitlines()[1:]:
            parts = line.split()
            if len(parts) >= 2 and parts[1] == "device":
                return parts[0]
    except Exception:
        pass
    return None


def run_android():
    print("[CLIENT] Detecting Android devices...")
    device_id = find_android_device()

    if not device_id:
        print(f"[CLIENT] No Android device found, trying adb connect {EMULATOR_ADDR}...")
        subprocess.run(["adb", "connect", EMULATOR_ADDR], timeout=10)
        print("[CLIENT] Waiting for device...")
        time.sleep(5)
        device_id = find_android_device()

    if not device_id:
        # 最后尝试：直接用 adb devices 看看
        print("[CLIENT] Retrying with adb devices...")
        r = subprocess.run(["adb", "devices"], capture_output=True, text=True, timeout=10)
        print(r.stdout)
        time.sleep(3)
        device_id = find_android_device()

    if not device_id:
        print("[CLIENT] ERROR: No Android device found")
        print("[CLIENT] 请确认模拟器已启动，或用 USB 连接真机")
        sys.exit(1)

    print(f"[CLIENT] Device found: {device_id}")
    print("[CLIENT] Starting Flutter on Android...")
    subprocess.run(f"flutter run -d {device_id}", cwd=CLIENT_DIR, shell=True)


def run_windows():
    print("[CLIENT] Starting Flutter on Windows...")
    subprocess.run("flutter run -d windows", cwd=CLIENT_DIR, shell=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="启动 Flutter 客户端")
    parser.add_argument("--platform", "-p", choices=["android", "windows"],
                        default="android", help="目标平台（默认 android）")
    args = parser.parse_args()

    if args.platform == "windows":
        run_windows()
    else:
        run_android()
