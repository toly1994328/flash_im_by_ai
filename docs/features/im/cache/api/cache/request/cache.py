#!/usr/bin/env python3
"""
cache - after_seq API 测试链 + 文档生成器
用法: python docs/features/im/cache/api/cache/request/cache.py
"""

import json
import os
import subprocess
import sys
import urllib.parse

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"

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
            try: data = json.loads(body)
            except: pass
        curl_str = f'curl -s -X {method} "{url}"'
        if token: curl_str += f'\n  -H "Authorization: Bearer {token}"'
        if json_body:
            curl_str += f'\n  -H "Content-Type: application/json"'
            curl_str += f"\n  -d '{json_body}'"
        return {"status": status, "body": body, "data": data, "curl": curl_str}

    @staticmethod
    def get(url, token=None): return Curl.request("GET", url, token=token)
    @staticmethod
    def post(url, json_body=None, token=None): return Curl.request("POST", url, json_body, token)

# ─── 测试框架 ───

link_lines = []
passed = 0
total = 0
CYAN, GREEN, RED, YELLOW, RESET = "\033[36m", "\033[32m", "\033[31m", "\033[33m", "\033[0m"

def step(n, desc): print(f"\n{CYAN}========== [{n}] {desc} =========={RESET}")
def fail(msg): print(f"{RED}[FAIL] {msg}{RESET}"); sys.exit(1)
def ok():
    global passed; passed += 1; print(f"{GREEN}[PASS]{RESET}")

def write_doc(filename, method, path, desc, param_json, resp_status, resp_body, token, notes=None, params_desc=None):
    global total; total += 1
    lines = [f"# {method} {path}", "", desc, ""]
    if params_desc:
        lines += ["## Parameters", "", "| 参数 | 类型 | 必填 | 说明 |", "|------|------|------|------|"]
        for p in params_desc:
            lines.append(f"| {p['name']} | {p['type']} | {p['required']} | {p['desc']} |")
        lines += [""]
    if param_json: lines += ["```json", param_json, "```", ""]
    lines += [f"## Response `{resp_status}`", "", "```json", resp_body or "(empty body)", "```", ""]
    curl = f'curl -s -X {method} "{BASE}{path}"'
    if token: curl += f'\n  -H "Authorization: Bearer {token}"'
    if param_json:
        curl += f'\n  -H "Content-Type: application/json"'
        curl += f"\n  -d '{param_json}'"
    lines += ["## curl", "", "```bash", curl, "```"]
    if notes: lines += ["", f"> {notes}"]
    with open(os.path.join(DOCS_DIR, filename), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    icon = "PASS" if resp_status < 400 or notes else "FAIL"
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = ["# cache - API test link", "", f"Base URL: `{BASE}`", "",
              "| # | Interface | Status | Result | Doc |", "|---|-----------|--------|--------|-----|"]
    with open(os.path.join(DOCS_DIR, "00_link.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))

# ─── pre: 登录 ───

step("pre", "Login user A")
r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_A, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"): fail(f"login failed: {r['body']}")
token = r["data"]["token"]
uid = r["data"]["user_id"]
print(f"User A: id={uid}, token={token[:20]}...")
ok()

# 获取第一个会话
r_conv = Curl.get(f"{BASE}/conversations?limit=1", token)
if r_conv["status"] != 200 or not r_conv["data"]: fail("no conversations")
conv_id = r_conv["data"][0]["id"]
conv_name = r_conv["data"][0].get("name") or r_conv["data"][0].get("peer_nickname") or "?"
print(f"Conversation: {conv_name} ({conv_id[:8]}...)")

# === 1: 无参数（最新消息，行为不变） ===
step(1, "GET /messages - no params (latest)")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?limit=5", token)
if r["status"] != 200: fail(f"status {r['status']}")
msgs = r["data"]
print(f"results: {len(msgs)} messages")
if len(msgs) > 0:
    print(f"  first seq={msgs[0].get('seq')}, last seq={msgs[-1].get('seq')}")
ok()
write_doc("01_messages_latest.md", "GET", f"/conversations/{conv_id}/messages?limit=5",
    "查询最新消息（无 before_seq/after_seq 参数），行为不变。", None, r["status"], r["body"], token,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 50"},
    ])

# === 2: before_seq（向上翻页，行为不变） ===
step(2, "GET /messages - before_seq (page up)")
max_seq = msgs[-1]["seq"] if msgs else 999
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?before_seq={max_seq}&limit=3", token)
if r["status"] != 200: fail(f"status {r['status']}")
msgs2 = r["data"]
print(f"results: {len(msgs2)} messages (before_seq={max_seq})")
for m in msgs2[:3]:
    print(f"  seq={m['seq']}: {m['content'][:30]}")
# 验证所有 seq < max_seq
for m in msgs2:
    if m["seq"] >= max_seq: fail(f"seq {m['seq']} >= before_seq {max_seq}")
ok()
write_doc("02_messages_before_seq.md", "GET", f"/conversations/{conv_id}/messages?before_seq={max_seq}&limit=3",
    "向上翻页：返回 seq < before_seq 的消息，按 seq DESC 排序。行为不变。", None, r["status"], r["body"], token,
    params_desc=[
        {"name": "before_seq", "type": "int", "required": "否", "desc": "返回 seq 小于此值的消息"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数"},
    ])

# === 3: after_seq（增量同步，新功能） ===
step(3, "GET /messages - after_seq (incremental sync)")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?after_seq=0&limit=5", token)
if r["status"] != 200: fail(f"status {r['status']}")
msgs3 = r["data"]
print(f"results: {len(msgs3)} messages (after_seq=0)")
for m in msgs3[:5]:
    print(f"  seq={m['seq']}: {m['content'][:30]}")
# 验证所有 seq > 0 且按 ASC 排序
for i, m in enumerate(msgs3):
    if m["seq"] <= 0: fail(f"seq {m['seq']} <= after_seq 0")
    if i > 0 and m["seq"] <= msgs3[i-1]["seq"]: fail(f"not ASC: {msgs3[i-1]['seq']} -> {m['seq']}")
if len(msgs3) == 0: fail("expected at least 1 message for after_seq=0")
ok()
write_doc("03_messages_after_seq.md", "GET", f"/conversations/{conv_id}/messages?after_seq=0&limit=5",
    "增量同步（新功能）：返回 seq > after_seq 的消息，按 seq ASC 排序。", None, r["status"], r["body"], token,
    params_desc=[
        {"name": "after_seq", "type": "int", "required": "否", "desc": "返回 seq 大于此值的消息"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数"},
    ],
    notes="after_seq 和 before_seq 同时传时，after_seq 优先。排序为 ASC（从旧到新），和 before_seq 的 DESC 相反。")

# === 4: after_seq 中间值 ===
step(4, "GET /messages - after_seq with mid value")
mid_seq = msgs3[0]["seq"] if msgs3 else 0
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?after_seq={mid_seq}&limit=5", token)
if r["status"] != 200: fail(f"status {r['status']}")
msgs4 = r["data"]
print(f"results: {len(msgs4)} messages (after_seq={mid_seq})")
for m in msgs4:
    if m["seq"] <= mid_seq: fail(f"seq {m['seq']} <= after_seq {mid_seq}")
ok()
write_doc("04_messages_after_seq_mid.md", "GET", f"/conversations/{conv_id}/messages?after_seq={mid_seq}&limit=5",
    f"增量同步：after_seq={mid_seq}，只返回比这个 seq 更新的消息。", None, r["status"], r["body"], token)

# === 5: after_seq 优先于 before_seq ===
step(5, "GET /messages - after_seq takes priority over before_seq")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?after_seq=0&before_seq=999&limit=5", token)
if r["status"] != 200: fail(f"status {r['status']}")
msgs5 = r["data"]
print(f"results: {len(msgs5)} messages (after_seq=0, before_seq=999)")
# 应该和 after_seq=0 结果一样（after_seq 优先）
for i, m in enumerate(msgs5):
    if i > 0 and m["seq"] <= msgs5[i-1]["seq"]: fail(f"not ASC: after_seq should take priority")
ok()
write_doc("05_after_seq_priority.md", "GET", f"/conversations/{conv_id}/messages?after_seq=0&before_seq=999&limit=5",
    "同时传 after_seq 和 before_seq 时，after_seq 优先。", None, r["status"], r["body"], token,
    "验证 after_seq 优先级高于 before_seq。结果按 ASC 排序，说明走的是 after_seq 逻辑。")

# === 生成文档 ===
write_link()
print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
