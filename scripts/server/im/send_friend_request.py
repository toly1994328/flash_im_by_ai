#!/usr/bin/env python3
"""
以用户 X 向用户 Y 发送好友申请
用法:
  python scripts/server/im/send_friend_request.py 0001 0002
  python scripts/server/im/send_friend_request.py 0001 0002 "你好，加个好友"
  python scripts/server/im/send_friend_request.py 0001 0002 --accept

参数:
  第1个: X 的手机后缀（如 0001 = 13800010001 = 朱红）
  第2个: Y 的手机后缀（如 0002 = 13800010002 = 橘橙）
  第3个: 留言（可选）
  --accept: 发送后自动让 Y 接受
"""

import json
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_PREFIX = "1380001"

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

def login(phone):
    _, data, _ = curl_post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = data["code"]
    status, data, _ = curl_post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if status != 200 or not data.get("token"):
        print(f"[FAIL] login failed for {phone}")
        sys.exit(1)
    return data["token"], data["user_id"]

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = [a for a in sys.argv[1:] if a.startswith("--")]
    auto_accept = "--accept" in flags

    if len(args) < 2:
        print("用法: python send_request.py <X后缀> <Y后缀> [留言] [--accept]")
        sys.exit(1)

    phone_x = f"{PHONE_PREFIX}{args[0]}"
    phone_y = f"{PHONE_PREFIX}{args[1]}"
    message = args[2] if len(args) > 2 else None

    print(f"[1] 登录 X ({phone_x})...")
    token_x, uid_x = login(phone_x)
    print(f"    user_id={uid_x}")

    print(f"[2] 登录 Y ({phone_y})...")
    token_y, uid_y = login(phone_y)
    print(f"    user_id={uid_y}")

    print(f"[3] X → Y 发送好友申请...")
    body = {"to_user_id": uid_y}
    if message:
        body["message"] = message
    status, data, raw = curl_post(f"{BASE}/api/friends/requests", json.dumps(body), token_x)
    if status != 200:
        print(f"    [FAIL] status={status} body={raw}")
        sys.exit(1)
    request_id = data["data"]["id"]
    print(f"    [OK] request_id={request_id}")

    if auto_accept:
        print(f"[4] Y 接受申请...")
        status, _, raw = curl_post(f"{BASE}/api/friends/requests/{request_id}/accept", None, token_y)
        if status != 200:
            print(f"    [FAIL] status={status} body={raw}")
            sys.exit(1)
        print(f"    [OK] 已成为好友")

if __name__ == "__main__":
    main()
