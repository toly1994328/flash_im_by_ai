#!/usr/bin/env python3
"""
IM 种子数据：注册用户 + 设置资料 + 创建会话
用法: python scripts/server/im_seed/seed.py
前置: 1. python scripts/server/reset_db.py  2. 服务已启动
"""

import json
import os
import subprocess
import sys
import time

BASE = "http://127.0.0.1:9600"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SEED_FILE = os.path.join(SCRIPT_DIR, "seed-data.json")

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"


class Curl:
    @staticmethod
    def request(method, url, json_body=None, token=None):
        cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", method, url]
        if token:
            cmd += ["-H", f"Authorization: Bearer {token}"]
        if json_body:
            cmd += ["-H", "Content-Type: application/json", "-d", json_body]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        lines = r.stdout.rsplit("\n", 1)
        body = lines[0] if len(lines) > 1 else ""
        status = int(lines[-1]) if lines[-1].isdigit() else 0
        data = json.loads(body) if body.strip() else None
        return {"status": status, "body": body, "data": data}

    @staticmethod
    def get(url, token=None):
        return Curl.request("GET", url, token=token)

    @staticmethod
    def post(url, json_body=None, token=None):
        return Curl.request("POST", url, json_body, token)

    @staticmethod
    def put(url, json_body=None, token=None):
        return Curl.request("PUT", url, json_body, token)


def wait_for_server():
    print(f"{CYAN}[SEED] Waiting for server...{RESET}")
    for i in range(15):
        try:
            r = Curl.get(f"{BASE}/user/profile")
            if r["status"] > 0:
                return True
        except Exception:
            pass
        print(f"  waiting... ({i+1}/15)")
        time.sleep(2)
    print(f"{RED}[SEED] Server not ready{RESET}")
    return False


def register_user(phone, name, bio, color, password):
    """注册用户：SMS → 登录 → 设密码 → 更新资料，返回 (token, user_id)"""
    # SMS
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    if r["status"] != 200 or not r["data"]:
        return None, None
    code = r["data"].get("code", "")

    # Login
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if r["status"] != 200 or not r["data"]:
        return None, None
    token = r["data"]["token"]
    user_id = r["data"]["user_id"]

    # Set password (ignore if already set)
    Curl.post(f"{BASE}/user/password",
              json.dumps({"new_password": password}), token)

    # Update profile
    avatar = f"identicon:{name}:{color}"
    profile = json.dumps({"nickname": name, "signature": bio, "avatar": avatar},
                         ensure_ascii=False)
    Curl.put(f"{BASE}/user/profile", profile, token)

    return token, user_id


def main():
    if not wait_for_server():
        sys.exit(1)

    with open(SEED_FILE, "r", encoding="utf-8-sig") as f:
        seed = json.load(f)

    phone_prefix = seed["phone_prefix"]
    password = seed["default_password"]
    primary_idx = seed["primary_user_idx"]
    users = seed["users"]

    print(f"{CYAN}[SEED] Registering {len(users)} users...{RESET}")

    tokens = {}
    user_ids = {}

    for u in users:
        phone = f"{phone_prefix}{u['phone_suffix']}"
        token, uid = register_user(phone, u["name"], u["bio"], u["color"], password)
        if token:
            tokens[u["idx"]] = token
            user_ids[u["idx"]] = uid
            print(f"  [{u['idx']:>2}] {u['name']} ({phone}) -> user_id={uid}")
        else:
            print(f"  {RED}[{u['idx']:>2}] FAILED: {u['name']} ({phone}){RESET}")

    # 为主用户建立好友关系和会话
    primary_token = tokens.get(primary_idx)
    primary_name = users[primary_idx - 1]["name"]
    if not primary_token:
        print(f"{RED}[SEED] Primary user not found{RESET}")
        sys.exit(1)

    # 朱红和所有人成为好友
    friend_count = 0
    for u in users:
        if u["idx"] == primary_idx:
            continue
        peer_id = user_ids.get(u["idx"])
        peer_token = tokens.get(u["idx"])
        if not peer_id or not peer_token:
            continue
        # 发送好友申请
        r = Curl.post(f"{BASE}/api/friends/requests",
                      json.dumps({"to_user_id": peer_id}), primary_token)
        if r["status"] == 200:
            req_id = r["data"]["data"]["id"]
            # 对方接受
            r2 = Curl.post(f"{BASE}/api/friends/requests/{req_id}/accept", None, peer_token)
            if r2["status"] == 200:
                friend_count += 1
    print(f"  {friend_count} friendships created")

    # 为主用户创建会话
    print(f"\n{CYAN}[SEED] Creating conversations for {primary_name}...{RESET}")
    conv_count = 0

    for u in users:
        if u["idx"] == primary_idx:
            continue
        peer_id = user_ids.get(u["idx"])
        if not peer_id:
            continue
        r = Curl.post(f"{BASE}/conversations",
                      json.dumps({"peer_user_id": peer_id}), primary_token)
        if r["status"] == 200:
            conv_count += 1
        else:
            print(f"  {RED}FAILED: conversation with {u['name']}{RESET}")

    # 创建群聊
    groups = seed.get("groups", [])
    group_count = 0
    msg_count = 0
    if groups:
        print(f"\n{CYAN}[SEED] Creating {len(groups)} groups...{RESET}")
        for g in groups:
            owner_idx = g["owner"]
            owner_token = tokens.get(owner_idx)
            if not owner_token:
                print(f"  {RED}SKIP: {g['name']} (owner idx={owner_idx} not found){RESET}")
                continue
            member_ids = [user_ids[m] for m in g["members"] if m in user_ids]
            if len(member_ids) < 2:
                print(f"  {RED}SKIP: {g['name']} (not enough members){RESET}")
                continue
            r = Curl.post(f"{BASE}/groups", json.dumps({
                "name": g["name"],
                "member_ids": member_ids,
            }, ensure_ascii=False), owner_token)
            if r["status"] == 200:
                group_count += 1
                gid = r["data"]["id"]
                print(f"  [OK] {g['name']} ({len(member_ids)+1}人) id={gid[:8]}...")

                # 发送群聊消息
                for m in g.get("messages", []):
                    from_idx = m["from"]
                    from_token = tokens.get(from_idx)
                    if not from_token:
                        continue
                    mr = Curl.post(
                        f"{BASE}/conversations/{gid}/messages",
                        json.dumps({"content": m["text"]}, ensure_ascii=False),
                        from_token,
                    )
                    if mr["status"] == 200:
                        msg_count += 1
                    else:
                        from_name = next((u["name"] for u in users if u["idx"] == from_idx), "?")
                        print(f"    {RED}MSG FAIL: {from_name} → {m['text'][:20]} ({mr['status']}){RESET}")
            else:
                err = r["data"].get("error", "") if r["data"] else ""
                print(f"  {RED}FAIL: {g['name']} ({r['status']}) {err}{RESET}")

    primary_phone = f"{phone_prefix}{users[primary_idx - 1]['phone_suffix']}"
    print(f"\n{GREEN}[SEED] Done. {len(tokens)} users, {conv_count} conversations, {group_count} groups, {msg_count} messages.{RESET}")
    print(f"[SEED] Login: phone={primary_phone} password={password}")


if __name__ == "__main__":
    main()
