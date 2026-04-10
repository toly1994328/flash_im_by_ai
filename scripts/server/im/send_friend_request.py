#!/usr/bin/env python3
"""
批量发送好友申请
用法:
  # A → B 单个申请
  python scripts/server/im/send_friend_request.py 0001 0002

  # A → B,C,D 批量申请（A 发给多人）
  python scripts/server/im/send_friend_request.py 0001 0002,0003,0004

  # 连续序号：A → 0002~0010
  python scripts/server/im/send_friend_request.py 0001 0002-0010

  # B,C,D → A 反向批量（多人发给 A）
  python scripts/server/im/send_friend_request.py 0002,0003,0004 0001

  # 连续序号反向：0002~0010 → A
  python scripts/server/im/send_friend_request.py 0002-0010 0001

  # 带留言
  python scripts/server/im/send_friend_request.py 0001 0002-0005 "你好"

  # 发送并自动接受
  python scripts/server/im/send_friend_request.py 0001 0002-0005 --accept

参数:
  第1个: 发送方（单个后缀 / 逗号分隔 / 连字符范围）
  第2个: 接收方（同上）
  第3个: 留言（可选）
  --accept: 发送后自动让接收方接受
"""

import json
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_PREFIX = "1380001"


def parse_suffixes(s):
    """解析后缀参数：支持单个、逗号分隔、连字符范围"""
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


# 缓存已登录的用户
_login_cache = {}

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


def send_one(from_suffix, to_suffix, message, auto_accept):
    token_from, uid_from = login(from_suffix)
    token_to, uid_to = login(to_suffix)

    body = {"to_user_id": uid_to}
    if message:
        body["message"] = message
    status, data, raw = curl_post(f"{BASE}/api/friends/requests", json.dumps(body), token_from)

    phone_from = f"{PHONE_PREFIX}{from_suffix}"
    phone_to = f"{PHONE_PREFIX}{to_suffix}"

    if status != 200:
        err = ""
        if data and "error" in data:
            err = data["error"]
        print(f"  {phone_from} → {phone_to}: FAIL ({status}) {err}")
        return

    request_id = data["data"]["id"]
    print(f"  {phone_from} → {phone_to}: OK (request_id={request_id[:8]}...)")

    if auto_accept:
        status, _, raw = curl_post(
            f"{BASE}/api/friends/requests/{request_id}/accept", None, token_to)
        if status == 200:
            print(f"    ↳ {phone_to} accepted")
        else:
            print(f"    ↳ accept FAIL ({status})")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    auto_accept = "--accept" in flags

    if len(args) < 2:
        print("用法: python send_friend_request.py <发送方> <接收方> [留言] [--accept]")
        print("  支持: 单个(0001) / 逗号(0001,0002) / 范围(0001-0005)")
        sys.exit(1)

    from_suffixes = parse_suffixes(args[0])
    to_suffixes = parse_suffixes(args[1])
    message = args[2] if len(args) > 2 else None

    # 登录所有涉及的用户
    all_suffixes = set(from_suffixes + to_suffixes)
    print(f"[1] 登录 {len(all_suffixes)} 个用户...")
    for s in sorted(all_suffixes):
        token, uid = login(s)
        print(f"  {PHONE_PREFIX}{s} → user_id={uid}")

    # 发送申请
    total = len(from_suffixes) * len(to_suffixes)
    print(f"\n[2] 发送 {total} 条好友申请...")
    for f in from_suffixes:
        for t in to_suffixes:
            if f == t:
                continue
            send_one(f, t, message, auto_accept)

    print(f"\n[Done]")


if __name__ == "__main__":
    main()
