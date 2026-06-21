---
name: github-release
description: GitHub Release 发布操作规范。在需要发布版本、上传安装包到 GitHub Release 时激活，确保使用正确的命令和流程。
metadata:
  model: manual
  last_modified: Sat, 20 Jun 2026 00:00:00 GMT

---

# GitHub Release 发布

## 适用场景

- 用户说"发布 release"、"上传到 GitHub"、"发版"时激活
- 打包完成后需要上传安装包（APK / EXE / AppImage 等）
- 需要创建或更新 GitHub Release

## 脚本位置

```
scripts/build_center/upload/release_github.py
```

## 构建产物默认路径

| 平台 | 路径 | 推荐上传名 |
|------|------|-----------|
| Android (arm64) | `scripts/build_center/dest/android/arm64-v8a/flash_im.apk` | `android-flash_im.apk` |
| Windows | `scripts/build_center/dest/windows/flash-im.exe` | `windows-flash-im.exe` |
| Linux | `scripts/build_center/dest/linux/flash_im.AppImage` | `linux-flash_im.AppImage` |
| HarmonyOS | `scripts/build_center/dest/ohos/ohos-default-signed.app` | `ohos-flash_im.app` |

如果用户未指定文件路径，先检查以上路径是否有产物，没有则询问用户。
上传时默认加平台前缀（如 `android-flash_im.apk`）。
鸿蒙产物需用 `--names` 重命名（原文件名含特殊字符，GitHub 不允许）。

## 前置条件

- 环境变量 `GITHUB_TOKEN` 已设置（GitHub Personal Access Token，需 Contents: Read and write 权限）
- 环境变量 `GITHUB_REPO` 可选（默认 `toly1994328/flash_im_by_ai`）
- Python 已安装 `requests` 包

## 使用方式

### 创建 Release + 上传文件（带前缀）

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --title "v1.0.2 正式版" \
  --body "更新内容描述" \
  --prefix android- \
  --files scripts/build_center/dest/android/arm64-v8a/flash_im.apk
```

### 往已有 Release 追加文件

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --prefix linux- \
  --files scripts/build_center/dest/linux/flash_im.AppImage
```

同名文件会自动先删除再上传（覆盖更新）。

### 删除 Release 中的文件

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --delete flash_im.apk flash-im.exe
```

### 删除旧文件 + 重新上传

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --delete flash_im.apk \
  --prefix android- \
  --files scripts/build_center/dest/android/arm64-v8a/flash_im.apk
```

### 自定义文件名上传

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --files path/to/file.apk \
  --names custom-name.apk
```

### 仅创建 Release（不上传文件）

```bash
python scripts/build_center/upload/release_github.py \
  --tag v1.0.2 \
  --title "v1.0.2" \
  --body "描述"
```

## 参数说明

| 参数 | 必需 | 说明 |
|------|------|------|
| `--tag` | ✅ | Release tag，如 `v1.0.2` |
| `--files` | 否 | 要上传的文件路径（空格分隔多个） |
| `--names` | 否 | 自定义文件名（与 --files 一一对应） |
| `--prefix` | 否 | 文件名前缀（如 `windows-`），自动加在文件名前 |
| `--delete` | 否 | 要删除的 asset 文件名（空格分隔多个） |
| `--title` | 否 | Release 标题，默认取 tag |
| `--body` | 否 | Release 描述 |

## 行为说明

1. 如果 tag 对应的 Release 已存在 → 复用，不重新创建
2. 如果上传的文件名在 Release 中已存在 → 先删除旧的再上传新的
3. 创建 Release 时自动在仓库中创建对应 tag（如果 tag 不存在）
4. `--prefix` 和 `--names` 同时指定时，prefix 加在 names 前面
5. `--delete` 在上传之前执行

## 注意事项

- Token 权限不足会报 403，需要到 GitHub 设置中勾选 `Contents: Read and write`
- 大文件上传可能较慢（通过 GitHub Upload API，限制 2GB）
- 工作目录应在项目根目录
