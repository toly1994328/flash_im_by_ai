#!/usr/bin/env python3
"""
app-center - API 测试链 + 文档生成器
用法: python docs/features/starter/v0.0.3/api/app-center/request/app_center.py

覆盖接口：
  GET  /api/app/list          - 应用列表
  POST /api/app               - 新增应用
  GET  /api/app/versions      - 某应用全部版本
  GET  /api/app/version       - 查询最新版本
  POST /api/app/version       - 新增版本
  PUT  /api/app/version       - 更新版本
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"

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

def write_doc(filename, method, path, desc, param_json, resp_status, resp_body, token=None, notes=None, params_desc=None):
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
    lines = [
        "# app-center - API test link",
        "",
        f"Base URL: `{BASE}`",
        "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ] + link_lines
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))


# ══════════════════════════════════════════════════════════════
#  测试步骤
# ══════════════════════════════════════════════════════════════

# ─── 1. 获取应用列表 ───

step(1, "GET /api/app/list - 获取应用列表")
r = Curl.get(f"{BASE}/api/app/list")
if r["status"] != 200:
    fail(f"list apps failed: {r['status']} {r['body']}")
print(f"apps count: {len(r['data'])}")
ok()
write_doc("01_list_apps.md", "GET", "/api/app/list",
    "获取所有注册的应用列表。", None, r["status"], r["body"],
    notes="返回数组，按创建时间排序")


# ─── 2. 新增应用 ───

step(2, "POST /api/app - 新增应用")
body = json.dumps({"id": "test_app", "name": "测试应用", "description": "用于测试的应用"})
r = Curl.post(f"{BASE}/api/app", body)
if r["status"] != 201:
    fail(f"create app failed: {r['status']} {r['body']}")
print(f"response: {r['body']}")
ok()
write_doc("02_create_app.md", "POST", "/api/app",
    "新增应用。注册一个新的应用到系统中。", body, r["status"], r["body"],
    params_desc=[
        {"name": "id", "type": "string", "required": "是", "desc": "应用唯一标识"},
        {"name": "name", "type": "string", "required": "是", "desc": "应用名称"},
        {"name": "description", "type": "string", "required": "否", "desc": "应用描述"},
    ])


# ─── 3. 重复新增应用（409） ───

step(3, "POST /api/app - 重复新增应用")
r = Curl.post(f"{BASE}/api/app", body)
if r["status"] != 400:
    fail(f"expected 400 for duplicate app, got: {r['status']}")
print(f"response: {r['body']}")
ok()
write_doc("03_create_app_duplicate.md", "POST", "/api/app",
    "重复新增同一应用，返回错误。", body, r["status"], r["body"],
    notes="app id 已存在时返回 400")


# ─── 4. 再次获取应用列表（验证新增生效） ───

step(4, "GET /api/app/list - 验证新增应用出现在列表中")
r = Curl.get(f"{BASE}/api/app/list")
if r["status"] != 200:
    fail(f"list failed: {r['status']}")
ids = [a["id"] for a in r["data"]]
if "test_app" not in ids:
    fail(f"test_app not in list: {ids}")
print(f"apps: {ids}")
ok()
write_doc("04_list_apps_after_create.md", "GET", "/api/app/list",
    "新增应用后验证列表包含新应用。", None, r["status"], r["body"])


# ─── 5. 为 test_app 新增版本 ───

step(5, "POST /api/app/version - 为 test_app 新增版本")
ver_body = json.dumps({
    "app_id": "test_app",
    "platform": "windows",
    "version": "0.1.0",
    "download_url": "https://example.com/test_app_0.1.0.exe",
    "file_size": 10000000,
    "sha256": "test_hash_123",
    "release_notes": "测试版本",
    "force_update": False
})
r = Curl.post(f"{BASE}/api/app/version", ver_body)
if r["status"] != 201:
    fail(f"create version failed: {r['status']} {r['body']}")
print(f"response: {r['body']}")
ok()
write_doc("05_create_version.md", "POST", "/api/app/version",
    "新增版本记录。发布新版本时调用。", ver_body, r["status"], r["body"],
    params_desc=[
        {"name": "app_id", "type": "string", "required": "是", "desc": "应用标识"},
        {"name": "platform", "type": "string", "required": "是", "desc": "平台"},
        {"name": "version", "type": "string", "required": "是", "desc": "版本号"},
        {"name": "download_url", "type": "string", "required": "是", "desc": "下载地址"},
        {"name": "file_size", "type": "int", "required": "否", "desc": "文件大小"},
        {"name": "sha256", "type": "string", "required": "否", "desc": "文件哈希"},
        {"name": "release_notes", "type": "string", "required": "否", "desc": "更新日志"},
        {"name": "force_update", "type": "bool", "required": "否", "desc": "是否强制更新"},
    ])


# ─── 6. 获取全部版本列表 ───

step(6, "GET /api/app/versions - 获取 test_app 全部版本")
r = Curl.get(f"{BASE}/api/app/versions?app_id=test_app")
if r["status"] != 200:
    fail(f"list versions failed: {r['status']} {r['body']}")
print(f"versions count: {len(r['data'])}")
ok()
write_doc("06_list_versions.md", "GET", "/api/app/versions?app_id=test_app",
    "获取某应用的全部版本记录（所有平台），按创建时间降序。", None, r["status"], r["body"],
    params_desc=[
        {"name": "app_id", "type": "string", "required": "是", "desc": "应用标识"},
    ])


# ─── 7. 查询单平台最新版本 ───

step(7, "GET /api/app/version - 查询最新版本")
r = Curl.get(f"{BASE}/api/app/version?app_id=test_app&platform=windows")
if r["status"] != 200:
    fail(f"get version failed: {r['status']} {r['body']}")
if r["data"]["version"] != "0.1.0":
    fail(f"unexpected version: {r['data']['version']}")
print(f"version: {r['data']['version']}")
ok()
write_doc("07_get_version.md", "GET", "/api/app/version?app_id=test_app&platform=windows",
    "查询指定应用在指定平台的最新版本。客户端启动时调用。", None, r["status"], r["body"],
    params_desc=[
        {"name": "app_id", "type": "string", "required": "是", "desc": "应用标识"},
        {"name": "platform", "type": "string", "required": "是", "desc": "平台标识"},
    ])


# ─── 8. 查询不存在的平台（404） ───

step(8, "GET /api/app/version - 查询不存在的平台（404）")
r = Curl.get(f"{BASE}/api/app/version?app_id=test_app&platform=ios")
if r["status"] != 404:
    fail(f"expected 404, got: {r['status']}")
print(f"response: {r['body']}")
ok()
write_doc("08_get_version_not_found.md", "GET", "/api/app/version?app_id=test_app&platform=ios",
    "查询不存在的版本记录，返回 404。", None, r["status"], r["body"],
    notes="该平台暂未发布任何版本")


# ─── 9. 更新版本信息 ───

step(9, "PUT /api/app/version - 更新版本信息")
update_body = json.dumps({"release_notes": "测试版本（已修正）", "force_update": True})
r = Curl.put(f"{BASE}/api/app/version?app_id=test_app&platform=windows&version=0.1.0", update_body)
if r["status"] != 200:
    fail(f"update failed: {r['status']} {r['body']}")
print(f"response: {r['body']}")
ok()
write_doc("09_update_version.md", "PUT", "/api/app/version?app_id=test_app&platform=windows&version=0.1.0",
    "更新已有版本的信息。", update_body, r["status"], r["body"],
    params_desc=[
        {"name": "app_id", "type": "string", "required": "是", "desc": "应用标识（query）"},
        {"name": "platform", "type": "string", "required": "是", "desc": "平台（query）"},
        {"name": "version", "type": "string", "required": "是", "desc": "版本号（query）"},
        {"name": "release_notes", "type": "string", "required": "否", "desc": "新更新日志（body）"},
        {"name": "force_update", "type": "bool", "required": "否", "desc": "新强制更新标记（body）"},
    ])


# ─── 10. 验证更新生效 ───

step(10, "GET /api/app/version - 验证更新生效")
r = Curl.get(f"{BASE}/api/app/version?app_id=test_app&platform=windows")
if r["status"] != 200:
    fail(f"query failed: {r['status']}")
if r["data"]["force_update"] != True:
    fail(f"force_update should be true")
if "修正" not in r["data"]["release_notes"]:
    fail(f"release_notes not updated")
print(f"force_update={r['data']['force_update']}, notes={r['data']['release_notes']}")
ok()
write_doc("10_verify_update.md", "GET", "/api/app/version?app_id=test_app&platform=windows",
    "验证版本信息已被正确更新。", None, r["status"], r["body"],
    notes="force_update 已变为 true，release_notes 已更新")


# ─── 结果汇总 ───

print(f"\n{GREEN}══════════════════════════════════════{RESET}")
print(f"{GREEN}  ALL PASSED: {passed}/{total}{RESET}")
print(f"{GREEN}══════════════════════════════════════{RESET}")

write_link()
print(f"\n文档已生成到: {DOCS_DIR}")
