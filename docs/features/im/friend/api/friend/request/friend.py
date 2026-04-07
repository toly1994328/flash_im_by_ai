#!/usr/bin/env python3
"""
friend - API 测试链 + 文档生成器
用法: python docs/features/im/friend/api/friend/request/friend.py
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

    @staticmethod
    def delete(url, token=None):
        return Curl.request("DELETE", url, token=token)


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
        "# friend - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 清理旧数据 + 登录两个用户 ───

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

# 清理：删除可能存在的好友关系
Curl.delete(f"{BASE}/api/friends/{uid_b}", token_a)
Curl.delete(f"{BASE}/api/friends/{uid_a}", token_b)
ok()

# === 1: 搜索用户 ===
step(1, "GET /api/users/search - search by nickname")
r = Curl.get(f"{BASE}/api/users/search?keyword=%E6%A9%98", token_a)  # 搜索"橘"
if r["status"] != 200: fail(f"search failed: {r['status']}")
print(f"results: {len(r['data']['data'])} users")
ok()
write_doc("01_search_users.md", "GET", "/api/users/search?keyword=橘",
    "按昵称模糊搜索用户。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（昵称模糊匹配）"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 20，最大 50"},
    ])

# === 2: 发送好友申请 ===
step(2, "POST /api/friends/requests - send request")
j = json.dumps({"to_user_id": uid_b, "message": "你好，我是测试用户A"})
r = Curl.post(f"{BASE}/api/friends/requests", j, token_a)
if r["status"] != 200: fail(f"send request failed: {r['status']}")
request_id = r["data"]["data"]["id"]
print(f"request_id: {request_id}")
assert r["data"]["data"]["status"] == 0
assert r["data"]["data"]["message"] == "你好，我是测试用户A"
ok()
write_doc("02_send_request.md", "POST", "/api/friends/requests",
    "发送好友申请，可附带留言。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "to_user_id", "type": "int", "required": "是", "desc": "目标用户 ID"},
        {"name": "message", "type": "string", "required": "否", "desc": "申请留言，最长 200 字"},
    ])

# === 3: 重复申请 ===
step(3, "POST /api/friends/requests - duplicate request")
j3 = json.dumps({"to_user_id": uid_b})
r = Curl.post(f"{BASE}/api/friends/requests", j3, token_a)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("03_duplicate_request.md", "POST", "/api/friends/requests",
    "重复发送好友申请（已有待处理申请）。", j3, r["status"], r["body"] or "(empty body)", token_a,
    "同一对用户存在待处理申请时返回 400。")

# === 4: 不能加自己 ===
step(4, "POST /api/friends/requests - cannot add self")
j4 = json.dumps({"to_user_id": uid_a})
r = Curl.post(f"{BASE}/api/friends/requests", j4, token_a)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("04_add_self.md", "POST", "/api/friends/requests",
    "不能添加自己为好友。", j4, r["status"], r["body"] or "(empty body)", token_a,
    "to_user_id 等于自己时返回 400。")

# === 5: 目标用户不存在 ===
step(5, "POST /api/friends/requests - user not found")
j5 = json.dumps({"to_user_id": 999999})
r = Curl.post(f"{BASE}/api/friends/requests", j5, token_a)
if r["status"] != 404: fail(f"expected 404, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("05_user_not_found.md", "POST", "/api/friends/requests",
    "目标用户不存在。", j5, r["status"], r["body"] or "(empty body)", token_a,
    "to_user_id 不存在时返回 404。")

# === 6: B 查询收到的申请 ===
step(6, "GET /api/friends/requests/received - B's received")
r = Curl.get(f"{BASE}/api/friends/requests/received", token_b)
if r["status"] != 200: fail(f"get received failed: {r['status']}")
items = r["data"]["data"]
print(f"received: {len(items)} requests")
found = any(item["id"] == request_id for item in items)
if not found: fail("request not found in B's received list")
# 验证带有申请者昵称
first = next(item for item in items if item["id"] == request_id)
print(f"from: {first.get('nickname', '?')}, message: {first.get('message', '')}")
ok()
write_doc("06_received_requests.md", "GET", "/api/friends/requests/received",
    "查询收到的好友申请列表（仅 pending 状态）。", None, r["status"], r["body"], token_b,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 7: A 查询发送的申请 ===
step(7, "GET /api/friends/requests/sent - A's sent")
r = Curl.get(f"{BASE}/api/friends/requests/sent", token_a)
if r["status"] != 200: fail(f"get sent failed: {r['status']}")
items = r["data"]["data"]
print(f"sent: {len(items)} requests")
found = any(item["id"] == request_id for item in items)
if not found: fail("request not found in A's sent list")
ok()
write_doc("07_sent_requests.md", "GET", "/api/friends/requests/sent",
    "查询发送的好友申请列表。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 8: B 接受申请 ===
step(8, f"POST /api/friends/requests/{request_id}/accept")
r = Curl.post(f"{BASE}/api/friends/requests/{request_id}/accept", None, token_b)
if r["status"] != 200: fail(f"accept failed: {r['status']}")
print("accepted")
ok()
write_doc("08_accept_request.md", "POST", f"/api/friends/requests/{request_id}/accept",
    "接受好友申请。副作用：创建双向好友关系 + 自动创建私聊会话 + 发送打招呼消息。",
    None, r["status"], r["body"], token_b,
    "只有被申请者（to_user_id）可以接受。接受后自动创建私聊会话并发送打招呼消息。")

# === 9: 重复接受 ===
step(9, f"POST /api/friends/requests/{request_id}/accept - already accepted")
r = Curl.post(f"{BASE}/api/friends/requests/{request_id}/accept", None, token_b)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("09_accept_again.md", "POST", f"/api/friends/requests/{request_id}/accept",
    "重复接受已处理的申请。", None, r["status"], r["body"] or "(empty body)", token_b,
    "申请已非 pending 状态时返回 403。")

# === 10: A 查询好友列表 ===
step(10, "GET /api/friends - A's friend list")
r = Curl.get(f"{BASE}/api/friends", token_a)
if r["status"] != 200: fail(f"get friends failed: {r['status']}")
friends = r["data"]["data"]
print(f"friends: {len(friends)}")
found = any(str(f["friend_id"]) == str(uid_b) for f in friends)
if not found: fail("B not in A's friend list")
friend_b = next(f for f in friends if str(f["friend_id"]) == str(uid_b))
print(f"friend: {friend_b.get('nickname', '?')}")
ok()
write_doc("10_friends_list_a.md", "GET", "/api/friends",
    "查询好友列表（A 视角），接受申请后 B 应出现在列表中。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 11: B 查询好友列表 ===
step(11, "GET /api/friends - B's friend list")
r = Curl.get(f"{BASE}/api/friends", token_b)
if r["status"] != 200: fail(f"get friends failed: {r['status']}")
friends = r["data"]["data"]
found = any(str(f["friend_id"]) == str(uid_a) for f in friends)
if not found: fail("A not in B's friend list")
print(f"friends: {len(friends)}")
ok()
write_doc("11_friends_list_b.md", "GET", "/api/friends",
    "查询好友列表（B 视角），双向关系验证。", None, r["status"], r["body"], token_b)

# === 12: 验证自动创建的私聊会话 ===
step(12, "GET /conversations - verify auto-created conversation")
r = Curl.get(f"{BASE}/conversations", token_a)
if r["status"] != 200: fail(f"get conversations failed: {r['status']}")
convs = r["data"]
found = any(str(c.get("peer_user_id", "")) == str(uid_b) for c in convs)
if not found: fail("conversation with B not found")
print("auto-created conversation exists")
ok()
write_doc("12_auto_conversation.md", "GET", "/conversations",
    "验证接受好友后自动创建的私聊会话。", None, r["status"], r["body"], token_a,
    "接受好友申请后，系统自动创建私聊会话并发送打招呼消息。")

# === 13: A 删除好友 B ===
step(13, f"DELETE /api/friends/{uid_b} - A removes B")
r = Curl.delete(f"{BASE}/api/friends/{uid_b}", token_a)
if r["status"] != 200: fail(f"delete friend failed: {r['status']}")
print("friend deleted")
ok()
write_doc("13_delete_friend.md", "DELETE", f"/api/friends/{uid_b}",
    "删除好友，双向关系同时解除。", None, r["status"], r["body"], token_a,
    "删除后双方的好友列表中都不再包含对方。WS 通知双方。")

# === 14: 删除后好友列表 ===
step(14, "GET /api/friends - A's list after delete")
r = Curl.get(f"{BASE}/api/friends", token_a)
if r["status"] != 200: fail(f"get friends failed: {r['status']}")
friends = r["data"]["data"]
found = any(str(f["friend_id"]) == str(uid_b) for f in friends)
if found: fail("B still in A's friend list after delete")
print(f"friends: {len(friends)} (B removed)")
ok()
write_doc("14_friends_after_delete.md", "GET", "/api/friends",
    "删除好友后查询列表，已删除的好友不再出现。", None, r["status"], r["body"], token_a)

# === 15: 删除好友后重新申请 ===
step(15, "POST /api/friends/requests - re-send after delete")
j15 = json.dumps({"to_user_id": uid_b, "message": "再次添加"})
r = Curl.post(f"{BASE}/api/friends/requests", j15, token_a)
if r["status"] != 200: fail(f"re-send failed: {r['status']}")
new_request_id = r["data"]["data"]["id"]
print(f"new request_id: {new_request_id}")
ok()
write_doc("15_resend_after_delete.md", "POST", "/api/friends/requests",
    "删除好友后可以重新发送申请。", j15, r["status"], r["body"], token_a,
    "删除好友后，UNIQUE 约束通过 ON CONFLICT DO UPDATE 重置申请状态。")

# === 16: B 拒绝申请 ===
step(16, f"POST /api/friends/requests/{new_request_id}/reject")
r = Curl.post(f"{BASE}/api/friends/requests/{new_request_id}/reject", None, token_b)
if r["status"] != 200: fail(f"reject failed: {r['status']}")
print("rejected")
ok()
write_doc("16_reject_request.md", "POST", f"/api/friends/requests/{new_request_id}/reject",
    "拒绝好友申请。", None, r["status"], r["body"], token_b,
    "拒绝后申请状态变为 rejected，不通知申请者。")

# === 17: 拒绝后无 pending 申请 ===
step(17, "GET /api/friends/requests/received - no pending after reject")
r = Curl.get(f"{BASE}/api/friends/requests/received", token_b)
if r["status"] != 200: fail(f"get received failed: {r['status']}")
items = r["data"]["data"]
pending = [item for item in items if item["status"] == 0]
if len(pending) > 0:
    # 检查是否有来自 A 的 pending
    from_a = [item for item in pending if str(item["from_user_id"]) == str(uid_a)]
    if from_a:
        fail("still has pending request from A after reject")
print(f"pending: {len(pending)} (none from A)")
ok()
write_doc("17_no_pending_after_reject.md", "GET", "/api/friends/requests/received",
    "拒绝后查询收到的申请，被拒绝的不再显示（仅返回 pending）。",
    None, r["status"], r["body"], token_b)

# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
