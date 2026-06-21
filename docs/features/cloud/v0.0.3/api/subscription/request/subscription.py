#!/usr/bin/env python3
"""
subscription + OSS upload-token - API 测试链 + 文档生成器
用法: python docs/features/cloud/v0.0.3/api/subscription/request/subscription.py
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
    print(f"{CYAN}========== [{n}] {desc} =========={RESET}")

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
        "# subscription - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── pre: 登录 ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    if r["status"] != 200:
        fail(f"SMS failed: {r['status']} {r['body']}")
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"Login failed: {r['body']}")
    return r["data"]["token"], r["data"]["user_id"]


print(f"\n{YELLOW}=== pre: 登录用户 ==={RESET}")
token_a, uid_a = login(PHONE_A)
print(f"  user_id={uid_a}")

# ─── 测试步骤 ───

# 1. 查询订阅状态（无订阅）
step(1, "GET /api/subscriptions/status - 无订阅")
r = Curl.get(f"{BASE}/api/subscriptions/status", token_a)
if r["status"] != 200:
    fail(f"status failed: {r['status']} {r['body']}")
if r["data"]["has_active_subscription"]:
    fail("should have no subscription")
print(f"  has_active_subscription: {r['data']['has_active_subscription']}")
print(f"  oss_upload_enabled: {r['data']['oss_upload_enabled']}")
ok()
write_doc("01_status_no_sub.md", "GET", "/api/subscriptions/status",
    "查询当前用户订阅状态（无订阅时）。", None, r["status"], r["body"], token_a)

# 2. upload-token 无订阅被拒绝
step(2, "POST /api/storage/upload-token - 无订阅被拒绝")
j = json.dumps({"file_name": "test.jpg", "file_size": 1024, "mime_type": "image/jpeg", "hash": "abc123"})
r = Curl.post(f"{BASE}/api/storage/upload-token", j, token_a)
if r["status"] != 403:
    fail(f"expected 403, got {r['status']} {r['body']}")
print(f"  status: {r['status']}, message: {r['data'].get('message', '')}")
ok()
write_doc("02_upload_token_no_sub.md", "POST", "/api/storage/upload-token",
    "无订阅用户请求 upload-token 被拒绝（403）。", j, r["status"], r["body"], token_a,
    notes="无活跃订阅的用户不能使用 OSS 上传")

# 3. 兑换码 - 无效码
step(3, "POST /api/subscriptions/redeem - 无效兑换码")
j = json.dumps({"code": "INVALID-CODE"})
r = Curl.post(f"{BASE}/api/subscriptions/redeem", j, token_a)
if r["status"] != 400:
    fail(f"expected 400, got {r['status']} {r['body']}")
print(f"  status: {r['status']}, message: {r['data'].get('message', '')}")
ok()
write_doc("03_redeem_invalid.md", "POST", "/api/subscriptions/redeem",
    "使用无效兑换码（400）。", j, r["status"], r["body"], token_a,
    notes="兑换码不存在时返回 400")

# 4. 兑换码 - 成功
step(4, "POST /api/subscriptions/redeem - 成功兑换")
j = json.dumps({"code": "TEST-PRO-2026"})
r = Curl.post(f"{BASE}/api/subscriptions/redeem", j, token_a)
if r["status"] != 200:
    fail(f"redeem failed: {r['status']} {r['body']}")
sub = r["data"]["subscription"]
quota = r["data"]["quota"]
print(f"  plan: {sub['plan_code']} ({sub['plan_name']})")
print(f"  expires_at: {sub['expires_at']}")
print(f"  quota: {quota['used_bytes']}/{quota['quota_bytes']}")
ok()
write_doc("04_redeem_success.md", "POST", "/api/subscriptions/redeem",
    "使用有效兑换码激活订阅。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "code", "type": "string", "required": "是", "desc": "兑换码"},
    ])

# 5. 查询订阅状态（有订阅）
step(5, "GET /api/subscriptions/status - 有订阅")
r = Curl.get(f"{BASE}/api/subscriptions/status", token_a)
if r["status"] != 200:
    fail(f"status failed: {r['status']} {r['body']}")
if not r["data"]["has_active_subscription"]:
    fail("should have active subscription")
if not r["data"]["oss_upload_enabled"]:
    fail("oss_upload should be enabled")
print(f"  has_active_subscription: {r['data']['has_active_subscription']}")
print(f"  oss_upload_enabled: {r['data']['oss_upload_enabled']}")
print(f"  plan: {r['data']['plan_code']}")
ok()
write_doc("05_status_with_sub.md", "GET", "/api/subscriptions/status",
    "查询当前用户订阅状态（有活跃订阅时）。", None, r["status"], r["body"], token_a)

# 6. upload-token 有订阅成功
step(6, "POST /api/storage/upload-token - 有订阅成功")
j = json.dumps({"file_name": "photo.jpg", "file_size": 2048000, "mime_type": "image/jpeg", "hash": "def456"})
r = Curl.post(f"{BASE}/api/storage/upload-token", j, token_a)
if r["status"] != 200:
    fail(f"upload-token failed: {r['status']} {r['body']}")
print(f"  object_key: {r['data']['object_key']}")
print(f"  url: {r['data']['url']}")
print(f"  expiration: {r['data']['expiration']}")
ok()
write_doc("06_upload_token_success.md", "POST", "/api/storage/upload-token",
    "有订阅用户获取 STS Token 成功。", j, r["status"], r["body"], token_a,
    params_desc=[
        {"name": "file_name", "type": "string", "required": "是", "desc": "文件名"},
        {"name": "file_size", "type": "int", "required": "是", "desc": "文件大小（bytes）"},
        {"name": "mime_type", "type": "string", "required": "是", "desc": "MIME 类型"},
        {"name": "hash", "type": "string", "required": "是", "desc": "文件 SHA-1 哈希"},
    ])

# ─── 完成 ───

write_link()
print(f"\n{GREEN}{'='*50}")
print(f"  ALL PASSED: {passed}/{passed}")
print(f"  Docs generated in: {DOCS_DIR}")
print(f"{'='*50}{RESET}")
