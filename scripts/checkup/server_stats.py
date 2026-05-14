"""后端代码统计脚本（望）

统计 server/ 下各模块的文件数、行数、字符数。
用法: python scripts/checkup/server_stats.py
输出: docs/project/checkup/{tag}/server/01_望_结构统计.md
"""

import subprocess
from pathlib import Path
from datetime import date

PROJECT_DIR = Path(__file__).parent.parent.parent
SERVER_DIR = PROJECT_DIR / "server"
MODULES_DIR = SERVER_DIR / "modules"
SRC_DIR = SERVER_DIR / "src"
OUTPUT_DIR = PROJECT_DIR / "docs" / "project" / "checkup"

# 忽略配置
IGNORE_DIRS = {
    "target",       # 构建产物
    ".git",
}

IGNORE_PATTERNS = [
    ".lock",        # Cargo.lock 等
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


def count_rust_files(directory):
    """统计目录下所有 .rs 文件的数量、行数、字符数"""
    files = 0
    lines = 0
    chars = 0
    file_details = []

    for f in sorted(directory.rglob("*.rs")):
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
        # 相对于 module 的 src 目录
        try:
            rel = str(f.relative_to(directory))
        except ValueError:
            rel = f.name
        file_details.append((rel, file_lines, file_chars))

    return files, lines, chars, file_details


def main():
    today = date.today().strftime("%Y-%m-%d")
    tag = get_latest_tag()
    out_dir = OUTPUT_DIR / tag / "server"
    out_dir.mkdir(parents=True, exist_ok=True)
    output_file = out_dir / "01_望_结构统计.md"

    lines_out = []
    def out(text=""):
        print(text)
        lines_out.append(text)

    out("# 后端代码统计")
    out("")
    out(f"日期：{today}　版本：{tag}")
    out("")

    # 1. 各模块统计
    out("## 模块统计")
    out("")
    out("| 模块 | 文件数 | 行数 | 字符数 | 占比 |")
    out("|------|--------|------|--------|------|")

    total_files = 0
    total_lines = 0
    total_chars = 0
    module_stats = []

    # 收集各 workspace member 模块
    for module_dir in sorted(MODULES_DIR.iterdir()):
        if not module_dir.is_dir():
            continue
        src_dir = module_dir / "src"
        if not src_dir.exists():
            continue
        files, lines, chars, details = count_rust_files(src_dir)
        if files > 0:
            module_stats.append((module_dir.name, files, lines, chars, details))
            total_files += files
            total_lines += lines
            total_chars += chars

    # 主工程 src/
    if SRC_DIR.exists():
        files, lines, chars, details = count_rust_files(SRC_DIR)
        if files > 0:
            module_stats.append(("主工程", files, lines, chars, details))
            total_files += files
            total_lines += lines
            total_chars += chars

    # 迁移文件统计
    migrations_dir = SERVER_DIR / "migrations"
    if migrations_dir.exists():
        sql_files = 0
        sql_lines = 0
        sql_chars = 0
        sql_details = []
        for f in sorted(migrations_dir.rglob("*.sql")):
            content = f.read_text(encoding="utf-8", errors="ignore")
            fl = content.count("\n") + 1
            fc = len(content)
            sql_files += 1
            sql_lines += fl
            sql_chars += fc
            sql_details.append((f.name, fl, fc))
        if sql_files > 0:
            module_stats.append(("migrations", sql_files, sql_lines, sql_chars, sql_details))
            total_files += sql_files
            total_lines += sql_lines
            total_chars += sql_chars

    # 输出表格（按行数从高到低）
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
    out("## 小模块提示（文件数 <= 3）")
    out("")
    for name, files, lines, chars, _ in module_stats:
        if files <= 3 and name != "migrations":
            out(f"- {name}: {files} 文件, {lines} 行")

    out("")

    # 写入文件
    output_file.write_text("\n".join(lines_out), encoding="utf-8")
    print(f"\n✅ 统计结果已保存到: {output_file}")


if __name__ == "__main__":
    main()
