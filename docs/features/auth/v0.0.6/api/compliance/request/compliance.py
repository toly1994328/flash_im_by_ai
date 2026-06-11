#!/usr/bin/env python3
"""
compliance - iOS 合规接口测试链 + 文档生成器
测试范围：举报、拉黑、账号注销
用法: python docs/features/auth/v0.0.6/api/compliance/request/compliance.py
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"
PHONE_B = "13800010002"
PHONE_C = "13800010003"  # 用于注销测试

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
    def put(url, json_body=None, token=None):
        return Curl.request("PUT", url, json_body, token)

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
    num = filename.split("_")[0].lstrip("0") or "0"
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = [
        "# compliance - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 登录测试用户 ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    if r["status"] != 200 or not r["data"]:
        fail(f"send sms failed for {phone}: {r['status']} {r['body']}")
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": str(code)
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
print(f"User C: id={uid_c} (for delete account test)")
ok()

# ─── 1: 举报消息 ───
step(1, "POST /api/reports - report a message")
j = json.dumps({"target_type": 0, "target_id": "fake-msg-id-123", "reason": 2, "description": "test harassment"})
r = Curl.post(f"{BASE}/api/reports", j, token_a)
if r["status"] != 201:
    fail(f"report failed: {r['status']} {r['body']}")
print(f"response: {r['body']}")
ok()
write_doc("01_report_message.md", "POST", "/api/reports",
    "举报消息或用户。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "target_type", "type": "int", "required": "是", "desc": "0=消息, 1=用户"},
        {"name": "target_id", "type": "string", "required": "是", "desc": "消息ID 或 用户ID"},
        {"name": "reason", "type": "int", "required": "是", "desc": "0=色情, 1=暴力, 2=骚扰, 3=诈骗, 4=其他"},
        {"name": "description", "type": "string", "required": "否", "desc": "补充说明"},
    ])

# ─── 2: 举报用户 ───
step(2, "POST /api/reports - report a user")
j = json.dumps({"target_type": 1, "target_id": str(uid_b), "reason": 3})
r = Curl.post(f"{BASE}/api/reports", j, token_a)
if r["status"] != 201:
    fail(f"report user failed: {r['status']} {r['body']}")
ok()
write_doc("02_report_user.md", "POST", "/api/reports",
    "举报用户（reason=3 诈骗）。", j, r["status"], r["body"], token_a)

# ─── 3: 举报参数错误 ───
step(3, "POST /api/reports - invalid reason (expect 400)")
j = json.dumps({"target_type": 0, "target_id": "abc", "reason": 99})
r = Curl.post(f"{BASE}/api/reports", j, token_a)
if r["status"] != 400:
    fail(f"expected 400, got {r['status']}")
ok()
write_doc("03_report_invalid.md", "POST", "/api/reports",
    "举报参数错误（reason 无效）。", j, r["status"], r["body"], token_a,
    notes="错误场景：reason 超出 0~4 范围")

# ─── 4: 拉黑用户 ───
step(4, "POST /api/blocks - block user B")
j = json.dumps({"blocked_id": uid_b})
r = Curl.post(f"{BASE}/api/blocks", j, token_a)
if r["status"] != 201:
    fail(f"block failed: {r['status']} {r['body']}")
ok()
write_doc("04_block_user.md", "POST", "/api/blocks",
    "拉黑用户。同时解除好友关系。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "blocked_id", "type": "int", "required": "是", "desc": "被拉黑的用户 ID"},
    ])

# ─── 5: 不能拉黑自己 ───
step(5, "POST /api/blocks - block self (expect 400)")
j = json.dumps({"blocked_id": uid_a})
r = Curl.post(f"{BASE}/api/blocks", j, token_a)
if r["status"] != 400:
    fail(f"expected 400, got {r['status']}")
ok()
write_doc("05_block_self.md", "POST", "/api/blocks",
    "不能拉黑自己。", j, r["status"], r["body"], token_a,
    notes="错误场景：blocker_id == blocked_id")

# ─── 6: 检查是否已拉黑 ───
step(6, "GET /api/blocks/check - is B blocked?")
r = Curl.get(f"{BASE}/api/blocks/check?user_id={uid_b}", token_a)
if r["status"] != 200:
    fail(f"check failed: {r['status']}")
if not r["data"].get("is_blocked"):
    fail(f"expected is_blocked=true, got {r['data']}")
ok()
write_doc("06_check_block.md", "GET", f"/api/blocks/check?user_id={uid_b}",
    "检查是否已拉黑某用户。", None, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "user_id", "type": "int", "required": "是", "desc": "待检查的用户 ID (query param)"},
    ])

# ─── 7: 获取黑名单 ───
step(7, "GET /api/blocks - list blocked users")
r = Curl.get(f"{BASE}/api/blocks", token_a)
if r["status"] != 200:
    fail(f"list failed: {r['status']}")
print(f"blocked count: {len(r['data'].get('data', []))}")
ok()
write_doc("07_block_list.md", "GET", "/api/blocks",
    "获取黑名单列表。", None, r["status"], r["body"], token_a)

# ─── 8: 取消拉黑 ───
step(8, f"DELETE /api/blocks/{uid_b} - unblock user B")
r = Curl.delete(f"{BASE}/api/blocks/{uid_b}", token_a)
if r["status"] != 200:
    fail(f"unblock failed: {r['status']} {r['body']}")
ok()
write_doc("08_unblock.md", "DELETE", f"/api/blocks/{uid_b}",
    "取消拉黑用户。", None, r["status"], r["body"], token_a)

# ─── 9: 验证取消拉黑 ───
step(9, "GET /api/blocks/check - verify unblocked")
r = Curl.get(f"{BASE}/api/blocks/check?user_id={uid_b}", token_a)
if r["data"].get("is_blocked"):
    fail("still blocked after unblock")
ok()
write_doc("09_verify_unblocked.md", "GET", f"/api/blocks/check?user_id={uid_b}",
    "验证取消拉黑后 is_blocked=false。", None, r["status"], r["body"], token_a)

# ─── 10: 注销账号 - 先设置密码 ───
step(10, "POST /user/password - set password for user C")
j = json.dumps({"new_password": "delete123"})
r = Curl.post(f"{BASE}/user/password", j, token_c)
if r["status"] != 200:
    fail(f"set password failed: {r['status']} {r['body']}")
ok()
write_doc("10_set_password.md", "POST", "/user/password",
    "为用户 C 设置密码（注销前置条件）。", j, r["status"], r["body"], token_c)

# ─── 11: 注销账号 - 密码错误 ───
step(11, "POST /api/account/delete - wrong password (expect 401)")
j = json.dumps({"password": "wrongpass"})
r = Curl.post(f"{BASE}/api/account/delete", j, token_c)
if r["status"] != 401:
    fail(f"expected 401, got {r['status']}")
ok()
write_doc("11_delete_wrong_pwd.md", "POST", "/api/account/delete",
    "注销账号 - 密码错误。", j, r["status"], r["body"], token_c,
    notes="错误场景：密码验证失败")

# ─── 12: 注销账号 - 正确密码 ───
step(12, "POST /api/account/delete - correct password")
j = json.dumps({"password": "delete123"})
r = Curl.post(f"{BASE}/api/account/delete", j, token_c)
if r["status"] != 200:
    fail(f"delete account failed: {r['status']} {r['body']}")
ok()
write_doc("12_delete_account.md", "POST", "/api/account/delete",
    "注销账号。验证密码后直接删除用户数据。", j, r["status"], r["body"], token_c,
    params_desc=[
        {"name": "password", "type": "string", "required": "是", "desc": "用户密码"},
    ])

# ─── 13: 注销后登录失败 ───
step(13, "POST /auth/login - login after deletion (expect fail)")
r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": PHONE_C}))
code = r["data"]["code"] if r["data"] else "0000"
r = Curl.post(f"{BASE}/auth/login", json.dumps({
    "phone": PHONE_C, "type": "sms", "credential": str(code)
}))
# 注销后重新登录会创建新账号（因为手机号登录是自动注册的）
# 验证旧 token 失效即可
r2 = Curl.get(f"{BASE}/user/profile", token_c)
if r2["status"] != 401 and r2["status"] != 404:
    fail(f"expected 401/404 for old token, got {r2['status']}")
print(f"old token status: {r2['status']} (expected 401 or 404)")
ok()
write_doc("13_login_after_delete.md", "GET", "/user/profile",
    "注销后旧 token 失效验证。", None, r2["status"], r2["body"], token_c,
    notes="注销后旧 token 应无法访问资源")

# ─── 输出结果 ───
write_link()
print(f"\n{GREEN}{'='*40}{RESET}")
print(f"{GREEN}All tests passed: {passed}/{passed}{RESET}")
print(f"Docs generated: {DOCS_DIR}")
