"""前端静态分析脚本（闻）

运行 flutter analyze，解析输出，按类型分类统计，结果保存到体检目录。
用法: python scripts/checkup/client_analyze.py
"""

import subprocess
import re
import os
from pathlib import Path
from datetime import date
from collections import defaultdict

PROJECT_DIR = Path(__file__).parent.parent.parent
CLIENT_DIR = PROJECT_DIR / "client"
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


def run_analyze():
    """运行 flutter analyze 并捕获输出"""
    import tempfile
    tmp = tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False, encoding='utf-8')
    tmp.close()
    cmd = f'cd /d "{CLIENT_DIR}" && flutter analyze > "{tmp.name}" 2>&1'
    os.system(cmd)
    with open(tmp.name, 'r', encoding='utf-8', errors='ignore') as f:
        output = f.read()
    os.unlink(tmp.name)
    return output


def parse_issues(output):
    """解析 flutter analyze 输出，提取 error/warning/info"""
    issues = {"error": [], "warning": [], "info": []}
    
    # 匹配格式: "   info - message - file:line:col - rule_name"
    # 或 "warning - message - file:line:col - rule_name"
    pattern = re.compile(
        r"^\s*(error|warning|info)\s+-\s+(.+?)\s+-\s+(.+?)\s+-\s*(\S+)\s*$"
    )
    
    for line in output.splitlines():
        m = pattern.match(line)
        if m:
            level, message, location, rule = m.groups()
            issues[level].append({
                "message": message.strip(),
                "location": location.strip(),
                "rule": rule.strip(),
            })
    
    return issues


def format_report(issues):
    """生成 markdown 格式的报告"""
    lines = []
    today = date.today().strftime("%Y-%m-%d")
    
    lines.append("# 前端静态分析（闻）")
    lines.append("")
    lines.append(f"日期：{today}")
    lines.append("")
    
    # 概览
    lines.append("## 概览")
    lines.append("")
    lines.append(f"| 级别 | 数量 |")
    lines.append(f"|------|------|")
    lines.append(f"| 🔴 error | {len(issues['error'])} |")
    lines.append(f"| 🟡 warning | {len(issues['warning'])} |")
    lines.append(f"| 🟢 info | {len(issues['info'])} |")
    lines.append("")
    
    # Warning 详情
    if issues["warning"]:
        lines.append("## Warning 详情")
        lines.append("")
        lines.append("| # | 规则 | 位置 | 说明 |")
        lines.append("|---|------|------|------|")
        for i, w in enumerate(issues["warning"], 1):
            lines.append(f"| {i} | `{w['rule']}` | {w['location']} | {w['message']} |")
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
    
    # Info 按规则分组统计
    if issues["info"]:
        lines.append("## Info 统计（按规则分组）")
        lines.append("")
        rule_count = defaultdict(int)
        for info in issues["info"]:
            rule_count[info["rule"]] += 1
        
        lines.append("| 规则 | 数量 | 说明 |")
        lines.append("|------|------|------|")
        for rule, count in sorted(rule_count.items(), key=lambda x: -x[1]):
            sample = next(i for i in issues["info"] if i["rule"] == rule)
            lines.append(f"| `{rule}` | {count} | {sample['message'][:50]} |")
        lines.append("")
    
    return "\n".join(lines)


def main():
    print("🔍 运行 flutter analyze...")
    output = run_analyze()
    
    print("📋 解析结果...")
    issues = parse_issues(output)
    
    report = format_report(issues)
    
    # 输出到控制台
    print(report)
    
    # 保存到文件
    tag = get_latest_tag()
    out_dir = OUTPUT_DIR / tag / "client"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "02_闻_静态分析.md"
    out_file.write_text(report, encoding="utf-8")
    print(f"\n✅ 结果已保存到: {out_file}")
    out_file.write_text(report, encoding="utf-8")
    print(f"\n✅ 结果已保存到: {out_file}")


if __name__ == "__main__":
    main()
