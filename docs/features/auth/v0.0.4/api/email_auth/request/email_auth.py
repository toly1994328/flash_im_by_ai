#!/usr/bin/env python3
"""
email_auth - API 测试链 + 文档生成器
用法: python docs/features/auth/v0.0.4/api/email_auth/request/email_auth.py
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
TEST_EMAIL = "test@example.com"

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
        "# email_auth - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ═══════════════════════════════════════════
# 测试步骤
# ═══════════════════════════════════════════

# === 1: 发送邮箱验证码 ===
step(1, "POST /auth/email/code - 发送验证码")
j = json.dumps({"email": TEST_EMAIL})
r = Curl.post(f"{BASE}/auth/email/code", j)
if r["status"] != 200:
    fail(f"发送验证码失败: status={r['status']}, body={r['body']}")
code = r["data"].get("code")
print(f"验证码: {code}")
if not code:
    fail("debug 模式未返回验证码")
ok()
write_doc("01_send_email_code.md", "POST", "/auth/email/code",
    "发送邮箱验证码。debug 模式下直接返回验证码。", j, r["status"], r["body"], None,
    params_desc=[
        {"name": "email", "type": "string", "required": "是", "desc": "邮箱地址"},
    ])

# === 2: 频率限制 ===
step(2, "POST /auth/email/code - 频率限制（60秒内重复）")
r2 = Curl.post(f"{BASE}/auth/email/code", j)
print(f"status: {r2['status']}")
if r2["status"] != 429:
    fail(f"期望 429，实际 {r2['status']}")
ok()
write_doc("02_rate_limit.md", "POST", "/auth/email/code",
    "60 秒内同一邮箱或同一 IP 重复请求，返回 429。", j, r2["status"], r2["body"], None,
    notes="频率限制：同一邮箱或同一 IP 60 秒内只能发一次")

# === 3: 邮箱格式校验 ===
step(3, "POST /auth/email/code - 邮箱格式无效")
j_bad = json.dumps({"email": "not-an-email"})
r3 = Curl.post(f"{BASE}/auth/email/code", j_bad)
print(f"status: {r3['status']}")
if r3["status"] != 400:
    fail(f"期望 400，实际 {r3['status']}")
ok()
write_doc("03_invalid_email.md", "POST", "/auth/email/code",
    "邮箱格式无效时返回 400。", j_bad, r3["status"], r3["body"], None,
    notes="邮箱必须包含 @ 和 .")

# === 4: 邮箱验证码登录 ===
step(4, "POST /auth/login - 邮箱验证码登录")
j_login = json.dumps({"phone": TEST_EMAIL, "type": "email", "credential": code})
r4 = Curl.post(f"{BASE}/auth/login", j_login)
if r4["status"] != 200:
    fail(f"邮箱登录失败: status={r4['status']}, body={r4['body']}")
token = r4["data"].get("token")
user_id = r4["data"].get("user_id")
print(f"token: {token[:20]}...")
print(f"user_id: {user_id}")
if not token:
    fail("未返回 token")
ok()
write_doc("04_email_login.md", "POST", "/auth/login",
    "使用邮箱验证码登录。首次登录自动注册。", j_login, r4["status"], r4["body"], None,
    params_desc=[
        {"name": "phone", "type": "string", "required": "是", "desc": "邮箱地址（复用 phone 字段）"},
        {"name": "type", "type": "string", "required": "是", "desc": "登录类型：email"},
        {"name": "credential", "type": "string", "required": "是", "desc": "验证码或密码"},
    ])

# === 5: 错误验证码登录 ===
step(5, "POST /auth/login - 错误验证码")
j_wrong = json.dumps({"phone": TEST_EMAIL, "type": "email", "credential": "000000"})
r5 = Curl.post(f"{BASE}/auth/login", j_wrong)
print(f"status: {r5['status']}")
if r5["status"] != 401:
    fail(f"期望 401，实际 {r5['status']}")
ok()
write_doc("05_wrong_credential.md", "POST", "/auth/login",
    "验证码错误且无密码时返回 401。", j_wrong, r5["status"], r5["body"], None,
    notes="验证码不匹配，且该邮箱未设置密码，返回 401")

# === 结果 ===
print(f"\n{GREEN}═══════════════════════════════════════{RESET}")
print(f"{GREEN}  ALL PASSED: {passed}/{passed}{RESET}")
print(f"{GREEN}═══════════════════════════════════════{RESET}")

write_link()
print(f"\n文档已生成到: {DOCS_DIR}")
