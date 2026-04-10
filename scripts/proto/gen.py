#!/usr/bin/env python3
"""
Protobuf 协议代码生成脚本

用法: python scripts/proto/gen.py

功能:
  1. 生成 Rust 代码 → cargo build -p im-ws 触发 prost-build
  2. 生成 Dart 代码 → client/modules/flash_im_core/lib/src/data/proto/

何时运行: 修改 proto/ 目录下的 .proto 文件后
"""

import os
import platform
import subprocess
import sys

SYSTEM = platform.system()
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
SERVER_DIR = os.path.join(PROJECT_ROOT, "server")
PROTO_DIR = os.path.join(PROJECT_ROOT, "proto")
DART_OUT = os.path.join(PROJECT_ROOT, "client", "modules", "flash_im_core", "lib", "src", "data", "proto")

if SYSTEM == "Windows":
    PROTOC = r"C:\toly\SDK\protoc\bin\protoc.exe"
    DART_PUB_BIN = os.path.join(os.environ.get("LOCALAPPDATA", ""), "Pub", "Cache", "bin")
else:
    import shutil
    PROTOC = shutil.which("protoc") or "protoc"
    DART_PUB_BIN = os.path.expanduser("~/.pub-cache/bin")

PROTOS = ["ws.proto", "message.proto"]


def gen_rust():
    print("[后端] 编译 im-ws（触发 prost-build 生成 Rust 代码）...")
    env = os.environ.copy()
    env["PROTOC"] = PROTOC
    r = subprocess.run(["cargo", "build", "-p", "im-ws"], cwd=SERVER_DIR, env=env)
    if r.returncode != 0:
        print("[后端] 编译失败")
        sys.exit(1)
    print("[后端] 完成 → server/modules/im-ws/src/generated/")


def gen_dart():
    print("[前端] 生成 Dart proto 代码...")
    os.makedirs(DART_OUT, exist_ok=True)

    env = os.environ.copy()
    if DART_PUB_BIN not in env.get("PATH", ""):
        env["PATH"] = DART_PUB_BIN + os.pathsep + env.get("PATH", "")

    cmd = [PROTOC, f"--proto_path={PROTO_DIR}", f"--dart_out={DART_OUT}"]
    cmd += [os.path.join(PROTO_DIR, p) for p in PROTOS]

    r = subprocess.run(cmd, env=env)
    if r.returncode != 0:
        print("[前端] 生成失败")
        sys.exit(1)
    print(f"[前端] 完成 → {os.path.relpath(DART_OUT, PROJECT_ROOT)}")


if __name__ == "__main__":
    gen_rust()
    print()
    gen_dart()
    print("\n前后端协议代码已同步更新。")
