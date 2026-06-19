#!/usr/bin/env python3
"""
cloud - 云空间 API 测试链 + 文档生成器
测试：文件列表 / 文件详情 / 文件删除

用法: python docs/features/cloud/v0.0.1/api/cloud/request/cloud.py
"""

import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import zlib

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

    @staticmethod
    def multipart(url, form_fields, token=None):
        cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", "POST", url]
        if token:
            cmd += ["-H", f"Authorization: Bearer {token}"]
        curl_str = f'curl -s -X POST "{url}"'
        if token:
            curl_str += f'\n  -H "Authorization: Bearer {token}"'
        for name, value in form_fields:
            if isinstance(value, tuple) and value[0].startswith("@"):
                cmd += ["-F", f"{name}={value[0]}"]
                curl_str += f'\n  -F "{name}={value[0]}"'
            else:
                cmd += ["-F", f"{name}={value}"]
                curl_str += f'\n  -F "{name}={value}"'
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
        return {"status": status, "body": body, "data": data, "curl": curl_str}


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


def write_doc(filename, method, path, desc, resp_status, resp_body, token,
              notes=None, params_desc=None, curl_override=None):
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
    lines += [f"## Response `{resp_status}`", "", "```json", resp_body or "(empty body)", "```", ""]
    if curl_override:
        curl = curl_override
    else:
        curl = f'curl -s -X {method} "{BASE}{path}"'
        if token:
            curl += f'\n  -H "Authorization: Bearer {token}"'
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
        "# cloud - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── 工具 ───

def sha1_file(filepath):
    h = hashlib.sha1()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def create_test_png(path):
    width, height = 2, 2
    def make_chunk(chunk_type, data):
        raw = chunk_type + data
        return struct.pack('>I', len(data)) + raw + struct.pack('>I', zlib.crc32(raw) & 0xffffffff)
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    raw_rows = b'\x00\xff\x00\x00\x00\xff\x00' * height
    idat = make_chunk(b'IDAT', zlib.compress(raw_rows))
    iend = make_chunk(b'IEND', b'')
    with open(path, "wb") as f:
        f.write(b'\x89PNG\r\n\x1a\n' + ihdr + idat + iend)


# ─── pre: 登录 ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    if r["status"] != 200:
        fail(f"sms failed: {r['status']}")
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]["token"], r["data"]["user_id"]


print(f"{YELLOW}>>> pre: login user A{RESET}")
token_a, uid_a = login(PHONE_A)
print(f"  uid={uid_a}")

# 上传一些测试文件
tmp_dir = tempfile.mkdtemp()
test_img = os.path.join(tmp_dir, "cloud_test.png")
test_file = os.path.join(tmp_dir, "cloud_test.txt")
create_test_png(test_img)
with open(test_file, "w") as f:
    f.write("cloud space test file content\n" * 5)

img_hash = sha1_file(test_img)
file_hash = sha1_file(test_file)

print(f"{YELLOW}>>> pre: upload test files{RESET}")
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_img}",)), ("hash", img_hash),
], token=token_a)
if r["status"] != 200:
    fail(f"upload img: {r['status']} {r['body']}")
uploaded_img_id = r["data"]["file_id"]
print(f"  image file_id={uploaded_img_id}")

r = Curl.multipart(f"{BASE}/api/upload/file", [
    ("file", (f"@{test_file}",)), ("hash", file_hash),
], token=token_a)
if r["status"] != 200:
    fail(f"upload file: {r['status']} {r['body']}")
uploaded_file_id = r["data"]["file_id"]
print(f"  file file_id={uploaded_file_id}")


# ─── 测试步骤 ───

# Step 1: 文件列表（全部）
step(1, "GET /api/storage/files - list all")
r = Curl.get(f"{BASE}/api/storage/files", token=token_a)
print(f"  status={r['status']}, total={r['data'].get('total') if r['data'] else 'N/A'}")
if r["status"] != 200:
    fail(f"list failed: {r['status']} {r['body']}")
if "data" not in r["data"] or "total" not in r["data"]:
    fail("missing data or total")
print(f"  items={len(r['data']['data'])}, total={r['data']['total']}")
ok()
write_doc("01_list_all.md", "GET", "/api/storage/files",
    "查询用户的所有文件列表（分页）。", r["status"], r["body"], token_a,
    params_desc=[
        {"name": "category", "type": "string", "required": "否", "desc": "image/video/audio/file"},
        {"name": "page", "type": "int", "required": "否", "desc": "页码，默认 1"},
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
    ])

# Step 2: 文件列表（按类型筛选）
step(2, "GET /api/storage/files?category=image - filter by image")
r = Curl.get(f"{BASE}/api/storage/files?category=image", token=token_a)
print(f"  status={r['status']}, count={len(r['data']['data']) if r['data'] else 0}")
if r["status"] != 200:
    fail(f"filter failed: {r['status']}")
# 验证返回的都是 image 类型
for item in r["data"]["data"]:
    if item["mime_category"] != "image":
        fail(f"expected image, got {item['mime_category']}")
ok()
write_doc("02_list_by_category.md", "GET", "/api/storage/files?category=image",
    "按类型筛选文件列表。", r["status"], r["body"], token_a,
    notes="返回的所有项 mime_category 均为 image。")

# Step 3: 文件详情
step(3, f"GET /api/storage/files/{uploaded_img_id} - file detail")
r = Curl.get(f"{BASE}/api/storage/files/{uploaded_img_id}", token=token_a)
print(f"  status={r['status']}")
if r["status"] != 200:
    fail(f"detail failed: {r['status']} {r['body']}")
if "file" not in r["data"]:
    fail("missing 'file' in response")
if "conversations" not in r["data"]:
    fail("missing 'conversations' in response")
print(f"  file.id={r['data']['file']['id']}, convs={len(r['data']['conversations'])}")
ok()
write_doc("03_file_detail.md", "GET", f"/api/storage/files/{uploaded_img_id}",
    "查询文件详情，含引用的会话列表。", r["status"], r["body"], token_a)

# Step 4: 文件详情 - 不存在（404）
step(4, "GET /api/storage/files/99999 - not found")
r = Curl.get(f"{BASE}/api/storage/files/99999", token=token_a)
print(f"  status={r['status']}")
if r["status"] != 404:
    fail(f"expected 404, got {r['status']}")
ok()
write_doc("04_detail_not_found.md", "GET", "/api/storage/files/99999",
    "查询不存在的文件，返回 404。", r["status"], r["body"], token_a,
    notes="文件不存在或不属于当前用户时返回 404。")

# Step 5: 删除文件
step(5, f"DELETE /api/storage/files/{uploaded_file_id} - delete file")
r = Curl.delete(f"{BASE}/api/storage/files/{uploaded_file_id}", token=token_a)
print(f"  status={r['status']}, body={r['body'][:200]}")
if r["status"] != 200:
    fail(f"delete failed: {r['status']} {r['body']}")
if "freed_bytes" not in r["data"]:
    fail("missing freed_bytes")
print(f"  freed={r['data']['freed_bytes']}, new_used={r['data']['new_used_bytes']}")
ok()
write_doc("05_delete_file.md", "DELETE", f"/api/storage/files/{uploaded_file_id}",
    "删除文件。ref_count 归零时物理删除并回收配额。", r["status"], r["body"], token_a)

# Step 6: 删除后验证不在列表中
step(6, "GET /api/storage/files - verify deleted file gone")
r = Curl.get(f"{BASE}/api/storage/files?category=file", token=token_a)
if r["status"] != 200:
    fail(f"list failed: {r['status']}")
ids = [item["id"] for item in r["data"]["data"]]
if uploaded_file_id in ids:
    fail(f"file_id={uploaded_file_id} should not be in list after delete")
print(f"  file_id={uploaded_file_id} not in list (correct)")
ok()
write_doc("06_verify_deleted.md", "GET", "/api/storage/files?category=file",
    "验证已删除的文件不再出现在列表中。", r["status"], r["body"], token_a,
    notes="删除后文件从列表消失。")

# Step 7: 删除不存在的文件（404）
step(7, "DELETE /api/storage/files/99999 - delete not found")
r = Curl.delete(f"{BASE}/api/storage/files/99999", token=token_a)
print(f"  status={r['status']}")
if r["status"] != 404:
    fail(f"expected 404, got {r['status']}")
ok()
write_doc("07_delete_not_found.md", "DELETE", "/api/storage/files/99999",
    "删除不存在的文件，返回 404。", r["status"], r["body"], token_a,
    notes="文件不存在时返回 404。")


# ─── cleanup ───

import shutil
shutil.rmtree(tmp_dir, ignore_errors=True)

write_link()
print(f"\n{GREEN}{'='*50}{RESET}")
print(f"{GREEN}  ALL DONE: {passed}/{total} steps passed{RESET}")
print(f"{GREEN}{'='*50}{RESET}")
print(f"  docs at: {DOCS_DIR}")
