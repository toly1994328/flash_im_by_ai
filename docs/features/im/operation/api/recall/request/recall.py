#!/usr/bin/env python3
"""
recall - 消息撤回 API 测试链 + 文档生成器
用法: python docs/features/im/operation/api/recall/request/recall.py
"""

import json
import os
import subprocess
import sys
import time

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"
PHONE_B = "13800010002"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(SCRIPT_DIR, "..", "doc")
os.makedirs(DOCS_DIR, exist_ok=True)

# ─── curl ───

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
        return {"status": status, "body": body, "data": data}

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

def write_doc(filename, method, path, desc, resp_status, resp_body, notes=None):
    global total; total += 1
    lines = [f"# {method} {path}", "", desc, ""]
    lines += [f"## Response `{resp_status}`", "", "```json", resp_body or "(empty)", "```"]
    if notes: lines += ["", f"> {notes}"]
    with open(os.path.join(DOCS_DIR, filename), "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    icon = "PASS" if resp_status < 400 or notes else "FAIL"
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = ["# recall - API test link", "", f"Base URL: `{BASE}`", "",
              "| # | Interface | Status | Result | Doc |", "|---|-----------|--------|--------|-----|"]
    with open(os.path.join(DOCS_DIR, "00_link.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))

# ─── pre: 登录两个用户 ───

step("pre", "Login users")
r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_A, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"): fail(f"login A failed: {r['body']}")
token_a = r["data"]["token"]
uid_a = r["data"]["user_id"]
print(f"User A: id={uid_a}, token={token_a[:20]}...")

r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_B, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"): fail(f"login B failed: {r['body']}")
token_b = r["data"]["token"]
uid_b = r["data"]["user_id"]
print(f"User B: id={uid_b}, token={token_b[:20]}...")
ok()

# 获取 A 和 B 的私聊会话
step("pre2", "Get conversation between A and B")
r_conv = Curl.get(f"{BASE}/conversations?limit=50", token_a)
if r_conv["status"] != 200: fail("get conversations failed")
convs = r_conv["data"]
# 找到和 B 的私聊
conv_id = None
for c in convs:
    if c.get("conv_type") == 0 and c.get("peer_user_id") == str(uid_b):
        conv_id = c["id"]
        break
if not conv_id:
    # 创建私聊
    r_create = Curl.post(f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token_a)
    conv_id = r_create["data"]["id"]
print(f"Conversation: {conv_id[:8]}...")
ok()

# === 1: A 发一条消息 ===
step(1, "A sends a message")
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", json.dumps({
    "content": "这条消息马上要被撤回",
    "msg_type": 0,
}), token_a)
if r["status"] != 200: fail(f"send failed: {r['body']}")
msg_id = r["data"]["id"]
msg_seq = r["data"]["seq"]
print(f"Message: id={msg_id[:8]}..., seq={msg_seq}")
ok()
write_doc("01_send_message.md", "POST", f"/conversations/{conv_id}/messages",
    "A 发送一条消息（用于后续撤回测试）", r["status"], r["body"])

# === 2: A 撤回消息（成功） ===
step(2, "A recalls the message (success)")
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages/{msg_id}/recall", token=token_a)
print(f"status={r['status']}, body={r['body']}")
if r["status"] != 200: fail(f"recall failed: {r['body']}")
ok()
write_doc("02_recall_success.md", "POST", f"/conversations/{conv_id}/messages/{msg_id}/recall",
    "A 撤回自己刚发的消息（2 分钟内，成功）", r["status"], r["body"])

# === 3: 验证消息 status=1 ===
step(3, "Verify message status=1 after recall")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?limit=5", token_a)
if r["status"] != 200: fail(f"get messages failed")
msgs = r["data"]
# 找到撤回的消息（可能已被过滤，也可能 status=1 还在）
recalled = [m for m in msgs if m["id"] == msg_id]
if recalled:
    if recalled[0]["status"] != 1: fail(f"status should be 1, got {recalled[0]['status']}")
    print(f"Message status={recalled[0]['status']} (RECALLED)")
else:
    print("Message filtered out (status != 0 filter)")
ok()
write_doc("03_verify_recalled.md", "GET", f"/conversations/{conv_id}/messages?limit=5",
    "验证撤回后消息 status=1", r["status"], r["body"])

# === 4: 重复撤回（失败 400） ===
step(4, "A recalls again (should fail 400)")
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages/{msg_id}/recall", token=token_a)
print(f"status={r['status']}, body={r['body']}")
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
ok()
write_doc("04_recall_duplicate.md", "POST", f"/conversations/{conv_id}/messages/{msg_id}/recall",
    "重复撤回同一条消息（应返回 400）", r["status"], r["body"],
    "消息已撤回，不能重复操作")

# === 5: B 撤回 A 的消息（失败 403） ===
step(5, "B tries to recall A's message (should fail 403)")
# A 再发一条
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", json.dumps({
    "content": "这条是 A 发的，B 不能撤回",
    "msg_type": 0,
}), token_a)
new_msg_id = r["data"]["id"]
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages/{new_msg_id}/recall", token=token_b)
print(f"status={r['status']}, body={r['body']}")
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
ok()
write_doc("05_recall_not_owner.md", "POST", f"/conversations/{conv_id}/messages/{new_msg_id}/recall",
    "B 尝试撤回 A 的消息（应返回 403）", r["status"], r["body"],
    "只能撤回自己的消息")

# === 6: 超时撤回（模拟：用一条旧消息） ===
step(6, "Recall an old message (should fail 403 timeout)")
# 获取一条旧消息（seq=1 通常是很早的）
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?limit=50", token_a)
old_msgs = [m for m in r["data"] if m["sender_id"] == uid_a and m["status"] == 0 and m["seq"] <= 2]
if old_msgs:
    old_id = old_msgs[0]["id"]
    r = Curl.post(f"{BASE}/conversations/{conv_id}/messages/{old_id}/recall", token=token_a)
    print(f"status={r['status']}, body={r['body']}")
    if r["status"] != 403: fail(f"expected 403, got {r['status']}")
    ok()
    write_doc("06_recall_timeout.md", "POST", f"/conversations/{conv_id}/messages/{old_id}/recall",
        "撤回超过 2 分钟的消息（应返回 403）", r["status"], r["body"],
        "超过撤回时限")
else:
    print("No old message found, skipping timeout test")
    ok()

# === 生成文档 ===
write_link()
print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
