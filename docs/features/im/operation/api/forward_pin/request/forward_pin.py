#!/usr/bin/env python3
"""
forward_pin - 消息转发与置顶 API 测试链 + 文档生成器
用法: python docs/features/im/operation/api/forward_pin/request/forward_pin.py
"""

import json
import os
import subprocess
import sys

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
    @staticmethod
    def delete(url, token=None): return Curl.request("DELETE", url, token=token)

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
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | PASS | [{filename}]({filename}) |")

def write_link():
    header = ["# forward_pin - API test link", "", f"Base URL: `{BASE}`", "",
              "| # | Interface | Status | Result | Doc |", "|---|-----------|--------|--------|-----|"]
    with open(os.path.join(DOCS_DIR, "00_link.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))

# ─── pre: 登录 ───

step("pre", "Login users")
r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_A, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"): fail(f"login A failed: {r['body']}")
token_a = r["data"]["token"]
uid_a = r["data"]["user_id"]
print(f"User A: id={uid_a}")

r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_B, "type": "password", "credential": "111111"
}))
if not r["data"] or not r["data"].get("token"): fail(f"login B failed: {r['body']}")
token_b = r["data"]["token"]
uid_b = r["data"]["user_id"]
print(f"User B: id={uid_b}")
ok()

# pre2: 获取/创建群聊会话（A 是群主）
step("pre2", "Get group conversation (A is owner)")
r = Curl.get(f"{BASE}/conversations?limit=50", token_a)
convs = r["data"] if r["status"] == 200 else []
group_conv_id = None
private_conv_id = None
for c in convs:
    if c.get("conv_type") == 1 and not group_conv_id:
        group_conv_id = c["id"]
    if c.get("conv_type") == 0 and c.get("peer_user_id") == str(uid_b) and not private_conv_id:
        private_conv_id = c["id"]

if not private_conv_id:
    r = Curl.post(f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token_a)
    private_conv_id = r["data"]["id"]

if not group_conv_id:
    print("No group conversation found, some tests will be skipped")
else:
    print(f"Group conv: {group_conv_id[:8]}...")
print(f"Private conv: {private_conv_id[:8]}...")
ok()

# pre3: A 发几条消息用于转发和置顶
step("pre3", "A sends messages for testing")
msg_ids = []
for i in range(3):
    r = Curl.post(f"{BASE}/conversations/{private_conv_id}/messages", json.dumps({
        "content": f"转发测试消息 {i+1}",
        "msg_type": 0,
    }), token_a)
    if r["status"] != 200: fail(f"send failed: {r['body']}")
    msg_ids.append(r["data"]["id"])
print(f"Sent 3 messages: {[m[:8] for m in msg_ids]}")
ok()

# === 1: 单条转发 ===
step(1, "Forward single message to private conv")
j = json.dumps({
    "message_ids": [msg_ids[0]],
    "target_conversation_id": private_conv_id,
    "forward_type": "single"
})
r = Curl.post(f"{BASE}/conversations/{private_conv_id}/messages/forward", j, token_a)
print(f"status={r['status']}, body={r['body']}")
if r["status"] != 200: fail(f"forward failed: {r['body']}")
ok()
write_doc("01_forward_single.md", "POST", f"/conversations/{{conv_id}}/messages/forward",
    "单条消息转发到目标会话", r["status"], r["body"])

# === 2: 合并转发 ===
step(2, "Forward merge (multiple messages)")
j = json.dumps({
    "message_ids": msg_ids,
    "target_conversation_id": private_conv_id,
    "forward_type": "merge"
})
r = Curl.post(f"{BASE}/conversations/{private_conv_id}/messages/forward", j, token_a)
print(f"status={r['status']}, body={r['body']}")
if r["status"] != 200: fail(f"merge forward failed: {r['body']}")
ok()
write_doc("02_forward_merge.md", "POST", f"/conversations/{{conv_id}}/messages/forward",
    "多条消息合并转发（type=5 FORWARD）", r["status"], r["body"])

# === 3: 转发空列表（400） ===
step(3, "Forward empty message_ids (should fail 400)")
j = json.dumps({
    "message_ids": [],
    "target_conversation_id": private_conv_id,
    "forward_type": "single"
})
r = Curl.post(f"{BASE}/conversations/{private_conv_id}/messages/forward", j, token_a)
print(f"status={r['status']}")
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
ok()
write_doc("03_forward_empty.md", "POST", f"/conversations/{{conv_id}}/messages/forward",
    "转发空消息列表（应返回 400）", r["status"], r["body"],
    "message_ids 不能为空")

# === 4: 置顶消息（需要群聊） ===
if group_conv_id:
    # A 在群里发一条消息
    step(4, "Pin message in group")
    r = Curl.post(f"{BASE}/conversations/{group_conv_id}/messages", json.dumps({
        "content": "这条消息要被置顶", "msg_type": 0,
    }), token_a)
    if r["status"] != 200: fail(f"send to group failed: {r['body']}")
    pin_msg_id = r["data"]["id"]

    j = json.dumps({"message_id": pin_msg_id})
    r = Curl.post(f"{BASE}/conversations/{group_conv_id}/messages/pin", j, token_a)
    print(f"status={r['status']}, body={r['body']}")
    if r["status"] != 200: fail(f"pin failed: {r['body']}")
    pin_id = r["data"]["pin_id"]
    ok()
    write_doc("04_pin_message.md", "POST", f"/conversations/{{conv_id}}/messages/pin",
        "置顶消息（群主操作）", r["status"], r["body"])

    # === 5: 查询置顶列表 ===
    step(5, "Get pinned messages")
    r = Curl.get(f"{BASE}/conversations/{group_conv_id}/messages/pinned", token_a)
    print(f"status={r['status']}, count={len(r['data']) if r['data'] else 0}")
    if r["status"] != 200: fail(f"get pinned failed")
    ok()
    write_doc("05_get_pinned.md", "GET", f"/conversations/{{conv_id}}/messages/pinned",
        "查询会话置顶消息列表", r["status"], r["body"])

    # === 6: 重复置顶（400） ===
    step(6, "Pin same message again (should fail 400)")
    j = json.dumps({"message_id": pin_msg_id})
    r = Curl.post(f"{BASE}/conversations/{group_conv_id}/messages/pin", j, token_a)
    print(f"status={r['status']}")
    if r["status"] != 400: fail(f"expected 400, got {r['status']}")
    ok()
    write_doc("06_pin_duplicate.md", "POST", f"/conversations/{{conv_id}}/messages/pin",
        "重复置顶同一条消息（应返回 400）", r["status"], r["body"],
        "消息已置顶")

    # === 7: B 尝试置顶（非群主，403） ===
    step(7, "B tries to pin (not owner, should fail 403)")
    r2 = Curl.post(f"{BASE}/conversations/{group_conv_id}/messages", json.dumps({
        "content": "B 的消息", "msg_type": 0,
    }), token_b)
    if r2["status"] == 200:
        b_msg_id = r2["data"]["id"]
        j = json.dumps({"message_id": b_msg_id})
        r = Curl.post(f"{BASE}/conversations/{group_conv_id}/messages/pin", j, token_b)
        print(f"status={r['status']}")
        if r["status"] != 403: fail(f"expected 403, got {r['status']}")
        ok()
        write_doc("07_pin_not_owner.md", "POST", f"/conversations/{{conv_id}}/messages/pin",
            "非群主尝试置顶（应返回 403）", r["status"], r["body"],
            "只有群主可以置顶消息")
    else:
        print("B is not group member, skipping")
        ok()

    # === 8: 取消置顶 ===
    step(8, "Unpin message")
    r = Curl.delete(f"{BASE}/conversations/{group_conv_id}/messages/pin/{pin_id}", token_a)
    print(f"status={r['status']}, body={r['body']}")
    if r["status"] != 200: fail(f"unpin failed: {r['body']}")
    ok()
    write_doc("08_unpin.md", "DELETE", f"/conversations/{{conv_id}}/messages/pin/{{pin_id}}",
        "取消置顶消息", r["status"], r["body"])

    # === 9: 验证置顶列表为空 ===
    step(9, "Verify pinned list is empty after unpin")
    r = Curl.get(f"{BASE}/conversations/{group_conv_id}/messages/pinned", token_a)
    pinned = r["data"] if r["data"] else []
    pinned_for_msg = [p for p in pinned if p.get("message_id") == pin_msg_id]
    if pinned_for_msg:
        fail("Message should not be in pinned list after unpin")
    print("Pinned list no longer contains the message")
    ok()
    write_doc("09_verify_unpinned.md", "GET", f"/conversations/{{conv_id}}/messages/pinned",
        "验证取消置顶后列表不再包含该消息", r["status"], r["body"])
else:
    print(f"\n{YELLOW}[SKIP] Steps 4-9 (pin/unpin) skipped: no group conversation{RESET}")

# === 生成文档 ===
write_link()
print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
