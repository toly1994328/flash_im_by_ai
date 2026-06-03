"""
闪讯鸿蒙（HarmonyOS）构建脚本

构建前自动切换为鸿蒙配置（overrides + EmptyLocalStore），
构建后无论成功失败都还原为正常配置。

用法：
  python scripts/build_center/build_ohos.py              # 构建（自动切换+还原）
  python scripts/build_center/build_ohos.py save         # 切换到鸿蒙状态（保持，方便调试）
  python scripts/build_center/build_ohos.py restore      # 还原为主项目状态
"""

import sys
import json
import shutil
import subprocess
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent
CLIENT_DIR = PROJECT_ROOT / "client"
BUILD_JSON = SCRIPT_DIR / "build.json"

# 需要切换的文件
OVERRIDES_FILE = CLIENT_DIR / "pubspec_overrides.yaml"
OVERRIDES_OHOS = CLIENT_DIR / "pubspec_overrides_ohos.yaml"
OVERRIDES_BACKUP = CLIENT_DIR / "pubspec_overrides.yaml.bak"
MAIN_DART = CLIENT_DIR / "lib" / "main.dart"
MAIN_DART_BACKUP = CLIENT_DIR / "lib" / "main.dart.bak"
PUBSPEC_FILE = CLIENT_DIR / "pubspec.yaml"
PUBSPEC_BACKUP = CLIENT_DIR / "pubspec.yaml.bak"


def info(msg):
    print(f"\033[34m[INFO]\033[0m {msg}")


def ok(msg):
    print(f"\033[32m[ OK ]\033[0m {msg}")


def fail(msg):
    print(f"\033[31m[FAIL]\033[0m {msg}")


def load_flutter_path():
    if not BUILD_JSON.exists():
        fail(f"配置文件不存在: {BUILD_JSON}")
        sys.exit(1)
    config = json.loads(BUILD_JSON.read_text(encoding="utf-8"))
    flutter = config.get("ohos", {}).get("flutter")
    if not flutter:
        fail("build.json 中未配置 ohos.flutter 路径")
        sys.exit(1)
    if not Path(flutter).exists():
        fail(f"Flutter 路径不存在: {flutter}")
        sys.exit(1)
    return flutter


def run(cmd, cwd=None):
    info(f"$ {cmd}")
    result = subprocess.run(cmd, shell=True, cwd=cwd)
    if result.returncode != 0:
        raise RuntimeError(f"命令执行失败: {cmd}")


def apply_ohos_config():
    """切换到鸿蒙配置"""
    info("切换到鸿蒙配置...")

    # 1. 备份 + 替换 pubspec_overrides.yaml
    shutil.copy2(OVERRIDES_FILE, OVERRIDES_BACKUP)
    shutil.copy2(OVERRIDES_OHOS, OVERRIDES_FILE)

    # 2. 备份 + 修改 pubspec.yaml（注释掉 flash_im_cache_drift）
    shutil.copy2(PUBSPEC_FILE, PUBSPEC_BACKUP)
    content = PUBSPEC_FILE.read_text(encoding="utf-8")
    content = content.replace(
        "  flash_im_cache_drift:\n    path: modules/flash_im_cache_drift",
        "  # flash_im_cache_drift:\n  #   path: modules/flash_im_cache_drift"
    )
    PUBSPEC_FILE.write_text(content, encoding="utf-8")

    # 3. 备份 + 修改 main.dart（DriftLocalStore → EmptyLocalStore）
    shutil.copy2(MAIN_DART, MAIN_DART_BACKUP)
    content = MAIN_DART.read_text(encoding="utf-8")
    content = content.replace(
        "import 'package:flash_im_cache_drift/flash_im_cache_drift.dart';",
        "// import 'package:flash_im_cache_drift/flash_im_cache_drift.dart';"
    )
    content = content.replace(
        "localStore = await DriftLocalStore.open(user.userId);",
        "localStore = EmptyLocalStore();"
    )
    MAIN_DART.write_text(content, encoding="utf-8")

    ok("鸿蒙配置已应用")


def restore_config():
    """还原正常配置"""
    info("还原正常配置...")
    restored = False

    if OVERRIDES_BACKUP.exists():
        shutil.move(str(OVERRIDES_BACKUP), str(OVERRIDES_FILE))
        restored = True

    if PUBSPEC_BACKUP.exists():
        shutil.move(str(PUBSPEC_BACKUP), str(PUBSPEC_FILE))
        restored = True

    if MAIN_DART_BACKUP.exists():
        shutil.move(str(MAIN_DART_BACKUP), str(MAIN_DART))
        restored = True

    if restored:
        ok("配置已还原")
    else:
        info("无需还原（未找到备份文件）")


def main():
    print()
    print("╔══════════════════════════════════════════╗")
    print("║   闪讯 HarmonyOS 构建                    ║")
    print("╚══════════════════════════════════════════╝")
    print()

    # 子命令处理
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"

    if cmd == "save":
        # 切换到鸿蒙状态并保持
        apply_ohos_config()
        print()
        ok("已切换到鸿蒙状态（使用 'build_ohos.py restore' 恢复）")
        return

    if cmd == "restore":
        # 还原为主项目状态
        restore_config()
        return

    # 默认：构建
    flutter = load_flutter_path()
    info(f"Flutter SDK: {flutter}")

    try:
        # 切换配置
        apply_ohos_config()

        # 1. clean
        info("清理旧产物...")
        run(f'"{flutter}" clean', cwd=CLIENT_DIR)

        # 2. pub get
        info("获取依赖...")
        run(f'"{flutter}" pub get', cwd=CLIENT_DIR)

        # 3. build hap
        info("构建 HAP (release)...")
        run(f'"{flutter}" build hap --release', cwd=CLIENT_DIR)

        # 检查产物
        hap_dir = CLIENT_DIR / "build" / "ohos" / "hap"
        hap_files = list(hap_dir.glob("*.hap")) if hap_dir.exists() else []
        if hap_files:
            for f in hap_files:
                size = f.stat().st_size / (1024 * 1024)
                ok(f"产物: {f.name} ({size:.1f} MB)")
        else:
            info("构建完成，但未找到 .hap 文件（可能需要先配置签名）")

        print()
        ok("鸿蒙构建完成!")

    except Exception as e:
        print()
        fail(f"构建失败: {e}")

    finally:
        # 无论成功失败都还原
        restore_config()


if __name__ == "__main__":
    main()
