#!/usr/bin/env python3
"""
storage - API 测试链 + 文档生成器
测试：文件上传（去重 + 配额）+ 配额查询

用法: python docs/features/im/core/v0.0.6_file_system/api/storage/request/storage.py
"""

import hashlib
import json
import os
import subprocess
import sys
import tempfile

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
    def multipart(url, form_fields, token=None):
        """
        multipart/form-data 上传
        form_fields: list of tuples:
          ("field_name", "value")            → -F "field_name=value"
          ("field_name", ("@filepath",))     → -F "field_name=@filepath"
        """
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
        "# storage - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


# ─── 工具函数 ───

def sha1_file(filepath):
    """计算文件 SHA-1 hex"""
    h = hashlib.sha1()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def create_test_image(path, size_kb=50):
    """创建一个最小有效 PNG（1x1 红色像素）"""
    import struct, zlib
    # 手工构造合法 1x1 RGB PNG
    width, height = 1, 1

    def make_chunk(chunk_type, data):
        raw = chunk_type + data
        return struct.pack('>I', len(data)) + raw + struct.pack('>I', zlib.crc32(raw) & 0xffffffff)

    # IHDR: 1x1, 8bit, RGB(2), no filter/interlace
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)

    # IDAT: filter byte(0) + R G B
    raw_row = b'\x00\xff\x00\x00'  # filter=None, pixel=(255,0,0)
    compressed = zlib.compress(raw_row)
    idat = make_chunk(b'IDAT', compressed)

    # IEND
    iend = make_chunk(b'IEND', b'')

    with open(path, "wb") as f:
        f.write(b'\x89PNG\r\n\x1a\n')  # PNG signature
        f.write(ihdr)
        f.write(idat)
        f.write(iend)


def create_test_file(path, content=b"hello world test file content\n", repeat=1):
    """创建一个测试文件"""
    with open(path, "wb") as f:
        for _ in range(repeat):
            f.write(content)


# ─── pre: 登录获取 token ───

def login(phone):
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    if r["status"] != 200:
        fail(f"send sms failed: {r['status']}")
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]["token"], r["data"]["user_id"]


print(f"{YELLOW}>>> 前置：登录用户 A{RESET}")
token_a, uid_a = login(PHONE_A)
print(f"  user_id={uid_a}, token={token_a[:20]}...")


# ─── 测试步骤 ───

# 创建临时测试文件
tmp_dir = tempfile.mkdtemp()
test_image_path = os.path.join(tmp_dir, "test.png")
test_file_path = os.path.join(tmp_dir, "test.txt")

# 用真实的小 PNG 文件（1x1 pixel）
create_test_image(test_image_path, size_kb=1)
create_test_file(test_file_path, b"hello storage test\n", repeat=10)

image_hash = sha1_file(test_image_path)
file_hash = sha1_file(test_file_path)
print(f"  image hash: {image_hash}")
print(f"  file hash:  {file_hash}")


# ─── Step 1: 上传图片（正常） ───

step(1, "POST /api/upload/image - 正常上传")
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_image_path}",)),
    ("hash", image_hash),
], token=token_a)
print(f"  status={r['status']}, body={r['body'][:200]}")
if r["status"] != 200:
    fail(f"upload image failed: {r['status']} {r['body']}")
if not r["data"].get("file_id"):
    fail("missing file_id in response")
if r["data"].get("is_dedup") is not False:
    fail("first upload should not be dedup")
file_id_image = r["data"]["file_id"]
print(f"  file_id={file_id_image}, is_dedup={r['data']['is_dedup']}")
ok()
write_doc("01_upload_image.md", "POST", "/api/upload/image",
    "上传图片文件。支持 jpg/png/gif/webp，最大 10MB。", r["status"], r["body"], token_a,
    params_desc=[
        {"name": "file", "type": "file", "required": "是", "desc": "图片文件（multipart）"},
        {"name": "hash", "type": "string", "required": "是", "desc": "文件 SHA-1 hex（40字符）"},
    ],
    curl_override=r["curl"])


# ─── Step 2: 重复上传同一图片（秒传） ───

step(2, "POST /api/upload/image - 秒传（相同 hash）")
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_image_path}",)),
    ("hash", image_hash),
], token=token_a)
print(f"  status={r['status']}, is_dedup={r['data'].get('is_dedup')}")
if r["status"] != 200:
    fail(f"dedup upload failed: {r['status']}")
if r["data"].get("is_dedup") is not True:
    fail("second upload should be dedup=true")
if r["data"]["file_id"] != file_id_image:
    fail("dedup should return same file_id")
ok()
write_doc("02_upload_image_dedup.md", "POST", "/api/upload/image",
    "重复上传相同文件（秒传）。服务端检测到相同 hash，不重复存储，直接返回已有记录。",
    r["status"], r["body"], token_a,
    notes="is_dedup=true 表示秒传，未写入新文件。",
    curl_override=r["curl"])


# ─── Step 3: 上传文件（正常） ───

step(3, "POST /api/upload/file - 正常上传")
r = Curl.multipart(f"{BASE}/api/upload/file", [
    ("file", (f"@{test_file_path}",)),
    ("hash", file_hash),
], token=token_a)
print(f"  status={r['status']}, body={r['body'][:200]}")
if r["status"] != 200:
    fail(f"upload file failed: {r['status']} {r['body']}")
if not r["data"].get("file_id"):
    fail("missing file_id")
print(f"  file_id={r['data']['file_id']}, file_type={r['data'].get('file_type')}")
ok()
write_doc("03_upload_file.md", "POST", "/api/upload/file",
    "上传通用文件。最大 50MB。", r["status"], r["body"], token_a,
    params_desc=[
        {"name": "file", "type": "file", "required": "是", "desc": "文件（multipart）"},
        {"name": "hash", "type": "string", "required": "是", "desc": "文件 SHA-1 hex"},
    ],
    curl_override=r["curl"])


# ─── Step 4: 查询配额 ───

step(4, "GET /api/storage/quota - 查询配额")
r = Curl.get(f"{BASE}/api/storage/quota", token=token_a)
print(f"  status={r['status']}, body={r['body'][:300]}")
if r["status"] != 200:
    fail(f"get quota failed: {r['status']}")
if "used_bytes" not in r["data"]:
    fail("missing used_bytes")
if "quota_bytes" not in r["data"]:
    fail("missing quota_bytes")
if "breakdown" not in r["data"]:
    fail("missing breakdown")
print(f"  used={r['data']['used_bytes']}, quota={r['data']['quota_bytes']}")
print(f"  breakdown={json.dumps(r['data']['breakdown'], indent=2)}")
ok()
write_doc("04_get_quota.md", "GET", "/api/storage/quota",
    "查询当前用户的云空间配额和分类用量。", r["status"], r["body"], token_a,
    params_desc=[])


# ─── Step 5: 缺少 hash 字段（400） ───

step(5, "POST /api/upload/image - 缺少 hash（400）")
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_image_path}",)),
], token=token_a)
print(f"  status={r['status']}")
if r["status"] != 400:
    fail(f"expected 400, got {r['status']}")
ok()
write_doc("05_upload_no_hash.md", "POST", "/api/upload/image",
    "上传图片但缺少 hash 字段。返回 400。",
    r["status"], r["body"], token_a,
    notes="缺少 hash 字段时返回 400 BAD_REQUEST。",
    curl_override=r["curl"])


# ─── Step 6: 未登录上传（401） ───

step(6, "POST /api/upload/image - 未登录（401）")
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_image_path}",)),
    ("hash", image_hash),
], token=None)
print(f"  status={r['status']}")
if r["status"] != 401:
    fail(f"expected 401, got {r['status']}")
ok()
write_doc("06_upload_unauthorized.md", "POST", "/api/upload/image",
    "未登录时上传文件。返回 401。",
    r["status"], r["body"], None,
    notes="未携带 Authorization header 时返回 401。",
    curl_override=r["curl"])


# ─── Step 7: 不支持的文件类型（400） ───

step(7, "POST /api/upload/image - 不支持的类型（400）")
bad_file = os.path.join(tmp_dir, "test.bmp")
create_test_file(bad_file, b"BM fake bmp data\n")
bad_hash = sha1_file(bad_file)
r = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{bad_file}",)),
    ("hash", bad_hash),
], token=token_a)
print(f"  status={r['status']}")
if r["status"] != 400:
    fail(f"expected 400, got {r['status']}")
ok()
write_doc("07_upload_unsupported_type.md", "POST", "/api/upload/image",
    "上传不支持的图片格式（如 .bmp）。返回 400。",
    r["status"], r["body"], token_a,
    notes="图片只支持 jpg/png/gif/webp。",
    curl_override=r["curl"])



# --- IM messaging full-chain tests ---

PHONE_B = "13800010002"
print(f"\n{YELLOW}>>> pre: login B + create conversation{RESET}")
token_b, uid_b = login(PHONE_B)
print(f"  user_b id={uid_b}")

r = Curl.post(f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token=token_a)
if r["status"] != 200:
    fail(f"create conv failed: {r['status']}")
conv_id = r["data"]["id"]
print(f"  conv_id={conv_id}")


# --- Step 8: send image message ---

step(8, "POST /conversations/{id}/messages - send IMAGE")
r_up = Curl.multipart(f"{BASE}/api/upload/image", [
    ("file", (f"@{test_image_path}",)),
    ("hash", image_hash),
], token=token_a)
img_url = r_up["data"]["original_url"]
msg_body = json.dumps({"content": img_url, "msg_type": 1, "extra": None})
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", msg_body, token=token_a)
print(f"  status={r['status']}, type={r['data'].get('msg_type')}")
if r["status"] != 200: fail(f"send IMAGE failed: {r['status']}")
ok()
write_doc("08_send_image_msg.md", "POST", f"/conversations/{conv_id}/messages",
    "发送图片消息。content=图片 URL，msg_type=1（IMAGE）。",
    r["status"], r["body"], token_a,
    params_desc=[
        {"name": "content", "type": "string", "required": "是", "desc": "图片 URL"},
        {"name": "msg_type", "type": "int", "required": "是", "desc": "1=IMAGE"},
    ])


# --- Step 9: send video message ---

step(9, "POST /conversations/{id}/messages - send VIDEO")
test_video = os.path.join(tmp_dir, "test.mp4")
create_test_file(test_video, b"\x00" * 128)
v_hash = sha1_file(test_video)
test_vthumb = os.path.join(tmp_dir, "vthumb.jpg")
create_test_file(test_vthumb, b"\xff" * 64)

r_up = Curl.multipart(f"{BASE}/api/upload/video", [
    ("video", (f"@{test_video}",)),
    ("thumbnail", (f"@{test_vthumb}",)),
    ("hash", v_hash),
    ("duration_ms", "15000"),
    ("width", "1280"),
    ("height", "720"),
], token=token_a)
if r_up["status"] != 200: fail(f"upload video failed: {r_up['status']} {r_up['body']}")

v_extra = {"thumbnail_url": r_up["data"]["thumbnail_url"], "duration_ms": 15000, "width": 1280, "height": 720, "file_size": r_up["data"]["file_size"]}
msg_body = json.dumps({"content": r_up["data"]["video_url"], "msg_type": 2, "extra": v_extra})
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", msg_body, token=token_a)
print(f"  status={r['status']}, type={r['data'].get('msg_type')}")
if r["status"] != 200: fail(f"send VIDEO failed: {r['status']}")
ok()
write_doc("09_send_video_msg.md", "POST", f"/conversations/{conv_id}/messages",
    "发送视频消息。content=视频 URL，extra 含缩略图/时长/宽高，msg_type=2（VIDEO）。",
    r["status"], r["body"], token_a,
    params_desc=[
        {"name": "content", "type": "string", "required": "是", "desc": "视频 URL"},
        {"name": "msg_type", "type": "int", "required": "是", "desc": "2=VIDEO"},
        {"name": "extra", "type": "json", "required": "是", "desc": "视频元数据"},
    ])


# --- Step 10: send file message ---

step(10, "POST /conversations/{id}/messages - send FILE")
r_up = Curl.multipart(f"{BASE}/api/upload/file", [
    ("file", (f"@{test_file_path}",)),
    ("hash", file_hash),
], token=token_a)
f_url = r_up["data"]["file_url"]
f_extra = {"file_name": "test.txt", "file_size": r_up["data"]["file_size"], "file_url": f_url, "file_type": "txt"}
msg_body = json.dumps({"content": f_url, "msg_type": 3, "extra": f_extra})
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", msg_body, token=token_a)
print(f"  status={r['status']}, type={r['data'].get('msg_type')}")
if r["status"] != 200: fail(f"send FILE failed: {r['status']}")
ok()
write_doc("10_send_file_msg.md", "POST", f"/conversations/{conv_id}/messages",
    "发送文件消息。content=文件 URL，extra 含文件名/大小/类型，msg_type=3（FILE）。",
    r["status"], r["body"], token_a,
    params_desc=[
        {"name": "content", "type": "string", "required": "是", "desc": "文件 URL"},
        {"name": "msg_type", "type": "int", "required": "是", "desc": "3=FILE"},
        {"name": "extra", "type": "json", "required": "是", "desc": "文件元数据"},
    ])


# --- Step 11: send audio message ---

step(11, "POST /conversations/{id}/messages - send AUDIO")
test_audio = os.path.join(tmp_dir, "test.m4a")
create_test_file(test_audio, b"\x00" * 96)
a_hash = sha1_file(test_audio)
r_up = Curl.multipart(f"{BASE}/api/upload/file", [
    ("file", (f"@{test_audio}",)),
    ("hash", a_hash),
], token=token_a)
if r_up["status"] != 200: fail(f"upload audio failed: {r_up['status']}")

a_extra = {"duration_ms": 5200}
msg_body = json.dumps({"content": r_up["data"]["file_url"], "msg_type": 4, "extra": a_extra})
r = Curl.post(f"{BASE}/conversations/{conv_id}/messages", msg_body, token=token_a)
print(f"  status={r['status']}, type={r['data'].get('msg_type')}")
if r["status"] != 200: fail(f"send AUDIO failed: {r['status']}")
ok()
write_doc("11_send_audio_msg.md", "POST", f"/conversations/{conv_id}/messages",
    "发送语音消息。content=音频 URL，extra 含时长，msg_type=4（AUDIO）。",
    r["status"], r["body"], token_a,
    params_desc=[
        {"name": "content", "type": "string", "required": "是", "desc": "音频 URL"},
        {"name": "msg_type", "type": "int", "required": "是", "desc": "4=AUDIO"},
        {"name": "extra", "type": "json", "required": "是", "desc": "音频元数据"},
    ])


# --- Step 12: verify history has all types ---

step(12, "GET /conversations/{id}/messages - verify all media types")
r = Curl.get(f"{BASE}/conversations/{conv_id}/messages?limit=10", token=token_a)
if r["status"] != 200: fail(f"get messages failed: {r['status']}")
msgs = r["data"]
types_found = set(m.get("msg_type", 0) for m in msgs)
print(f"  count={len(msgs)}, types={types_found}")
for t in [1, 2, 3, 4]:
    if t not in types_found: fail(f"missing msg_type={t}")
ok()
write_doc("12_verify_history.md", "GET", f"/conversations/{conv_id}/messages",
    "查询消息历史，验证图片/视频/文件/语音四种类型消息都已正确存储。",
    r["status"], r["body"], token_a,
    notes="消息列表应包含 msg_type=1(IMAGE), 2(VIDEO), 3(FILE), 4(AUDIO)。")


# --- Step 13: quota after all sends ---

step(13, "GET /api/storage/quota - quota after sends")
r = Curl.get(f"{BASE}/api/storage/quota", token=token_a)
if r["status"] != 200: fail(f"quota failed: {r['status']}")
print(f"  used={r['data']['used_bytes']}, breakdown={r['data']['breakdown']}")
if r["data"]["used_bytes"] <= 0: fail("used_bytes should be > 0")
ok()
write_doc("13_quota_after_sends.md", "GET", "/api/storage/quota",
    "发送多种媒体消息后查询配额，验证用量正确增长。",
    r["status"], r["body"], token_a,
    notes="used_bytes 应大于 0，breakdown 包含各类型文件用量。")


# --- cleanup ---

import shutil
shutil.rmtree(tmp_dir, ignore_errors=True)
write_link()
print(f"\n{GREEN}{'='*50}{RESET}")
print(f"{GREEN}  ALL DONE: {passed}/{total} steps passed{RESET}")
print(f"{GREEN}{'='*50}{RESET}")
print(f"  docs at: {DOCS_DIR}")
