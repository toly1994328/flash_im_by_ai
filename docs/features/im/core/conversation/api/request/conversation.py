#!/usr/bin/env python3
"""
conversation - API 测试链 + 文档生成器
用法: python docs/features/im/core/conversation/api/request/conversation.py
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"
PHONE_B = "13800010002"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(SCRIPT_DIR, "..", "docs", "conversation")
os.makedirs(DOCS_DIR, exist_ok=True)

# ─── curl 处理器 ───

class Curl:
    """封装 curl 命令，返回状态码、响应体、完整 curl 命令字符串"""

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
        data = json.loads(body) if body.strip() else None

        # 构造可复制的 curl 命令
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
    def post(url, json_body, token=None):
        return Curl.request("POST", url, json_body, token)

    @staticmethod
    def delete(url, token=None):
        return Curl.request("DELETE", url, token=token)


# ─── 测试框架 ───

link_lines = []
passed = 0
total = 0

# ANSI 颜色
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
    # curl
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
        "# conversation - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 登录两个用户 ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]

step("pre", "Login user A and user B")
user_a = login(PHONE_A)
token_a, uid_a = user_a["token"], user_a["user_id"]
print(f"User A: id={uid_a}")

user_b = login(PHONE_B)
token_b, uid_b = user_b["token"], user_b["user_id"]
print(f"User B: id={uid_b}")
ok()


# === 1: 创建私聊 ===
step(1, "POST /conversations - create private")
j = json.dumps({"peer_user_id": uid_b})
r = Curl.post(f"{BASE}/conversations", j, token_a)
if r["status"] != 200: fail(f"create failed: {r['status']}")
conv_id = r["data"]["id"]
print(f"conversation_id: {conv_id}, type: {r['data'].get('conv_type')}")
ok()
write_doc("01_create_private.md", "POST", "/conversations",
    "创建私聊会话。幂等性：已有则返回已有的。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "peer_user_id", "type": "int", "required": "是", "desc": "对方用户 ID"},
    ])

# === 2: 幂等创建 ===
step(2, "POST /conversations - idempotent")
r = Curl.post(f"{BASE}/conversations", j, token_a)
if r["data"]["id"] != conv_id: fail(f"expected {conv_id}, got {r['data']['id']}")
print(f"same id: {r['data']['id']}")
ok()
write_doc("02_create_idempotent.md", "POST", "/conversations",
    "重复创建同一私聊，返回已有会话（幂等）。", j, r["status"], r["body"], token_a,
    "返回相同的会话，不会重复创建。",
    params_desc=[
        {"name": "peer_user_id", "type": "int", "required": "是", "desc": "对方用户 ID"},
    ])

# === 3: 对方不存在 ===
step(3, "POST /conversations - peer not found")
j3 = json.dumps({"peer_user_id": 999999})
r = Curl.post(f"{BASE}/conversations", j3, token_a)
if r["status"] != 404: fail(f"expected 404, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("03_create_peer_not_found.md", "POST", "/conversations",
    "创建会话时对方用户不存在。", j3, r["status"], r["body"] or "(empty body)", token_a,
    "peer_user_id 不存在时返回 404。",
    params_desc=[
        {"name": "peer_user_id", "type": "int", "required": "是", "desc": "对方用户 ID（不存在）"},
    ])

# === 4: 查询列表 ===
step(4, "GET /conversations - list")
r = Curl.get(f"{BASE}/conversations", token_a)
count = len(r["data"]) if r["data"] else 0
if count < 1: fail(f"expected >= 1, got {count}")
print(f"total: {count}")
ok()
write_doc("04_list.md", "GET", "/conversations",
    "查询当前用户的会话列表，按最后消息时间倒序。", None, r["status"], r["body"], token_a)

# === 5: 分页 ===
step(5, "GET /conversations?limit=1&offset=0 - pagination")
r = Curl.get(f"{BASE}/conversations?limit=1&offset=0", token_a)
if len(r["data"]) != 1: fail(f"expected 1, got {len(r['data'])}")
print(f"page size: {len(r['data'])}")
ok()
write_doc("05_list_paginated.md", "GET", "/conversations?limit=1&offset=0",
    "分页查询会话列表。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 6: 超出范围 ===
step(6, "GET /conversations?limit=20&offset=100 - empty")
r = Curl.get(f"{BASE}/conversations?limit=20&offset=100", token_a)
if len(r["data"]) != 0: fail(f"expected 0, got {len(r['data'])}")
print("empty list")
ok()
write_doc("06_list_empty.md", "GET", "/conversations?limit=20&offset=100",
    "偏移量超出总数时返回空数组。", None, r["status"], r["body"], token_a)

# === 7: 删除会话 ===
step(7, f"DELETE /conversations/{conv_id}")
r = Curl.delete(f"{BASE}/conversations/{conv_id}", token_a)
if r["status"] != 200: fail(f"delete failed: {r['status']}")
print(f"deleted: {conv_id}")
ok()
write_doc("07_delete.md", "DELETE", f"/conversations/{conv_id}",
    "软删除会话，仅影响当前用户。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "id", "type": "UUID", "required": "是", "desc": "会话 ID（路径参数）"},
    ])

# === 8: 删除后列表 ===
step(8, "GET /conversations - after delete")
r = Curl.get(f"{BASE}/conversations", token_a)
ids = [c["id"] for c in r["data"]] if r["data"] else []
if conv_id in ids: fail("deleted conversation still in list")
print(f"conversation {conv_id} not in list")
ok()
write_doc("08_list_after_delete.md", "GET", "/conversations",
    "删除后查询列表，已删除的会话不再出现。", None, r["status"], r["body"], token_a,
    "软删除的会话从列表中排除。")

# === 9: 对方仍可见 ===
step(9, "GET /conversations - user B still sees it")
r = Curl.get(f"{BASE}/conversations", token_b)
ids = [c["id"] for c in r["data"]] if r["data"] else []
if conv_id not in ids: fail("user B should still see the conversation")
print(f"user B still has {conv_id}")
ok()
write_doc("09_other_user_sees.md", "GET", "/conversations",
    "对方仍能看到被删除的会话。", None, r["status"], r["body"], token_b,
    "软删除仅影响操作者，对方不受影响。")

# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
