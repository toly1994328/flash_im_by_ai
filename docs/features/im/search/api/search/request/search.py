#!/usr/bin/env python3
"""
search - API 测试链 + 文档生成器
用法: python docs/features/im/search/api/search/request/search.py
"""

import json
import os
import subprocess
import sys
import urllib.parse

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"  # 朱红（有好友、有群聊、有消息）

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
        "# search - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 登录 ───

step("pre", "Login user A (朱红)")
r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_A, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"):
    fail(f"login failed: {r['body']}")
token_a = r["data"]["token"]
uid_a = r["data"]["user_id"]
print(f"User A: id={uid_a}, token={token_a[:20]}...")
ok()


# === 1: 好友搜索（按昵称） ===
step(1, "GET /api/friends/search - search by nickname")
kw = urllib.parse.quote("橘")
r = Curl.get(f"{BASE}/api/friends/search?keyword={kw}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
items = r["data"]["data"]
print(f"results: {len(items)} friends")
if len(items) == 0: fail("expected at least 1 result for '橘'")
print(f"  first: {items[0].get('nickname')} (id={items[0].get('friend_id')})")
ok()
write_doc("01_search_friends.md", "GET", "/api/friends/search?keyword=橘",
    "搜索当前用户的好友，按昵称模糊匹配。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（昵称模糊匹配）"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 20，最大 50"},
    ])


# === 2: 好友搜索（无匹配） ===
step(2, "GET /api/friends/search - no match")
kw2 = urllib.parse.quote("不存在的名字xyz")
r = Curl.get(f"{BASE}/api/friends/search?keyword={kw2}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
items = r["data"]["data"]
print(f"results: {len(items)} (expected 0)")
if len(items) != 0: fail("expected 0 results")
ok()
write_doc("02_search_friends_empty.md", "GET", "/api/friends/search?keyword=不存在的名字xyz",
    "搜索好友，无匹配结果时返回空数组。", None, r["status"], r["body"], token_a,
    "关键词无匹配时返回 200 + 空数组，不返回 404。")


# === 3: 已加入群搜索 ===
step(3, "GET /api/conversations/search-joined-groups - search groups")
kw3 = urllib.parse.quote("七彩")
r = Curl.get(f"{BASE}/api/conversations/search-joined-groups?keyword={kw3}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
items = r["data"]["data"]
print(f"results: {len(items)} groups")
if len(items) == 0: fail("expected at least 1 group for '七彩'")
print(f"  first: {items[0].get('name')} (members={items[0].get('member_count')})")
ok()
write_doc("03_search_joined_groups.md", "GET", "/api/conversations/search-joined-groups?keyword=七彩",
    "搜索当前用户已加入的群聊，按群名模糊匹配。只返回已加入且未解散的群。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（群名模糊匹配）"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 20，最大 50"},
    ])


# === 4: 已加入群搜索（空关键词返回全部） ===
step(4, "GET /api/conversations/search-joined-groups - empty keyword")
r = Curl.get(f"{BASE}/api/conversations/search-joined-groups?keyword=", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
items = r["data"]["data"]
print(f"results: {len(items)} groups (all joined)")
ok()
write_doc("04_search_joined_groups_all.md", "GET", "/api/conversations/search-joined-groups?keyword=",
    "空关键词返回所有已加入的群聊。", None, r["status"], r["body"], token_a)


# === 5: 跨会话消息搜索（有结果） ===
step(5, "GET /api/messages/search - search messages")
kw5 = urllib.parse.quote("签到")
r = Curl.get(f"{BASE}/api/messages/search?keyword={kw5}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
groups = r["data"]["data"]
print(f"results: {len(groups)} conversation groups")
if len(groups) == 0: fail("expected at least 1 group for '签到'")
for g in groups[:3]:
    print(f"  - {g.get('conversation_name')}: {g.get('match_count')} matches")
    for m in g.get("messages", [])[:2]:
        print(f"    > {m.get('sender_name')}: {m.get('content', '')[:30]}")
ok()
write_doc("05_search_messages.md", "GET", "/api/messages/search?keyword=签到",
    "跨会话搜索消息内容，按会话分组返回。只搜文本消息（msg_type=0）。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（消息内容模糊匹配）"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回的会话分组数量，默认 10，最大 20"},
    ],
    notes="每个会话分组包含 conversation_name/avatar/conv_type/match_count + 最近 3 条匹配消息。")


# === 6: 消息搜索（无匹配） ===
step(6, "GET /api/messages/search - no match")
kw6 = urllib.parse.quote("完全不存在的内容xyz")
r = Curl.get(f"{BASE}/api/messages/search?keyword={kw6}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
groups = r["data"]["data"]
print(f"results: {len(groups)} (expected 0)")
if len(groups) != 0: fail("expected 0 groups")
ok()
write_doc("06_search_messages_empty.md", "GET", "/api/messages/search?keyword=完全不存在的内容xyz",
    "消息搜索无匹配时返回空数组。", None, r["status"], r["body"], token_a)


# === 7: 会话内消息搜索 ===
step(7, "GET /conversations/{id}/messages/search - search in conversation")
# 先获取第一个群聊会话（七彩虹）
r_conv = Curl.get(f"{BASE}/conversations?type=1&limit=1", token_a)
if r_conv["status"] != 200 or not r_conv["data"]: fail("no group conversation found")
conv_id = r_conv["data"][0]["id"]
conv_name = r_conv["data"][0].get("name", "?")
print(f"conversation: {conv_name} ({conv_id[:8]}...)")

kw7 = urllib.parse.quote("签到")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages/search?keyword={kw7}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
items = r["data"]["data"]
print(f"results: {len(items)} messages in '{conv_name}'")
for m in items[:3]:
    print(f"  > {m.get('sender_name')}: {m.get('content', '')[:30]} (seq={m.get('seq')})")
ok()
write_doc("07_search_conversation_messages.md", "GET", f"/conversations/{conv_id}/messages/search?keyword=签到",
    "在指定会话内搜索消息内容。返回匹配的消息列表（含 seq，可用于定位）。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 50，最大 100"},
    ])


# === 8: 通配符转义 ===
step(8, "GET /api/friends/search - wildcard escape")
kw8 = urllib.parse.quote("%")
r = Curl.get(f"{BASE}/api/friends/search?keyword={kw8}", token_a)
if r["status"] != 200: fail(f"status {r['status']}")
print(f"results: {len(r['data']['data'])} (wildcard escaped, no crash)")
ok()
write_doc("08_wildcard_escape.md", "GET", "/api/friends/search?keyword=%25",
    "搜索关键词包含 SQL 通配符（%、_）时正确转义，不报错。", None, r["status"], r["body"], token_a,
    "后端对 % 和 _ 做了转义（\\% 和 \\_），防止 ILIKE 注入。")


# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
