"""前端代码统计脚本（望）

统计 client/ 下各模块的文件数、行数、字符数。
用法: python scripts/checkup/client_stats.py
输出: docs/project/checkup/{tag}_client/01_望_结构统计.md
"""

import os
import subprocess
from pathlib import Path
from datetime import date

PROJECT_DIR = Path(__file__).parent.parent.parent
CLIENT_DIR = PROJECT_DIR / "client"
MODULES_DIR = CLIENT_DIR / "modules"
LIB_DIR = CLIENT_DIR / "lib"
OUTPUT_DIR = PROJECT_DIR / "docs" / "project" / "checkup"

# 忽略配置
IGNORE_DIRS = {
    "playground",      # 废弃的原型代码
    ".dart_tool",      # 工具生成
    "build",           # 构建产物
}

IGNORE_PATTERNS = [
    ".pb.dart",        # protobuf 生成
    ".pbenum.dart",    # protobuf 生成
    ".pbserver.dart",  # protobuf 生成
    ".pbjson.dart",    # protobuf 生成
    ".g.dart",         # build_runner 生成（drift 等）
    ".freezed.dart",   # freezed 生成
]


def get_latest_tag():
    """从 git 获取最新 tag"""
    try:
        result = subprocess.run(
            ["git", "describe", "--tags", "--abbrev=0"],
            cwd=str(PROJECT_DIR),
            capture_output=True, text=True, shell=True,
        )
        tag = result.stdout.strip()
        return tag if tag else "unknown"
    except:
        return "unknown"


def count_dart_files(directory):
    """统计目录下所有 .dart 文件的数量、行数、字符数"""
    files = 0
    lines = 0
    chars = 0
    file_details = []

    for f in sorted(directory.rglob("*.dart")):
        if any(part in IGNORE_DIRS for part in f.parts):
            continue
        if any(f.name.endswith(pat) for pat in IGNORE_PATTERNS):
            continue
        content = f.read_text(encoding="utf-8", errors="ignore")
        file_lines = content.count("\n") + 1
        file_chars = len(content)
        files += 1
        lines += file_lines
        chars += file_chars
        file_details.append((str(f.relative_to(directory)), file_lines, file_chars))

    return files, lines, chars, file_details


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    today = date.today().strftime("%Y-%m-%d")
    tag = get_latest_tag()
    out_dir = OUTPUT_DIR / f"{tag}_client"
    out_dir.mkdir(parents=True, exist_ok=True)
    output_file = out_dir / "01_望_结构统计.md"

    lines_out = []
    def out(text=""):
        print(text)
        lines_out.append(text)

    out(f"# 前端代码统计")
    out(f"")
    out(f"日期：{today}　版本：{tag}")
    out("")

    # 1. 各模块统计
    out("## 模块统计")
    out("")
    out(f"| 模块 | 文件数 | 行数 | 字符数 | 占比 |")
    out(f"|------|--------|------|--------|------|")

    total_files = 0
    total_lines = 0
    total_chars = 0
    module_stats = []

    # 先收集所有数据
    for module_dir in sorted(MODULES_DIR.iterdir()):
        if not module_dir.is_dir():
            continue
        lib_dir = module_dir / "lib"
        if not lib_dir.exists():
            continue
        files, lines, chars, details = count_dart_files(lib_dir)
        module_stats.append((module_dir.name, files, lines, chars, details))
        total_files += files
        total_lines += lines
        total_chars += chars

    # 主工程 lib/src + main.dart
    src_dir = LIB_DIR / "src"
    main_file = LIB_DIR / "main.dart"
    app_files = 0
    app_lines = 0
    app_chars = 0
    app_details = []

    if src_dir.exists():
        files, lines, chars, details = count_dart_files(src_dir)
        app_files += files
        app_lines += lines
        app_chars += chars
        app_details.extend(details)

    if main_file.exists():
        content = main_file.read_text(encoding="utf-8")
        ml = content.count("\n") + 1
        mc = len(content)
        app_files += 1
        app_lines += ml
        app_chars += mc
        app_details.append(("main.dart", ml, mc))

    if app_files > 0:
        module_stats.append(("主工程", app_files, app_lines, app_chars, app_details))
        total_files += app_files
        total_lines += app_lines
        total_chars += app_chars

    # 输出表格（按行数占比从高到低排列）
    module_stats.sort(key=lambda x: x[2], reverse=True)
    for name, files, lines, chars, _ in module_stats:
        pct = f"{lines / total_lines * 100:.1f}%" if total_lines > 0 else "0%"
        out(f"| {name} | {files} | {lines} | {chars} | {pct} |")

    out(f"| **合计** | **{total_files}** | **{total_lines}** | **{total_chars}** | **100%** |")
    out("")

    # 2. 大文件排行
    out("## 大文件 TOP 10（按行数）")
    out("")
    out("| 模块 | 路径 | 行数 | 字符数 |")
    out("|------|------|------|--------|")

    all_details = []
    for name, _, _, _, details in module_stats:
        for path, lines, chars in details:
            all_details.append((name, path, lines, chars))

    all_details.sort(key=lambda x: x[2], reverse=True)
    for name, path, lines, chars in all_details[:10]:
        out(f"| {name} | {path} | {lines} | {chars} |")

    out("")

    # 3. 小模块提示
    out("## 小模块提示（文件数 <= 5）")
    out("")
    for name, files, lines, chars, _ in module_stats:
        if files <= 5:
            out(f"- {name}: {files} 文件, {lines} 行")

    out("")

    # 写入文件
    output_file.write_text("\n".join(lines_out), encoding="utf-8")
    print(f"\n✅ 统计结果已保存到: {output_file}")


if __name__ == "__main__":
    main()
