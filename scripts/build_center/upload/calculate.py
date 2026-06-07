"""
安装包元信息计算工具

用法：
  python scripts/build_center/upload/calculate.py <文件路径>

示例：
  python scripts/build_center/upload/calculate.py scripts/build_center/dest/android/arm64-v8a/flash_im.apk

输出：
  在文件同级目录生成 meta.json，包含 file_name、file_size、sha256、version 等信息。
"""

import hashlib
import json
import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
PUBSPEC_PATH = PROJECT_ROOT / "client" / "pubspec.yaml"


def get_version_from_pubspec() -> str:
    """从 pubspec.yaml 中提取 version 字段"""
    if not PUBSPEC_PATH.exists():
        return "unknown"
    content: str = PUBSPEC_PATH.read_text(encoding="utf-8")
    match = re.search(r'^version:\s*(.+)$', content, re.MULTILINE)
    if match:
        # 返回 x.y.z 部分（去掉 +buildNumber）
        version_str: str = match.group(1).strip()
        return version_str.split('+')[0]
    return "unknown"


def calculate_sha256(file_path: str) -> str:
    """计算文件的 SHA256 哈希"""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()


def calculate_meta(file_path: str, platform: str = "") -> dict:
    """计算文件的元信息"""
    path = Path(file_path)
    if not path.exists():
        print(f"\033[31m[ERROR]\033[0m 文件不存在: {file_path}")
        sys.exit(1)

    file_size: int = path.stat().st_size
    sha256: str = calculate_sha256(file_path)
    file_name: str = path.name

    meta = {
        "file_name": file_name,
        "version": get_version_from_pubspec(),
        "platform": platform,
        "file_size": file_size,
        "file_size_mb": round(file_size / (1024 * 1024), 2),
        "sha256": sha256,
    }
    return meta


def main():
    if len(sys.argv) < 2:
        print("用法: python scripts/build_center/upload/calculate.py <文件路径>")
        sys.exit(1)

    file_path: str = sys.argv[1]
    platform: str = sys.argv[2] if len(sys.argv) > 2 else ""
    meta: dict = calculate_meta(file_path, platform)

    # 输出到同级目录的 meta.json
    output_dir: Path = Path(file_path).parent
    output_path: Path = output_dir / "meta.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)

    print(f"\033[32m[OK]\033[0m 元信息已生成: {output_path}")
    print(f"     版本:   {meta['version']}")
    print(f"     文件名: {meta['file_name']}")
    print(f"     大小:   {meta['file_size_mb']} MB ({meta['file_size']} bytes)")
    print(f"     SHA256: {meta['sha256']}")


if __name__ == "__main__":
    main()
