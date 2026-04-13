#!/usr/bin/env python3
"""
创建群聊 / 加入群聊 便捷脚本

用法:
  # 0001 创建群聊，成员 0002~0005
  python scripts/server/im/create_group.py 0001 0002-0005 "周末爬山群"

  # 0001 创建群聊，成员 0002,0003,0010
  python scripts/server/im/create_group.py 0001 0002,0003,0010 "测试群"

  # 0006 加入已有群聊（需要群 ID）
  python scripts/server/im/create_group.py --join 0006 <group_id>

  # 0006 加入已有群聊，带留言
  python scripts/server/im/create_group.py --join 0006 <group_id> "请让我加入"

参数:
  创建模式（默认）:
    第1个: 群主后缀
    第2个: 成员后缀（逗号分隔 / 连字符范围）
    第3个: 群名称

  加入模式（--join）:
    第1个: 申请者后缀
    第2个: 群聊 ID（UUID）
    第3个: 留言（可选）
"""

import json
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_PREFIX = "1380001"

_login_cache = {}


def parse_suffixes(s):
    results = []
    for part in s.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            for i in range(int(start), int(end) + 1):
                results.append(str(i).zfill(4))
        else:
            results.append(part.zfill(4))
    return results


def curl_post(url, data=None, token=None):
    cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", "POST", url]
    if token:
        cmd += ["-H", f"Authorization: Bearer {token}"]
    if data:
        cmd += ["-H", "Content-Type: application/json", "-d", data]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    lines = r.stdout.rsplit("\n", 1)
    body = lines[0] if len(lines) > 1 else ""
    status = int(lines[-1]) if lines[-1].isdigit() else 0
    try:
        parsed = json.loads(body)
    except Exception:
        parsed = None
    return status, parsed, body


def login(suffix):
    if suffix in _login_cache:
        return _login_cache[suffix]
    phone = f"{PHONE_PREFIX}{suffix}"
    _, data, _ = curl_post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = data["code"]
    status, data, _ = curl_post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if status != 200 or not data.get("token"):
        print(f"  [FAIL] login {phone}")
        sys.exit(1)
    result = (data["token"], data["user_id"])
    _login_cache[suffix] = result
    return result


def do_create(owner_suffix, member_suffixes, group_name):
    print(f"[1] 登录用户...")
    token, owner_uid = login(owner_suffix)
    print(f"  群主: {PHONE_PREFIX}{owner_suffix} (id={owner_uid})")

    member_ids = []
    for s in member_suffixes:
        _, uid = login(s)
        member_ids.append(uid)
        print(f"  成员: {PHONE_PREFIX}{s} (id={uid})")

    print(f"\n[2] 创建群聊: {group_name} ({len(member_ids)} 个成员)...")
    body = json.dumps({
        "type": "group",
        "name": group_name,
        "member_ids": member_ids,
    })
    status, data, raw = curl_post(f"{BASE}/conversations", body, token)

    if status != 200:
        err = data.get("error", raw) if data else raw
        print(f"  [FAIL] {status}: {err}")
        sys.exit(1)

    group_id = data["id"]
    avatar = data.get("avatar", "")
    print(f"  [OK] group_id={group_id}")
    print(f"       name={data.get('name')}")
    print(f"       avatar={avatar[:50]}{'...' if len(avatar) > 50 else ''}")
    print(f"\n[Done] 群聊已创建")


def do_join(user_suffix, group_id, message):
    print(f"[1] 登录用户...")
    token, uid = login(user_suffix)
    print(f"  用户: {PHONE_PREFIX}{user_suffix} (id={uid})")

    print(f"\n[2] 申请加入群聊 {group_id[:8]}...")
    body = json.dumps({"message": message} if message else {})
    status, data, raw = curl_post(f"{BASE}/conversations/{group_id}/join", body, token)

    if status != 200:
        err = data.get("error", raw) if data else raw
        print(f"  [FAIL] {status}: {err}")
        sys.exit(1)

    if data.get("auto_approved"):
        print(f"  [OK] 直接加入成功（无需审批）")
    else:
        owner = data.get("owner_id", "?")
        gname = data.get("group_name", "?")
        print(f"  [OK] 申请已发送，等待群主({owner})审批")
        print(f"       群名: {gname}")

    print(f"\n[Done]")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    is_join = "--join" in flags

    if is_join:
        if len(args) < 2:
            print("用法: python create_group.py --join <用户后缀> <群ID> [留言]")
            sys.exit(1)
        user_suffix = args[0].zfill(4)
        group_id = args[1]
        message = args[2] if len(args) > 2 else None
        do_join(user_suffix, group_id, message)
    else:
        if len(args) < 3:
            print("用法: python create_group.py <群主后缀> <成员后缀> <群名称>")
            print("  成员支持: 单个(0002) / 逗号(0002,0003) / 范围(0002-0005)")
            sys.exit(1)
        owner_suffix = args[0].zfill(4)
        member_suffixes = parse_suffixes(args[1])
        group_name = args[2]
        do_create(owner_suffix, member_suffixes, group_name)


if __name__ == "__main__":
    main()
