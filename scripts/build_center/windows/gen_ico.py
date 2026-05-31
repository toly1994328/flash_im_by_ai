#!/usr/bin/env python3
"""
生成 Windows .ico 图标文件

用法：
  python scripts/build_center/windows/gen_ico.py [源图路径]

默认源图：client/assets/images/logo.png
输出位置：client/windows/runner/resources/app_icon.ico

前置：pip install Pillow
"""

import os
import sys
from PIL import Image

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", ".."))

DEFAULT_SOURCE = os.path.join(PROJECT_ROOT, "client", "assets", "images", "logo.png")
OUTPUT_PATH = os.path.join(PROJECT_ROOT, "client", "windows", "runner", "resources", "app_icon.ico")


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE

    if not os.path.isfile(source):
        print(f"❌ 源图不存在: {source}")
        sys.exit(1)

    img = Image.open(source)
    print(f"📷 源图: {source} ({img.size[0]}×{img.size[1]})")

    # resize 到 256×256
    img = img.resize((256, 256), Image.LANCZOS)

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    img.save(OUTPUT_PATH, format="ICO")

    print(f"✅ 已生成: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
