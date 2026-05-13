"""前端代码统计脚本

统计 client/ 下各模块的文件数、行数、字符数。
用法: python scripts/checkup/client_stats.py
输出: docs/project/checkup/ 目录下的统计文件
"""

import os
from pathlib import Path
from collections import defaultdict
from datetime import date

CLIENT_DIR = Path(__file__).parent.parent.parent / "client"
MODULES_DIR = CLIENT_DIR / "modules"
LIB_DIR = CLIENT_DIR / "lib"
OUTPUT_DIR = Path(__file__).parent.parent.parent / "docs" / "project" / "checkup"

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

def count_dart_files(directory):
    """统计目录下所有 .dart 文件的数量、行数、字符数"""
    files = 0
    lines = 0
    chars = 0
    file_details = []
    
    for f in sorted(directory.rglob("*.dart")):
        # 跳过忽略目录
        if any(part in IGNORE_DIRS for part in f.parts):
            continue
        # 跳过生成文件
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
    out_dir = OUTPUT_DIR / f"{today}_client"
    out_dir.mkdir(parents=True, exist_ok=True)
    output_file = out_dir / "01_望_结构统计.md"
    
    lines_out = []
    def out(text=""):
        print(text)
        lines_out.append(text)
    
    out(f"# 前端代码统计")
    out(f"")
    out(f"日期：{today}")
    out("")
    
    # 1. 各模块统计
    out("## 模块统计")
    out("")
    out(f"| 模块 | 文件数 | 行数 | 字符数 |")
    out(f"|------|--------|------|--------|")
    
    total_files = 0
    total_lines = 0
    total_chars = 0
    module_stats = []
    
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
        out(f"| {module_dir.name} | {files} | {lines} | {chars} |")
    
    # 主工程 lib/src（不含 playground）
    src_dir = LIB_DIR / "src"
    if src_dir.exists():
        files, lines, chars, details = count_dart_files(src_dir)
        module_stats.append(("lib/src (主工程)", files, lines, chars, details))
        total_files += files
        total_lines += lines
        total_chars += chars
        out(f"| lib/src (主工程) | {files} | {lines} | {chars} |")
    
    # main.dart
    main_file = LIB_DIR / "main.dart"
    if main_file.exists():
        content = main_file.read_text(encoding="utf-8")
        ml = content.count("\n") + 1
        mc = len(content)
        total_files += 1
        total_lines += ml
        total_chars += mc
        out(f"| main.dart | 1 | {ml} | {mc} |")
    
    # playground（废弃代码）
    pg_dir = LIB_DIR / "playground"
    pg_files = pg_lines = pg_chars = 0
    if pg_dir.exists():
        pg_files, pg_lines, pg_chars, _ = count_dart_files(pg_dir)
        out(f"| playground (废弃) | {pg_files} | {pg_lines} | {pg_chars} |")
    
    out(f"| **合计（不含 playground）** | **{total_files}** | **{total_lines}** | **{total_chars}** |")
    out("")
    
    # 2. 大文件排行
    out("## 大文件 TOP 10（按行数）")
    out("")
    out("| 文件 | 行数 |")
    out("|------|------|")
    
    all_details = []
    for name, _, _, _, details in module_stats:
        for path, lines, chars in details:
            all_details.append((f"{name}/{path}", lines, chars))
    
    all_details.sort(key=lambda x: x[1], reverse=True)
    for path, lines, chars in all_details[:10]:
        out(f"| {path} | {lines} |")
    
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
