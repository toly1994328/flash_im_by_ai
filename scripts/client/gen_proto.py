#!/usr/bin/env python3
"""
生成 Dart proto 代码

用法: python scripts/client/gen_proto.py

功能:
  将 proto/ 下的 .proto 文件生成 Dart 代码到 client/modules/flash_im_core/lib/src/data/proto/

何时运行: 修改 proto/ 目录下的 .proto 文件后
"""

import os
import platform
import subprocess
import sys

SYSTEM = platform.system()
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", ".."))
PROTO_DIR = os.path.join(PROJECT_ROOT, "proto")
DART_OUT = os.path.join(
    PROJECT_ROOT,
    "client", "modules", "flash_im_core", "lib", "src", "data", "proto",
)

if SYSTEM == "Windows":
    PROTOC = r"C:\toly\SDK\protoc\bin\protoc.exe"
    DART_PUB_BIN = os.path.join(
        os.environ.get("LOCALAPPDATA", ""), "Pub", "Cache", "bin"
    )
else:
    import shutil
    PROTOC = shutil.which("protoc") or "protoc"
    DART_PUB_BIN = os.path.expanduser("~/.pub-cache/bin")

PROTOS = ["ws.proto", "message.proto"]


def check_tools():
    """检查 protoc 和 protoc-gen-dart 是否可用。"""
    if not os.path.isfile(PROTOC):
        print(f"[错误] protoc 未找到: {PROTOC}")
        return False

    dart_plugin = os.path.join(DART_PUB_BIN, "protoc-gen-dart")
    if SYSTEM == "Windows":
        dart_plugin += ".bat"
    if not os.path.isfile(dart_plugin):
        print(f"[错误] protoc-gen-dart 未找到: {dart_plugin}")
        print("请运行: dart pub global activate protoc_plugin")
        return False

    return True


def gen_dart():
    """生成 Dart proto 代码。"""
    print("[前端] 生成 Dart proto 代码...")
    os.makedirs(DART_OUT, exist_ok=True)

    env = os.environ.copy()
    # 确保 protoc-gen-dart 在 PATH 中（放在最前面） 
    if DART_PUB_BIN not in env.get("PATH", ""):
        env["PATH"] = DART_PUB_BIN + os.pathsep + env["PATH"]

    cmd = [PROTOC, f"--proto_path={PROTO_DIR}", f"--dart_out={DART_OUT}"]
    cmd += [os.path.join(PROTO_DIR, p) for p in PROTOS]

    r = subprocess.run(cmd, env=env)
    if r.returncode != 0:
        print("[前端] 生成失败，请确认 protoc-gen-dart 已安装: dart pub global activate protoc_plugin")
        sys.exit(1)

    print(f"[前端] 完成 → {os.path.relpath(DART_OUT, PROJECT_ROOT)}")
    for p in PROTOS:
        out_file = os.path.join(DART_OUT, p.replace(".proto", ".pb.dart"))
        print(f"         {os.path.relpath(out_file, PROJECT_ROOT)}")


if __name__ == "__main__":
    if not check_tools():
        sys.exit(1)

    gen_dart()
    print("\nDart proto 代码已同步更新。")
