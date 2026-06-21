"""
GitHub Release 管理脚本

功能：
  - 创建 Release（如果不存在）
  - 上传附件到 Release（同名文件会先删除再上传）

用法：
  python release_github.py --tag v0.38.0 --files path/to/file1.apk path/to/file2.exe
  python release_github.py --tag v0.38.0 --files path/to/file.apk --title "v0.38.0 正式版" --body "更新内容"

环境变量：
  GITHUB_TOKEN  - GitHub Personal Access Token（必需）
  GITHUB_REPO   - 仓库名，默认 toly1994328/flash_im_by_ai
"""

import argparse
import os
import sys
import mimetypes
from pathlib import Path

try:
    import requests
except ImportError:
    print("❌ 请先安装 requests: pip install requests")
    sys.exit(1)


GITHUB_API = "https://api.github.com"
DEFAULT_REPO = "toly1994328/flash_im_by_ai"


def get_config():
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        print("❌ 未设置 GITHUB_TOKEN 环境变量")
        print("   请在 GitHub Settings > Developer settings > Personal access tokens 创建 token")
        print("   需要 repo 权限")
        sys.exit(1)
    repo = os.environ.get("GITHUB_REPO", DEFAULT_REPO)
    return token, repo


def headers(token: str) -> dict:
    return {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json",
    }


def get_release_by_tag(token: str, repo: str, tag: str) -> dict | None:
    """查询指定 tag 的 release，不存在返回 None"""
    res = requests.get(f"{GITHUB_API}/repos/{repo}/releases/tags/{tag}", headers=headers(token))
    if res.status_code == 200:
        return res.json()
    return None


def create_release(token: str, repo: str, tag: str, title: str, body: str) -> dict:
    """创建新 release"""
    print(f"📦 创建 Release: {tag}")
    res = requests.post(
        f"{GITHUB_API}/repos/{repo}/releases",
        headers=headers(token),
        json={
            "tag_name": tag,
            "name": title or tag,
            "body": body or f"Release {tag}",
            "draft": False,
            "prerelease": False,
        },
    )
    if res.status_code not in (200, 201):
        print(f"❌ 创建失败: {res.status_code} {res.text}")
        sys.exit(1)
    data = res.json()
    print(f"✅ Release 创建成功: {data['html_url']}")
    return data


def delete_asset_by_name(token: str, repo: str, release_id: int, filename: str):
    """删除 release 中同名的 asset"""
    res = requests.get(
        f"{GITHUB_API}/repos/{repo}/releases/{release_id}/assets",
        headers=headers(token),
    )
    if res.status_code != 200:
        return
    for asset in res.json():
        if asset["name"] == filename:
            print(f"  🗑️  删除旧文件: {filename}")
            requests.delete(
                f"{GITHUB_API}/repos/{repo}/releases/assets/{asset['id']}",
                headers=headers(token),
            )
            break


def upload_asset(token: str, upload_url: str, filepath: str, custom_name: str | None = None):
    """上传文件到 release"""
    path = Path(filepath)
    if not path.exists():
        print(f"  ⚠️  文件不存在，跳过: {filepath}")
        return

    filename = custom_name or path.name
    filesize = path.stat().st_size
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"

    print(f"  📤 上传: {filename} ({filesize / 1024 / 1024:.1f} MB)")

    # upload_url 格式: https://uploads.github.com/repos/.../releases/.../assets{?name,label}
    url = upload_url.split("{")[0] + f"?name={filename}"

    with open(filepath, "rb") as f:
        res = requests.post(
            url,
            headers={
                "Authorization": f"token {token}",
                "Content-Type": content_type,
            },
            data=f,
        )

    if res.status_code in (200, 201):
        print(f"  ✅ 上传成功: {res.json()['browser_download_url']}")
    else:
        print(f"  ❌ 上传失败: {res.status_code} {res.text[:200]}")


def main():
    parser = argparse.ArgumentParser(description="GitHub Release 管理")
    parser.add_argument("--tag", required=True, help="Release tag (如 v0.38.0)")
    parser.add_argument("--files", nargs="+", default=[], help="要上传的文件路径")
    parser.add_argument("--names", nargs="+", default=[], help="上传后的文件名（与 --files 一一对应，不指定则用原文件名）")
    parser.add_argument("--prefix", default="", help="文件名前缀（如 windows-），自动加在文件名前")
    parser.add_argument("--delete", nargs="+", default=[], dest="delete_names", help="要删除的 asset 文件名")
    parser.add_argument("--title", default="", help="Release 标题")
    parser.add_argument("--body", default="", help="Release 描述")
    args = parser.parse_args()

    token, repo = get_config()
    print(f"🔧 仓库: {repo}")
    print(f"🏷️  Tag: {args.tag}")

    # 查找或创建 release
    release = get_release_by_tag(token, repo, args.tag)
    if release:
        print(f"📦 Release 已存在: {release['html_url']}")
    else:
        release = create_release(token, repo, args.tag, args.title, args.body)

    release_id = release["id"]
    upload_url = release["upload_url"]

    # 删除指定 asset
    if args.delete_names:
        print(f"\n🗑️  删除 {len(args.delete_names)} 个文件:")
        for name in args.delete_names:
            delete_asset_by_name(token, repo, release_id, name)

    # 上传文件
    if not args.files:
        if not args.delete_names:
            print("ℹ️  无文件需要上传")
        return

    print(f"\n📎 上传 {len(args.files)} 个文件:")
    for i, filepath in enumerate(args.files):
        base_name = args.names[i] if i < len(args.names) else Path(filepath).name
        filename = f"{args.prefix}{base_name}" if args.prefix else base_name
        delete_asset_by_name(token, repo, release_id, filename)
        upload_asset(token, upload_url, filepath, filename)

    print("\n🎉 完成！")


if __name__ == "__main__":
    main()
