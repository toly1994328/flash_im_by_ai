#!/usr/bin/env python3
"""
conversation - 会话操作 API 测试链 + 文档生成器 (v0.0.5: pin/mute/unread toggle)
用法: python docs/features/im/operation/v0.0.5/api/conversation/request/conversation.py
"""

import json
import os
import subprocess
import sys
import uuid as uuid_mod

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"
PHONE_B = "13800010002"
PHONE_C = "13800010003"

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
    icon = "PASS" if resp_status < 400 or notes else "FAIL"
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = ["# conversation - API test link (v0.0.5)", "", f"Base URL: `{BASE}`", "",
              "| # | Interface | Status | Result | Doc |", "|---|-----------|--------|--------|-----|"]
    with open(os.path.join(DOCS_DIR, "00_link.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))

# ─── pre: 登录三个用户 ───

def login(phone):
    """密码登录"""
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "password", "credential": "111111"
    }))
    if not r["data"] or not r["data"].get("token"):
        fail(f"login failed for {phone}: {r['body']}")
    return r["data"]

step("pre", "Login users A, B, C")
user_a = login(PHONE_A)
token_a, uid_a = user_a["token"], user_a["user_id"]
print(f"User A: id={uid_a}")

user_b = login(PHONE_B)
token_b, uid_b = user_b["token"], user_b["user_id"]
print(f"User B: id={uid_b}")

user_c = login(PHONE_C)
token_c, uid_c = user_c["token"], user_c["user_id"]
print(f"User C: id={uid_c}")
ok()

# pre2: 创建 A-B 私聊会话
step("pre2", "Create conversation between A and B")
r = Curl.post(f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token_a)
if r["status"] != 200: fail(f"create conversation failed: {r['body']}")
conv_id = r["data"]["id"]
print(f"conversation_id: {conv_id}")
ok()

# === 1: 获取会话列表 ===
step(1, "GET /conversations - verify conversation exists")
r = Curl.get(f"{BASE}/conversations?limit=100", token_a)
if r["status"] != 200: fail(f"list failed: {r['status']}")
convs = r["data"]
found = any(str(c.get("id")) == conv_id for c in convs)
if not found: fail("conversation not found in list")
conv_a = next(c for c in convs if str(c["id"]) == conv_id)
print(f"is_pinned={conv_a.get('is_pinned')}, is_muted={conv_a.get('is_muted')}, unread={conv_a.get('unread_count')}")
ok()
write_doc("01_list_conversations.md", "GET", "/conversations",
    "获取当前用户的会话列表，包含 is_pinned、is_muted、unread_count 等状态。",
    r["status"], r["body"])

# === 2: Toggle 置顶 ON ===
step(2, f"POST /conversations/{conv_id}/pin - toggle pin ON")
r = Curl.post(f"{BASE}/conversations/{conv_id}/pin", None, token_a)
if r["status"] != 200: fail(f"toggle pin failed: {r['status']}")
is_pinned = r["data"]["is_pinned"]
print(f"is_pinned: {is_pinned}")
if not is_pinned: fail("expected is_pinned=true after first toggle")
ok()
write_doc("02_toggle_pin_on.md", "POST", f"/conversations/{conv_id}/pin",
    "Toggle 置顶状态（首次调用，取消置顶 → 置顶）。",
    r["status"], r["body"],
    "每次调用翻转 is_pinned，置顶时写入 pinned_at 时间戳。")

# === 3: Toggle 置顶 OFF ===
step(3, f"POST /conversations/{conv_id}/pin - toggle pin OFF")
r = Curl.post(f"{BASE}/conversations/{conv_id}/pin", None, token_a)
if r["status"] != 200: fail(f"toggle pin (2nd) failed: {r['status']}")
is_pinned = r["data"]["is_pinned"]
print(f"is_pinned: {is_pinned}")
if is_pinned: fail("expected is_pinned=false after second toggle")
ok()
write_doc("03_toggle_pin_off.md", "POST", f"/conversations/{conv_id}/pin",
    "再次调用翻转置顶状态（置顶 → 取消置顶），pinned_at 清空。",
    r["status"], r["body"],
    "每次调用原子翻转，单条 SQL 完成。")

# === 4: Toggle 免打扰 ON ===
step(4, f"POST /conversations/{conv_id}/mute - toggle mute ON")
r = Curl.post(f"{BASE}/conversations/{conv_id}/mute", None, token_a)
if r["status"] != 200: fail(f"toggle mute failed: {r['status']}")
is_muted = r["data"]["is_muted"]
print(f"is_muted: {is_muted}")
if not is_muted: fail("expected is_muted=true after first toggle")
ok()
write_doc("04_toggle_mute_on.md", "POST", f"/conversations/{conv_id}/mute",
    "Toggle 免打扰状态（首次调用，关闭 → 开启）。",
    r["status"], r["body"],
    "每次调用翻转 is_muted，仅影响当前用户的会话通知。")

# === 5: Toggle 免打扰 OFF ===
step(5, f"POST /conversations/{conv_id}/mute - toggle mute OFF")
r = Curl.post(f"{BASE}/conversations/{conv_id}/mute", None, token_a)
if r["status"] != 200: fail(f"toggle mute (2nd) failed: {r['status']}")
is_muted = r["data"]["is_muted"]
print(f"is_muted: {is_muted}")
if is_muted: fail("expected is_muted=false after second toggle")
ok()
write_doc("05_toggle_mute_off.md", "POST", f"/conversations/{conv_id}/mute",
    "再次调用翻转免打扰状态（开启 → 关闭）。",
    r["status"], r["body"],
    "服务端原子翻转，无需客户端传当前状态。")

# === 6: 标记未读 ===
step(6, f"POST /conversations/{conv_id}/unread - mark unread")
r = Curl.post(f"{BASE}/conversations/{conv_id}/unread", None, token_a)
if r["status"] != 200: fail(f"mark unread failed: {r['status']}")
unread_count = r["data"]["unread_count"]
print(f"unread_count: {unread_count}")
if unread_count != 1: fail(f"expected unread_count=1, got {unread_count}")
ok()
write_doc("06_mark_unread.md", "POST", f"/conversations/{conv_id}/unread",
    "标记会话为未读，unread_count 固定设为 1。",
    r["status"], r["body"],
    "不关心之前有无未读，总是设为 1。同时推送 total_unread 汇总值。")

# === 7: 标记已读（复原） ===
step(7, f"POST /conversations/{conv_id}/read - mark read (reset)")
r = Curl.post(f"{BASE}/conversations/{conv_id}/read", None, token_a)
if r["status"] != 200: fail(f"mark read failed: {r['status']}")
print("unread cleared")
ok()
write_doc("07_mark_read.md", "POST", f"/conversations/{conv_id}/read",
    "标记会话已读（清零 unread_count）。已有接口，本次无变更。",
    r["status"], r["body"],
    "与 mark_unread 互为逆操作。")

# === 8: 无效 UUID → 400 ===
step(8, "POST /conversations/not-a-uuid/pin - invalid UUID")
r = Curl.post(f"{BASE}/conversations/not-a-uuid/pin", None, token_a)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("08_invalid_uuid.md", "POST", "/conversations/not-a-uuid/pin",
    "会话 ID 格式非法（非 UUID），返回 400。",
    r["status"], r["body"],
    "路由层 Uuid::parse_str 失败即返回 400。")

# === 9: 非成员 → 403 ===
step(9, f"POST /conversations/{conv_id}/pin - non-member (user C)")
r = Curl.post(f"{BASE}/conversations/{conv_id}/pin", None, token_c)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("09_non_member.md", "POST", f"/conversations/{conv_id}/pin",
    "非会话成员操作（用户 C 不是 A-B 会话的成员），返回 403。",
    r["status"], r["body"],
    "is_member 校验失败，不执行 toggle。")

# === 10: 会话不存在 → 404 ===
fake_id = str(uuid_mod.uuid4())
step(10, f"POST /conversations/{fake_id}/pin - not found")
r = Curl.post(f"{BASE}/conversations/{fake_id}/pin", None, token_a)
if r["status"] != 404: fail(f"expected 404, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("10_not_found.md", "POST", f"/conversations/{fake_id}/pin",
    "会话不存在（随机 UUID），返回 404。",
    r["status"], r["body"],
    "conversation_exists 校验失败。")

# === 11: 未认证 → 401 ===
step(11, f"POST /conversations/{conv_id}/pin - unauthorized")
r = Curl.post(f"{BASE}/conversations/{conv_id}/pin", None, None)
if r["status"] != 401: fail(f"expected 401, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("11_unauthorized.md", "POST", f"/conversations/{conv_id}/pin",
    "无认证信息访问，返回 401。",
    r["status"], r["body"],
    "缺少 Authorization header 时 JWT 中间件返回 401。")

# === 生成 00_link.md ===
write_link()
print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
