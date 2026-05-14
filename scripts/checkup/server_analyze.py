"""后端静态分析脚本（闻）

运行 cargo clippy，解析输出，按类型分类统计，结果保存到体检目录。
用法: python scripts/checkup/server_analyze.py
"""

import subprocess
import re
import json
from pathlib import Path
from datetime import date
from collections import defaultdict

PROJECT_DIR = Path(__file__).parent.parent.parent
SERVER_DIR = PROJECT_DIR / "server"
OUTPUT_DIR = PROJECT_DIR / "docs" / "project" / "checkup"


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


def run_clippy():
    """运行 cargo clippy 并捕获 JSON 输出"""
    result = subprocess.run(
        ["cargo", "clippy", "--workspace", "--message-format=json", "--", "-W", "clippy::all"],
        cwd=str(SERVER_DIR),
        capture_output=True, text=True, shell=True,
    )
    return result.stdout, result.stderr


def parse_clippy_json(stdout):
    """解析 cargo clippy 的 JSON 输出"""
    issues = {"error": [], "warning": [], "info": []}

    for line in stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        if msg.get("reason") != "compiler-message":
            continue

        message = msg.get("message", {})
        level = message.get("level", "")
        text = message.get("message", "")
        code = message.get("code")
        spans = message.get("spans", [])

        # 跳过 note 级别和无 span 的消息
        if level == "note" or level == "help":
            continue
        if not spans:
            continue

        # 取主 span
        primary = next((s for s in spans if s.get("is_primary")), spans[0])
        file_name = primary.get("file_name", "")
        line_start = primary.get("line_start", 0)
        col_start = primary.get("column_start", 0)

        # 跳过非项目文件
        if file_name.startswith("/") or file_name.startswith("\\"):
            continue

        location = f"{file_name}:{line_start}:{col_start}"
        rule = code.get("code", "") if code else ""

        # 分类
        if level == "error":
            issues["error"].append({"message": text, "location": location, "rule": rule})
        elif level == "warning":
            # clippy lint 归为 warning
            issues["warning"].append({"message": text, "location": location, "rule": rule})
        else:
            issues["info"].append({"message": text, "location": location, "rule": rule})

    return issues


def parse_clippy_text(stderr):
    """备用：从 stderr 文本解析（当 JSON 解析结果为空时）"""
    issues = {"error": [], "warning": [], "info": []}

    # 匹配格式: "warning: message"  或 "error[E0123]: message"
    # 后跟 "  --> file:line:col"
    pattern = re.compile(
        r"^(error|warning)(?:\[([^\]]+)\])?: (.+)$"
    )
    location_pattern = re.compile(
        r"^\s+--> (.+):(\d+):(\d+)$"
    )

    lines = stderr.splitlines()
    i = 0
    while i < len(lines):
        m = pattern.match(lines[i])
        if m:
            level, code, message = m.groups()
            code = code or ""
            location = ""
            # 找下一行的位置信息
            if i + 1 < len(lines):
                loc_m = location_pattern.match(lines[i + 1])
                if loc_m:
                    file_name, line_num, col_num = loc_m.groups()
                    location = f"{file_name}:{line_num}:{col_num}"
                    i += 1

            if location and not location.startswith("/"):
                issues[level].append({
                    "message": message.strip(),
                    "location": location,
                    "rule": code,
                })
        i += 1

    return issues


def format_report(issues):
    """生成 markdown 格式的报告"""
    lines = []
    today = date.today().strftime("%Y-%m-%d")

    lines.append("# 后端静态分析（闻）")
    lines.append("")
    lines.append(f"日期：{today}")
    lines.append("")

    # 概览
    lines.append("## 概览")
    lines.append("")
    lines.append("| 级别 | 数量 |")
    lines.append("|------|------|")
    lines.append(f"| 🔴 error | {len(issues['error'])} |")
    lines.append(f"| 🟡 warning | {len(issues['warning'])} |")
    lines.append(f"| 🟢 info | {len(issues['info'])} |")
    lines.append("")

    # Error 详情
    if issues["error"]:
        lines.append("## Error 详情")
        lines.append("")
        lines.append("| # | 规则 | 位置 | 说明 |")
        lines.append("|---|------|------|------|")
        for i, e in enumerate(issues["error"], 1):
            lines.append(f"| {i} | `{e['rule']}` | {e['location']} | {e['message']} |")
        lines.append("")

    # Warning 详情
    if issues["warning"]:
        lines.append("## Warning 详情")
        lines.append("")
        lines.append("| # | 规则 | 位置 | 说明 |")
        lines.append("|---|------|------|------|")
        for i, w in enumerate(issues["warning"], 1):
            msg = w['message'][:80]
            lines.append(f"| {i} | `{w['rule']}` | {w['location']} | {msg} |")
        lines.append("")

    # Warning 按规则分组统计
    if issues["warning"]:
        lines.append("## Warning 统计（按规则分组）")
        lines.append("")
        rule_count = defaultdict(int)
        for w in issues["warning"]:
            rule_count[w["rule"] or "unknown"] += 1

        lines.append("| 规则 | 数量 | 说明 |")
        lines.append("|------|------|------|")
        for rule, count in sorted(rule_count.items(), key=lambda x: -x[1]):
            sample = next(w for w in issues["warning"] if (w["rule"] or "unknown") == rule)
            lines.append(f"| `{rule}` | {count} | {sample['message'][:50]} |")
        lines.append("")

    # 无问题时的提示
    if not issues["error"] and not issues["warning"]:
        lines.append("## 结果")
        lines.append("")
        lines.append("✅ 无 error 和 warning，代码通过 clippy 检查。")
        lines.append("")

    return "\n".join(lines)


def main():
    print("🔍 运行 cargo clippy...")
    stdout, stderr = run_clippy()

    print("📋 解析结果...")
    issues = parse_clippy_json(stdout)

    # 如果 JSON 解析没有结果，尝试从 stderr 文本解析
    total = len(issues["error"]) + len(issues["warning"]) + len(issues["info"])
    if total == 0 and stderr:
        issues = parse_clippy_text(stderr)

    report = format_report(issues)

    # 输出到控制台
    print(report)

    # 保存到文件
    tag = get_latest_tag()
    out_dir = OUTPUT_DIR / tag / "server"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "02_闻_静态分析.md"
    out_file.write_text(report, encoding="utf-8")
    print(f"\n✅ 结果已保存到: {out_file}")


if __name__ == "__main__":
    main()
