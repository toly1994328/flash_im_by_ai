"""
将 pub 依赖库源码复制到 docs/ref/ 下作为 AI 参考。

用法：
  python .kiro/skills/dep-source-ref/copy_dep_ref.py <源路径> [目标名称]

示例：
  # 从本地项目路径复制
  python .kiro/skills/dep-source-ref/copy_dep_ref.py C:\toly\Project\toly1994\Flutter\toly_fx

  # 从 pub cache 复制（自动从 pubspec.lock 查找版本）
  python .kiro/skills/dep-source-ref/copy_dep_ref.py tolyui_rx_layout

  # 指定目标名称
  python .kiro/skills/dep-source-ref/copy_dep_ref.py C:\toly\Project\toly1994\Flutter\toly_fx toly_fx
"""

import sys
import os
import shutil
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent
CLIENT_DIR = PROJECT_ROOT / "client"
REF_DIR = PROJECT_ROOT / "docs" / "ref"

# 复制时排除的目录/文件
EXCLUDE_DIRS = {".git", ".dart_tool", "build", ".idea", ".gradle", "node_modules"}
EXCLUDE_EXTENSIONS = {".lock"}


def get_pub_cache_path():
    """获取 pub cache 路径"""
    if sys.platform == "win32":
        return Path(os.environ.get("LOCALAPPDATA", "")) / "Pub" / "Cache" / "hosted" / "pub.dev"
    return Path.home() / ".pub-cache" / "hosted" / "pub.dev"


def get_version_from_lock(package_name: str) -> str | None:
    """从 pubspec.lock 中获取包的精确版本（简单解析，不依赖 yaml 库）"""
    lock_file = CLIENT_DIR / "pubspec.lock"
    if not lock_file.exists():
        return None
    lines = lock_file.read_text(encoding="utf-8").splitlines()
    found_pkg = False
    for i, line in enumerate(lines):
        if line.strip() == f"{package_name}:":
            found_pkg = True
        elif found_pkg and line.strip().startswith("version:"):
            version = line.strip().split('"')[1] if '"' in line else line.strip().split(": ")[1]
            return version
        elif found_pkg and not line.startswith(" "):
            break
    return None


def copy_with_filter(src: Path, dst: Path):
    """复制目录，排除不需要的文件"""
    if dst.exists():
        shutil.rmtree(dst)
    
    def ignore_fn(directory, contents):
        ignored = set()
        for item in contents:
            if item in EXCLUDE_DIRS:
                ignored.add(item)
            elif any(item.endswith(ext) for ext in EXCLUDE_EXTENSIONS):
                ignored.add(item)
        return ignored

    shutil.copytree(src, dst, ignore=ignore_fn)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    source = sys.argv[1]
    target_name = sys.argv[2] if len(sys.argv) > 2 else None

    source_path = Path(source)

    # 情况 1：源是一个存在的目录路径
    if source_path.is_dir():
        name = target_name or source_path.name
        dest = REF_DIR / name
        print(f"[INFO] 复制本地项目: {source_path}")
        print(f"[INFO] 目标: {dest}")
        copy_with_filter(source_path, dest)
        print(f"[ OK ] 已复制到 docs/ref/{name}/")
        return

    # 情况 2：源是包名，从 pub cache 查找
    package_name = source
    version = get_version_from_lock(package_name)
    if not version:
        print(f"[FAIL] 在 pubspec.lock 中未找到包: {package_name}")
        sys.exit(1)

    cache_dir = get_pub_cache_path() / f"{package_name}-{version}"
    if not cache_dir.is_dir():
        print(f"[FAIL] pub cache 中未找到: {cache_dir}")
        print(f"[INFO] 尝试运行: cd client && flutter pub get")
        sys.exit(1)

    name = target_name or f"{package_name}-{version}"
    dest = REF_DIR / name
    print(f"[INFO] 从 pub cache 复制: {cache_dir}")
    print(f"[INFO] 目标: {dest}")
    copy_with_filter(cache_dir, dest)
    print(f"[ OK ] 已复制到 docs/ref/{name}/")


if __name__ == "__main__":
    main()
