"""
版本上传工具

根据平台名自动寻址 meta.json 和产物文件，调用后端接口创建版本记录。
上传前校验：版本是否已存在、版本号是否高于当前最新。

用法：
  python scripts/build_center/upload/update.py <platform>

示例：
  python scripts/build_center/upload/update.py android
  python scripts/build_center/upload/update.py windows
"""

import json
import subprocess
import sys
from pathlib import Path


DEFAULT_SERVER = "http://127.0.0.1:9600"
DEFAULT_APP_ID = "1"

SCRIPT_DIR = Path(__file__).resolve().parent
BUILD_JSON = SCRIPT_DIR.parent / "build.json"
DEST_DIR = SCRIPT_DIR.parent / "dest"

# 平台 → 产物子目录的映射
PLATFORM_PATHS: dict = {
    "android": "android/arm64-v8a",
    "windows": "windows",
    "macos": "macos",
    "linux": "linux",
    "ohos": "ohos",
}


def load_server_config() -> dict:
    """从 build.json 读取 server 配置"""
    if BUILD_JSON.exists():
        config: dict = json.loads(BUILD_JSON.read_text(encoding="utf-8"))
        return config.get("server", {})
    return {}

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def info(msg: str):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg: str):
    print(f"{GREEN}[ OK ]{RESET} {msg}")


def fail(msg: str):
    print(f"{RED}[FAIL]{RESET} {msg}")
    sys.exit(1)


def warn(msg: str):
    print(f"{YELLOW}[WARN]{RESET} {msg}")


def parse_version(version_str: str) -> tuple:
    """解析版本号为元组，用于比较"""
    parts = version_str.split(".")
    return tuple(int(p) for p in parts)


def curl_get(url: str) -> dict:
    """GET 请求"""
    result = subprocess.run(
        ["curl.exe", "-s", "-w", "\n%{http_code}", url],
        capture_output=True, text=True, encoding="utf-8"
    )
    lines = result.stdout.rsplit("\n", 1)
    body: str = lines[0] if len(lines) > 1 else ""
    status: int = int(lines[-1]) if lines[-1].isdigit() else 0
    data = None
    if body.strip():
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            pass
    return {"status": status, "body": body, "data": data}


def curl_post(url: str, json_body: str) -> dict:
    """POST 请求"""
    result = subprocess.run(
        ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", "POST", url,
         "-H", "Content-Type: application/json", "-d", json_body],
        capture_output=True, text=True, encoding="utf-8"
    )
    lines = result.stdout.rsplit("\n", 1)
    body: str = lines[0] if len(lines) > 1 else ""
    status: int = int(lines[-1]) if lines[-1].isdigit() else 0
    data = None
    if body.strip():
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            pass
    return {"status": status, "body": body, "data": data}


def main():
    if len(sys.argv) < 2:
        print("用法: python scripts/build_center/upload/update.py <platform>")
        print("支持: android, windows, macos, linux, ohos")
        sys.exit(1)

    platform_arg: str = sys.argv[1]
    args: list = sys.argv[2:]

    # 自动寻址 meta.json
    sub_path: str = PLATFORM_PATHS.get(platform_arg, platform_arg)
    meta_file: Path = DEST_DIR / sub_path / "meta.json"

    if not meta_file.exists():
        fail(f"meta.json 不存在: {meta_file}\n  请先构建并运行 calculate.py")

    # 解析参数（build.json 优先，命令行覆盖）
    server_config: dict = load_server_config()
    server: str = server_config.get("runner", DEFAULT_SERVER)
    upload_to: str = server_config.get("uploadTo", "")
    file_prefix: str = server_config.get("filePrefix", server)
    app_id: str = DEFAULT_APP_ID

    if "--server" in args:
        idx: int = args.index("--server")
        server = args[idx + 1]
    if "--app-id" in args:
        idx: int = args.index("--app-id")
        app_id = args[idx + 1]

    # 读取 meta.json
    meta: dict = json.loads(meta_file.read_text(encoding="utf-8"))
    version: str = meta.get("version", "")
    platform: str = meta.get("platform", "")
    file_size: int = meta.get("file_size", 0)
    sha256: str = meta.get("sha256", "")
    file_name: str = meta.get("file_name", "")

    if not version or not platform:
        fail("meta.json 缺少 version 或 platform 字段")

    print()
    print(f"{CYAN}══════════════════════════════════════{RESET}")
    print(f"{CYAN}  版本上传: {platform} v{version}{RESET}")
    print(f"{CYAN}══════════════════════════════════════{RESET}")
    print()

    # ─── 校验 1：查询当前最新版本 ───

    info(f"查询 {platform} 当前最新版本...")
    check_url: str = f"{server}/api/app/version?app_id={app_id}&platform={platform}"
    r: dict = curl_get(check_url)

    if r["status"] == 200 and r["data"]:
        current_version: str = r["data"]["version"]
        info(f"当前最新版本: v{current_version}")

        # 校验版本号是否更高
        if parse_version(version) <= parse_version(current_version):
            fail(f"上传版本 v{version} 不高于当前版本 v{current_version}，终止上传")

        # 校验是否已存在同版本
        versions_url: str = f"{server}/api/app/versions?app_id={app_id}"
        rv: dict = curl_get(versions_url)
        if rv["status"] == 200 and rv["data"]:
            existing: list = [v for v in rv["data"] if v["platform"] == platform and v["version"] == version]
            if existing:
                fail(f"版本 {platform} v{version} 已存在，终止上传")

    elif r["status"] == 404:
        info(f"{platform} 暂无版本记录，将创建首个版本")
    else:
        warn(f"查询失败（status={r['status']}），继续尝试上传")

    # ─── 上传产物到服务器 ───

    # 服务器目录：~/server/flash_im/static/application/v{version}/{file_name}
    remote_dir: str = f"~/server/flash_im/static/application/v{version}"
    apk_path: Path = meta_file.parent / file_name
    download_url: str = f"{file_prefix}/static/application/v{version}/{file_name}"

    if apk_path.exists() and upload_to:
        info(f"上传产物到 {upload_to}:{remote_dir}/{file_name} ...")
        subprocess.run(["ssh", upload_to, f"mkdir -p {remote_dir}"], check=False)
        scp_result = subprocess.run(["scp", str(apk_path), f"{upload_to}:{remote_dir}/{file_name}"])
        if scp_result.returncode == 0:
            ok(f"产物已上传: {download_url}")
        else:
            warn("产物上传失败，版本记录仍会创建（下载地址可能不可用）")
    elif not upload_to:
        warn("build.json 未配置 uploadTo，跳过文件上传")
    else:
        warn(f"产物文件不存在: {apk_path}，跳过上传")

    # ─── 上传版本记录 ───

    info("创建版本记录...")

    payload: dict = {
        "app_id": app_id,
        "platform": platform,
        "version": version,
        "download_url": download_url,
        "file_size": file_size,
        "sha256": sha256,
        "release_notes": "",
        "force_update": False,
    }

    create_url: str = f"{server}/api/app/version"
    r = curl_post(create_url, json.dumps(payload))

    if r["status"] == 201:
        ok(f"版本记录创建成功: {platform} v{version}")
        info(f"下载地址（占位）: {download_url}")
        info("请在 Web 后台确认信息后手动发布")
    elif r["status"] == 400 and "already exists" in (r.get("body") or ""):
        fail(f"版本 {platform} v{version} 已存在")
    else:
        fail(f"创建失败: status={r['status']}, body={r['body']}")

    print()


if __name__ == "__main__":
    main()
