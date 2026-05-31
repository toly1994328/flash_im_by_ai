#!/usr/bin/env python3
"""
scan - 扫码登录 API 测试链 + 文档生成器
用法: python docs/features/auth/v0.0.5/api/scan/request/scan.py
"""

import json
import os
import subprocess
import sys

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
        "# scan - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 登录手机端用户 ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]

step("pre", "Login mobile user")
user_a = login(PHONE_A)
token_a, uid_a = user_a["token"], user_a["user_id"]
print(f"Mobile user: id={uid_a}, token={token_a[:20]}...")
ok()

# ─── 1. 创建扫码会话 ───

step(1, "POST /auth/scan/create - 创建扫码会话")
r = Curl.post(f"{BASE}/auth/scan/create")
if r["status"] != 200: fail(f"create failed: {r['status']} {r['body']}")
scan_token = r["data"]["token"]
qr_content = r["data"]["qr_content"]
print(f"scan_token: {scan_token}")
print(f"qr_content: {qr_content}")
assert qr_content == f"flashim://scan/{scan_token}"
ok()
write_doc("01_scan_create.md", "POST", "/auth/scan/create",
    "创建扫码登录会话，返回二维码内容。桌面端调用。", None, r["status"], r["body"], None,
    notes="无需认证，桌面端未登录时调用")

# ─── 2. 查询状态 - pending ───

step(2, "GET /auth/scan/status - 状态 pending")
r = Curl.get(f"{BASE}/auth/scan/status?token={scan_token}")
if r["status"] != 200: fail(f"status failed: {r['status']}")
if r["data"]["status"] != "pending": fail(f"expected pending, got {r['data']['status']}")
ok()
write_doc("02_scan_status_pending.md", "GET", f"/auth/scan/status?token={scan_token}",
    "查询扫码会话状态。桌面端轮询调用。", None, r["status"], r["body"], None,
    params_desc=[
        {"name": "token", "type": "string", "required": "是", "desc": "扫码会话 token（query 参数）"},
    ])

# ─── 3. 手机端扫码 ───

step(3, "POST /auth/scan/confirm (action=scan) - 手机端扫码")
j = json.dumps({"scan_token": scan_token, "action": "scan"})
r = Curl.post(f"{BASE}/auth/scan/confirm", j, token_a)
if r["status"] != 200: fail(f"scan failed: {r['status']} {r['body']}")
ok()
write_doc("03_scan_confirm_scan.md", "POST", "/auth/scan/confirm",
    "手机端扫码，标记会话为已扫码。需要手机端 JWT 认证。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "scan_token", "type": "string", "required": "是", "desc": "扫码会话 token"},
        {"name": "action", "type": "string", "required": "是", "desc": "动作：scan 或 confirm"},
    ])

# ─── 4. 查询状态 - scanned ───

step(4, "GET /auth/scan/status - 状态 scanned")
r = Curl.get(f"{BASE}/auth/scan/status?token={scan_token}")
if r["status"] != 200: fail(f"status failed: {r['status']}")
if r["data"]["status"] != "scanned": fail(f"expected scanned, got {r['data']['status']}")
ok()
write_doc("04_scan_status_scanned.md", "GET", f"/auth/scan/status?token={scan_token}",
    "查询扫码会话状态，已扫码等待确认。", None, r["status"], r["body"], None)

# ─── 5. 手机端确认登录 ───

step(5, "POST /auth/scan/confirm (action=confirm) - 手机端确认")
j = json.dumps({"scan_token": scan_token, "action": "confirm"})
r = Curl.post(f"{BASE}/auth/scan/confirm", j, token_a)
if r["status"] != 200: fail(f"confirm failed: {r['status']} {r['body']}")
ok()
write_doc("05_scan_confirm_confirm.md", "POST", "/auth/scan/confirm",
    "手机端确认登录，后端为桌面端签发 JWT。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "scan_token", "type": "string", "required": "是", "desc": "扫码会话 token"},
        {"name": "action", "type": "string", "required": "是", "desc": "动作：confirm"},
    ])

# ─── 6. 查询状态 - confirmed（携带 token） ───

step(6, "GET /auth/scan/status - 状态 confirmed + JWT")
r = Curl.get(f"{BASE}/auth/scan/status?token={scan_token}")
if r["status"] != 200: fail(f"status failed: {r['status']}")
if r["data"]["status"] != "confirmed": fail(f"expected confirmed, got {r['data']['status']}")
if not r["data"].get("token"): fail("missing JWT token in confirmed response")
if r["data"].get("user_id") != uid_a: fail(f"user_id mismatch: {r['data'].get('user_id')} != {uid_a}")
desktop_token = r["data"]["token"]
print(f"desktop JWT: {desktop_token[:20]}...")
ok()
write_doc("06_scan_status_confirmed.md", "GET", f"/auth/scan/status?token={scan_token}",
    "查询扫码会话状态，已确认，返回桌面端 JWT token 和 user_id。", None, r["status"], r["body"], None,
    notes="桌面端拿到 token 后保存，进入主页")

# ─── 7. 错误场景：无效 token ───

step(7, "GET /auth/scan/status - 无效 token (404)")
r = Curl.get(f"{BASE}/auth/scan/status?token=invalid-token-xxx")
if r["status"] != 404: fail(f"expected 404, got {r['status']}")
ok()
write_doc("07_scan_status_not_found.md", "GET", "/auth/scan/status?token=invalid-token-xxx",
    "查询不存在的扫码会话，返回 404。", None, r["status"], r["body"], None,
    notes="错误场景：token 不存在")

# ─── 8. 错误场景：未认证扫码 (401) ───

step(8, "POST /auth/scan/confirm - 未认证 (401)")
# 先创建新会话
r2 = Curl.post(f"{BASE}/auth/scan/create")
new_token = r2["data"]["token"]
j = json.dumps({"scan_token": new_token, "action": "scan"})
r = Curl.post(f"{BASE}/auth/scan/confirm", j)  # 不带 JWT
if r["status"] != 401: fail(f"expected 401, got {r['status']}")
ok()
write_doc("08_scan_confirm_unauthorized.md", "POST", "/auth/scan/confirm",
    "未携带 JWT 认证的扫码请求，返回 401。", j, r["status"], r["body"], None,
    notes="错误场景：手机端未登录")

# ─── 9. 取消流程 ───

step(9, "POST /auth/scan/cancel - 取消扫码")
# 先扫码
j = json.dumps({"scan_token": new_token, "action": "scan"})
r = Curl.post(f"{BASE}/auth/scan/confirm", j, token_a)
if r["status"] != 200: fail(f"scan for cancel test failed: {r['status']}")
# 取消
j = json.dumps({"scan_token": new_token})
r = Curl.post(f"{BASE}/auth/scan/cancel", j, token_a)
if r["status"] != 200: fail(f"cancel failed: {r['status']} {r['body']}")
ok()
write_doc("09_scan_cancel.md", "POST", "/auth/scan/cancel",
    "手机端取消扫码登录。需要手机端 JWT 认证。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "scan_token", "type": "string", "required": "是", "desc": "扫码会话 token"},
    ])

# ─── 10. 取消后状态 ───

step(10, "GET /auth/scan/status - 状态 cancelled")
r = Curl.get(f"{BASE}/auth/scan/status?token={new_token}")
if r["status"] != 200: fail(f"status failed: {r['status']}")
if r["data"]["status"] != "cancelled": fail(f"expected cancelled, got {r['data']['status']}")
ok()
write_doc("10_scan_status_cancelled.md", "GET", f"/auth/scan/status?token={new_token}",
    "查询已取消的扫码会话状态。", None, r["status"], r["body"], None)

# ─── 完成 ───

write_link()
print(f"\n{GREEN}========== ALL {passed}/{passed} PASSED =========={RESET}")
print(f"Docs generated in: {DOCS_DIR}")
