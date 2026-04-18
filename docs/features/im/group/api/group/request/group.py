#!/usr/bin/env python3
"""
group v0.0.1 - API 测试链 + 文档生成器
用法: python docs/features/im/group/api/group/request/group.py

前置:
  1. python scripts/server/reset_db.py
  2. python scripts/server/start.py
  3. python scripts/server/im_seed/seed.py
  4. python scripts/server/im/send_friend_request.py 0001 0002-0004 --accept
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_PREFIX = "1380001"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(SCRIPT_DIR, "..", "doc")
os.makedirs(DOCS_DIR, exist_ok=True)

# ─── curl 处理器 ───

class Curl:
    @staticmethod
    def request(method, url, json_body=None, token=None):
        cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", method, url]
        if token:
            cmd += ["-H", f"Authorization: Bearer {token}"]
        if json_body:
            cmd += ["-H", "Content-Type: application/json", "-d", json_body]

        result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        lines = result.stdout.rsplit("\n", 1)
        body = lines[0] if len(lines) > 1 else ""
        status = int(lines[-1]) if lines[-1].isdigit() else 0
        data = None
        if body.strip():
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                pass

        curl_str = f'curl -s -X {method} "{url}"'
        if token:
            curl_str += f'\n  -H "Authorization: Bearer {token}"'
        if json_body:
            curl_str += f'\n  -H "Content-Type: application/json"'
            curl_str += f"\n  -d '{json_body}'"

        return {"status": status, "body": body, "data": data, "curl": curl_str}

    @staticmethod
    def get(url, token=None):
        return Curl.request("GET", url, token=token)

    @staticmethod
    def post(url, json_body=None, token=None):
        return Curl.request("POST", url, json_body, token)


# ─── 测试框架 ───

link_lines = []
passed = 0
total = 0

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"

def step(n, desc):
    print(f"\n{CYAN}========== [{n}] {desc} =========={RESET}")

def fail(msg):
    print(f"{RED}[FAIL] {msg}{RESET}")
    sys.exit(1)

def ok():
    global passed
    passed += 1
    print(f"{GREEN}[PASS]{RESET}")

def write_doc(filename, method, path, desc, param_json, resp_status, resp_body, token, notes=None, params_desc=None):
    global total
    total += 1
    lines = [f"# {method} {path}", "", desc, ""]
    if params_desc:
        lines += ["## Parameters", ""]
        lines += ["| 参数 | 类型 | 必填 | 说明 |"]
        lines += ["|------|------|------|------|"]
        for p in params_desc:
            lines.append(f"| {p['name']} | {p['type']} | {p['required']} | {p['desc']} |")
        lines += [""]
    if param_json:
        lines += ["```json", param_json, "```", ""]
    lines += [f"## Response `{resp_status}`", "", "```json", resp_body or "(empty body)", "```", ""]
    curl = f'curl -s -X {method} "{BASE}{path}"'
    if token:
        curl += f'\n  -H "Authorization: Bearer {token}"'
    if param_json:
        curl += f'\n  -H "Content-Type: application/json"'
        curl += f"\n  -d '{param_json}'"
    lines += ["## curl", "", "```bash", curl, "```"]
    if notes:
        lines += ["", f"> {notes}"]

    filepath = os.path.join(DOCS_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    icon = "PASS" if resp_status < 400 or notes else "FAIL"
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = [
        "# group v0.0.1 - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


def login(suffix):
    phone = f"{PHONE_PREFIX}{suffix}"
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]["token"], r["data"]["user_id"]


# ─── pre: 登录测试用户 ───

step("pre", "Login test users (0001~0004)")
t1, uid1 = login("0001")  # 朱红 — 群主
t2, uid2 = login("0002")  # 橘橙
t3, uid3 = login("0003")  # 藤黄
t4, uid4 = login("0004")  # 碧螺春绿
print(f"朱红={uid1}, 橘橙={uid2}, 藤黄={uid3}, 碧螺春绿={uid4}")
ok()

# === 1: 创建群聊 ===
step(1, "POST /groups - create group")
j = json.dumps({"name": "测试群聊", "member_ids": [uid2, uid3, uid4]})
r = Curl.post(f"{BASE}/groups", j, t1)
if r["status"] != 200: fail(f"create group failed: {r['status']}")
group_id = r["data"]["id"]
print(f"group_id: {group_id}, name: {r['data']['name']}, avatar: {r['data'].get('avatar', '')[:30]}...")
assert r["data"]["conv_type"] == 1
assert r["data"]["name"] == "测试群聊"
assert str(r["data"].get("avatar", "")).startswith("grid:")
assert str(r["data"].get("owner_id")) == str(uid1)
ok()
write_doc("01_create_group.md", "POST", "/groups",
    "创建群聊。群主自动加入，自动生成宫格头像，自动初始化 group_info，自动发送系统消息。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "name", "type": "string", "required": "是", "desc": "群名称"},
        {"name": "member_ids", "type": "int[]", "required": "是", "desc": "成员 ID 列表（不含群主，至少 2 人）"},
    ])

# === 2: 群名为空 → 400 ===
step(2, "POST /groups - empty group name")
j2 = json.dumps({"name": "", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/groups", j2, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("02_create_group_empty_name.md", "POST", "/groups",
    "群名为空时返回 400。", j2, r["status"], r["body"] or "(empty body)", t1,
    "群名 trim 后为空即拒绝。")

# === 3: 成员不足 → 400 ===
step(3, "POST /groups - not enough members")
j3 = json.dumps({"name": "太少了", "member_ids": [uid2]})
r = Curl.post(f"{BASE}/groups", j3, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("03_create_group_too_few.md", "POST", "/groups",
    "成员不足时返回 400（加上群主至少 3 人）。", j3, r["status"], r["body"] or "(empty body)", t1,
    "member_ids 去重后加群主不足 3 人时拒绝。")

# === 4: 单聊创建不受影响 ===
step(4, "POST /conversations - private still works")
j4 = json.dumps({"peer_user_id": uid4})
r = Curl.post(f"{BASE}/conversations", j4, t1)
if r["status"] != 200: fail(f"private create failed: {r['status']}")
print(f"conv_type: {r['data']['conv_type']}")
assert r["data"]["conv_type"] == 0
ok()
write_doc("04_create_private.md", "POST", "/conversations",
    "单聊创建走独立的 POST /conversations，不受群聊影响。", j4, r["status"], r["body"], t1,
    params_desc=[
        {"name": "peer_user_id", "type": "int", "required": "是", "desc": "对方用户 ID"},
    ])

# === 5: 会话列表包含群聊 ===
step(5, "GET /conversations - list includes group")
r = Curl.get(f"{BASE}/conversations", t1)
if r["status"] != 200: fail(f"list failed: {r['status']}")
group_convs = [c for c in r["data"] if c.get("conv_type") == 1]
print(f"total: {len(r['data'])}, groups: {len(group_convs)}")
assert len(group_convs) > 0
g = group_convs[0]
assert g.get("name") is not None
assert g.get("avatar") is not None
ok()
write_doc("05_list_with_group.md", "GET", "/conversations",
    "会话列表包含群聊，群聊显示群名和宫格头像。", None, r["status"], r["body"], t1,
    "群聊的 name 来自 conversations.name，avatar 来自 conversations.avatar（grid: 格式）。")

# === 6: type 过滤只返回群聊 ===
step(6, "GET /conversations?type=1 - filter groups only")
r = Curl.get(f"{BASE}/conversations?type=1", t1)
if r["status"] != 200: fail(f"filter failed: {r['status']}")
print(f"groups only: {len(r['data'])}")
for c in r["data"]:
    assert c["conv_type"] == 1, f"expected type=1, got {c['conv_type']}"
ok()
write_doc("06_list_type_filter.md", "GET", "/conversations?type=1",
    "type=1 只返回群聊会话，不含单聊。", None, r["status"], r["body"], t1,
    params_desc=[
        {"name": "type", "type": "int", "required": "否", "desc": "会话类型过滤（0=单聊, 1=群聊），不传返回全部"},
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 7: 群成员看到群聊 ===
step(7, "GET /conversations - member sees group")
r = Curl.get(f"{BASE}/conversations?type=1", t2)
if r["status"] != 200: fail(f"list failed: {r['status']}")
print(f"橘橙的群聊: {len(r['data'])}")
assert len(r["data"]) > 0
ok()
write_doc("07_member_sees_group.md", "GET", "/conversations?type=1",
    "群成员（非群主）也能在会话列表中看到群聊。", None, r["status"], r["body"], t2,
    "验证 conversation_members 正确插入了所有成员。")

# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs → {os.path.relpath(DOCS_DIR)}{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
