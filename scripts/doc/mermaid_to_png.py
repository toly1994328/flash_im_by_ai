#!/usr/bin/env python3
"""
mermaid_to_png.py — 从 mermaid_diagrams.md 中提取所有 mermaid 代码块，导出为 PNG

用法:
  python scripts/doc/mermaid_to_png.py docs/ref/doc/books/draft/25/mermaid_diagrams.md

输出:
  同目录下生成 mermaid_0.png, mermaid_1.png, ...

依赖:
  pip install requests（通常已有）

原理:
  使用 kroki.io 在线渲染服务，将 mermaid 代码 POST 过去，返回 PNG 图片。
  无需安装 node/npm/mmdc。
"""

import base64
import os
import re
import sys
import zlib

try:
    import requests
except ImportError:
    print("需要 requests 库：pip install requests")
    sys.exit(1)


def extract_mermaid_blocks(md_path: str) -> list[tuple[str, str]]:
    """从 markdown 文件中提取所有 mermaid 代码块，返回 [(标题, 代码), ...]"""
    with open(md_path, "r", encoding="utf-8") as f:
        content = f.read()

    blocks = []
    # 匹配 ## N. 标题 和紧随的 ```mermaid ... ```
    pattern = r"## (\d+\..+?)\n\n```mermaid\n(.*?)```"
    for match in re.finditer(pattern, content, re.DOTALL):
        title = match.group(1).strip()
        code = match.group(2).strip()
        blocks.append((title, code))

    return blocks


def render_mermaid_png(mermaid_code: str) -> bytes | None:
    """通过 kroki.io API 将 mermaid 代码渲染为 PNG"""
    # 注入主题配置（base 主题不覆盖自定义 style 配色）
    themed_code = "%%{init: {'theme': 'base', 'themeVariables': {'fontSize': '14px'}}}%%\n" + mermaid_code

    # kroki 接受 base64 编码的 zlib 压缩数据
    compressed = zlib.compress(themed_code.encode("utf-8"), 9)
    encoded = base64.urlsafe_b64encode(compressed).decode("ascii")

    # 先拿 SVG（矢量图，无限清晰）
    url = f"https://kroki.io/mermaid/svg/{encoded}"
    try:
        resp = requests.get(url, timeout=30)
        if resp.status_code == 200:
            return resp.content
        else:
            print(f"  ⚠️ kroki 返回 {resp.status_code}: {resp.text[:100]}")
            return None
    except Exception as e:
        print(f"  ⚠️ 请求失败: {e}")
        return None


def main():
    if len(sys.argv) < 2:
        print("用法: python scripts/doc/mermaid_to_png.py <mermaid_diagrams.md>")
        sys.exit(1)

    md_path = sys.argv[1]
    if not os.path.exists(md_path):
        print(f"文件不存在: {md_path}")
        sys.exit(1)

    out_dir = os.path.join(os.path.dirname(md_path), "images")
    os.makedirs(out_dir, exist_ok=True)

    blocks = extract_mermaid_blocks(md_path)
    if not blocks:
        print("未找到 mermaid 代码块")
        sys.exit(1)

    print(f"找到 {len(blocks)} 个 mermaid 图表，开始导出...\n")

    success = 0
    for i, (title, code) in enumerate(blocks):
        print(f"[{i}] {title}")
        png_data = render_mermaid_png(code)
        if png_data:
            filename = f"mermaid_{i}.svg"
            filepath = os.path.join(out_dir, filename)
            with open(filepath, "wb") as f:
                f.write(png_data)
            print(f"  ✅ → {filepath} ({len(png_data)} bytes)")
            success += 1
        else:
            print(f"  ❌ 导出失败")

    print(f"\n完成：{success}/{len(blocks)} 张图片 → {out_dir}")


if __name__ == "__main__":
    main()
