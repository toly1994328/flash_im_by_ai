#!/usr/bin/env python3
"""
group - API 测试链 + 文档生成器
用法: python docs/features/im/group/api/group/request/group.py

前置:
  1. python scripts/server/reset_db.py
  2. python scripts/server/start.py
  3. python scripts/server/im_seed/seed.py
  4. python scripts/server/im/send_friend_request.py 0001 0002-0006 --accept
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_PREFIX = "1380001"

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
        "# group - API test link",
        "", f"Base URL: `{BASE}`", "",
        "| # | Interface | Status | Result | Doc |",
        "|---|-----------|--------|--------|-----|",
    ]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))


def login(suffix):
    phone = f"{PHONE_PREFIX}{suffix}"
    r = Curl.post(f"{BASE}/auth/sms", json.dumps({"phone": phone}))
    code = r["data"]["code"]
    r = Curl.post(f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "sms", "credential": code
    }))
    if not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]["token"], r["data"]["user_id"]


def psql(sql):
    """执行 SQL（用于测试中修改 group_info 等）"""
    env = os.environ.copy()
    env["PGPASSWORD"] = "postgres"
    env["PGCLIENTENCODING"] = "UTF8"
    psql_bin = "psql.exe" if sys.platform == "win32" else "psql"
    subprocess.run(
        [psql_bin, "-U", "postgres", "-h", "127.0.0.1", "-d", "flash_im", "-c", sql],
        capture_output=True, env=env
    )


# ─── pre: 登录测试用户 ───

step("pre", "Login test users (0001~0006)")
t1, uid1 = login("0001")  # 朱红 — 群主
t2, uid2 = login("0002")  # 橘橙
t3, uid3 = login("0003")  # 藤黄
t4, uid4 = login("0004")  # 碧螺春绿
t5, uid5 = login("0005")  # 天蓝
t6, uid6 = login("0006")  # 景泰蓝（入群测试用）
print(f"朱红={uid1}, 橘橙={uid2}, 藤黄={uid3}, 碧螺春绿={uid4}, 天蓝={uid5}, 景泰蓝={uid6}")
ok()

# === 1: 创建群聊 ===
step(1, "POST /conversations - create group")
j = json.dumps({"type": "group", "name": "测试群聊", "member_ids": [uid2, uid3, uid4]})
r = Curl.post(f"{BASE}/conversations", j, t1)
if r["status"] != 200: fail(f"create group failed: {r['status']}")
group_id = r["data"]["id"]
print(f"group_id: {group_id}, name: {r['data']['name']}, avatar: {r['data'].get('avatar', '')[:30]}...")
assert r["data"]["conv_type"] == 1
assert r["data"]["name"] == "测试群聊"
assert str(r["data"].get("avatar", "")).startswith("grid:")
assert str(r["data"].get("owner_id")) == str(uid1)
ok()
write_doc("01_create_group.md", "POST", "/conversations",
    "创建群聊会话。群主自动加入，自动生成宫格头像，自动初始化 group_info。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "type", "type": "string", "required": "是", "desc": '"group"'},
        {"name": "name", "type": "string", "required": "是", "desc": "群名称"},
        {"name": "member_ids", "type": "int[]", "required": "是", "desc": "成员 ID 列表（不含群主，至少 2 人）"},
    ])

# === 2: 群名为空 → 400 ===
step(2, "POST /conversations - empty group name")
j2 = json.dumps({"type": "group", "name": "", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/conversations", j2, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("02_create_group_empty_name.md", "POST", "/conversations",
    "群名为空时返回 400。", j2, r["status"], r["body"] or "(empty body)", t1,
    "群名 trim 后为空即拒绝。")

# === 3: 成员不足 → 400 ===
step(3, "POST /conversations - not enough members")
j3 = json.dumps({"type": "group", "name": "太少了", "member_ids": [uid2]})
r = Curl.post(f"{BASE}/conversations", j3, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("03_create_group_too_few.md", "POST", "/conversations",
    "成员不足时返回 400（加上群主至少 3 人）。", j3, r["status"], r["body"] or "(empty body)", t1,
    "member_ids 去重后加群主不足 3 人时拒绝。")

# === 4: 单聊不受影响 ===
step(4, "POST /conversations - private still works")
j4 = json.dumps({"type": "private", "peer_user_id": uid5})
r = Curl.post(f"{BASE}/conversations", j4, t1)
if r["status"] != 200: fail(f"private create failed: {r['status']}")
print(f"conv_type: {r['data']['conv_type']}")
assert r["data"]["conv_type"] == 0
ok()
write_doc("04_create_private.md", "POST", "/conversations",
    "单聊创建不受群聊扩展影响。", j4, r["status"], r["body"], t1,
    params_desc=[
        {"name": "type", "type": "string", "required": "否", "desc": '"private"（默认值）'},
        {"name": "peer_user_id", "type": "int", "required": "是", "desc": "对方用户 ID"},
    ])

# === 5: 旧格式兼容 ===
step(5, "POST /conversations - legacy format (no type field)")
j5 = json.dumps({"peer_user_id": uid2})
r = Curl.post(f"{BASE}/conversations", j5, t1)
if r["status"] != 200: fail(f"legacy create failed: {r['status']}")
print(f"conv_type: {r['data']['conv_type']}")
assert r["data"]["conv_type"] == 0
ok()
write_doc("05_create_legacy.md", "POST", "/conversations",
    "旧格式兼容：不传 type 字段时默认为 private。", j5, r["status"], r["body"], t1,
    "type 字段 serde default 为 \"private\"，兼容旧客户端。")

# === 6: 会话列表包含群聊 ===
step(6, "GET /conversations - list includes group")
r = Curl.get(f"{BASE}/conversations", t1)
if r["status"] != 200: fail(f"list failed: {r['status']}")
group_convs = [c for c in r["data"] if c.get("conv_type") == 1]
print(f"total: {len(r['data'])}, groups: {len(group_convs)}")
assert len(group_convs) > 0
g = group_convs[0]
assert g.get("name") is not None
assert g.get("avatar") is not None
ok()
write_doc("06_list_with_group.md", "GET", "/conversations",
    "会话列表包含群聊，群聊显示群名和宫格头像。", None, r["status"], r["body"], t1,
    "群聊的 name 来自 conversations.name，avatar 来自 conversations.avatar（grid: 格式）。")

# === 7: 搜索群聊 ===
step(7, "GET /conversations/search - search groups")
r = Curl.get(f"{BASE}/conversations/search?keyword=测试", t1)
if r["status"] != 200: fail(f"search failed: {r['status']}")
print(f"results: {len(r['data'])}")
assert len(r["data"]) > 0
result = r["data"][0]
assert "member_count" in result
assert "is_member" in result
assert "join_verification" in result
assert result["is_member"] == True  # 群主是成员
ok()
write_doc("07_search_groups.md", "GET", "/conversations/search",
    "按群名模糊搜索群聊，返回成员数、是否已加入、是否需要入群验证。", None, r["status"], r["body"], t1,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（群名模糊匹配）"},
        {"name": "limit", "type": "int", "required": "否", "desc": "返回条数，默认 20"},
    ])

# === 8: 非成员搜索 ===
step(8, "GET /conversations/search - non-member sees is_member=false")
r = Curl.get(f"{BASE}/conversations/search?keyword=测试", t6)
if r["status"] != 200: fail(f"search failed: {r['status']}")
assert len(r["data"]) > 0
assert r["data"][0]["is_member"] == False
print(f"is_member: {r['data'][0]['is_member']}")
ok()
write_doc("08_search_non_member.md", "GET", "/conversations/search",
    "非成员搜索同一群聊，is_member=false。", None, r["status"], r["body"], t6,
    "用于前端判断显示「加入」还是「已加入」按钮。")

# === 9: 空关键词 ===
step(9, "GET /conversations/search - empty keyword")
r = Curl.get(f"{BASE}/conversations/search?keyword=", t1)
if r["status"] != 200: fail(f"search failed: {r['status']}")
assert len(r["data"]) == 0
print(f"results: {len(r['data'])}")
ok()
write_doc("09_search_empty.md", "GET", "/conversations/search",
    "空关键词返回空列表。", None, r["status"], r["body"], t1,
    "防止无意义的全表扫描。")

# === 10: 入群（无需验证，默认） ===
step(10, "POST /conversations/{id}/join - auto approved (no verification)")
j10 = json.dumps({"message": "我想加入"})
r = Curl.post(f"{BASE}/conversations/{group_id}/join", j10, t5)
if r["status"] != 200: fail(f"join failed: {r['status']}")
assert r["data"]["auto_approved"] == True
print(f"auto_approved: {r['data']['auto_approved']}")
ok()
write_doc("10_join_auto.md", "POST", f"/conversations/{group_id}/join",
    "入群申请（无需验证时直接加入）。group_info.join_verification 默认 false。", j10, r["status"], r["body"], t5,
    params_desc=[
        {"name": "message", "type": "string", "required": "否", "desc": "申请留言"},
    ])

# === 11: 已是成员再申请 → 400 ===
step(11, "POST /conversations/{id}/join - already member")
r = Curl.post(f"{BASE}/conversations/{group_id}/join", json.dumps({}), t5)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("11_join_already_member.md", "POST", f"/conversations/{group_id}/join",
    "已是群成员时返回 400。", "{}", r["status"], r["body"] or "(empty body)", t5,
    "防止重复加入。")

# === 12: 开启入群验证 + 申请 ===
step(12, "POST /conversations/{id}/join - needs verification")
psql(f"UPDATE group_info SET join_verification = true WHERE conversation_id = '{group_id}';")
j12 = json.dumps({"message": "请让我加入"})
r = Curl.post(f"{BASE}/conversations/{group_id}/join", j12, t6)
if r["status"] != 200: fail(f"join failed: {r['status']}")
assert r["data"]["auto_approved"] == False
assert r["data"]["owner_id"] is not None
assert r["data"]["group_name"] is not None
print(f"auto_approved: {r['data']['auto_approved']}, owner: {r['data']['owner_id']}, group: {r['data']['group_name']}")
ok()
write_doc("12_join_verification.md", "POST", f"/conversations/{group_id}/join",
    "入群申请（需验证时创建申请记录，WS 通知群主）。", j12, r["status"], r["body"], t6,
    "group_info.join_verification=true 时，不直接加入，而是创建 group_join_requests 记录。")

# === 13: 重复申请 → 400 ===
step(13, "POST /conversations/{id}/join - duplicate request")
r = Curl.post(f"{BASE}/conversations/{group_id}/join", json.dumps({}), t6)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("13_join_duplicate.md", "POST", f"/conversations/{group_id}/join",
    "已有待处理申请时返回 400。", "{}", r["status"], r["body"] or "(empty body)", t6,
    "同一用户对同一群只能有一条 pending 申请。")

# === 14: 群主通知查询 ===
step(14, "GET /conversations/my-join-requests - owner's pending requests")
r = Curl.get(f"{BASE}/conversations/my-join-requests", t1)
if r["status"] != 200: fail(f"get requests failed: {r['status']}")
assert len(r["data"]) > 0
req = r["data"][0]
assert "nickname" in req
assert "group_name" in req
assert req["status"] == 0
request_id = req["id"]
print(f"pending: {len(r['data'])}, first: {req['nickname']} → {req['group_name']}")
ok()
write_doc("14_my_join_requests.md", "GET", "/conversations/my-join-requests",
    "查询当前用户作为群主的所有待处理入群申请（跨群聚合）。", None, r["status"], r["body"], t1,
    params_desc=[
        {"name": "limit", "type": "int", "required": "否", "desc": "每页条数，默认 20"},
        {"name": "offset", "type": "int", "required": "否", "desc": "偏移量，默认 0"},
    ])

# === 15: 非群主查询 → 空列表 ===
step(15, "GET /conversations/my-join-requests - non-owner gets empty")
r = Curl.get(f"{BASE}/conversations/my-join-requests", t2)
if r["status"] != 200: fail(f"get requests failed: {r['status']}")
assert len(r["data"]) == 0
print(f"pending: {len(r['data'])}")
ok()
write_doc("15_my_join_requests_empty.md", "GET", "/conversations/my-join-requests",
    "非群主查询返回空列表。", None, r["status"], r["body"], t2,
    "只返回当前用户作为 owner_id 的群的待处理申请。")

# === 16: 非群主审批 → 403 ===
step(16, f"POST /conversations/{{id}}/join-requests/{{rid}}/handle - non-owner forbidden")
r = Curl.post(
    f"{BASE}/conversations/{group_id}/join-requests/{request_id}/handle",
    json.dumps({"approved": True}), t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("16_handle_forbidden.md", "POST",
    f"/conversations/{group_id}/join-requests/{request_id}/handle",
    "非群主处理入群申请返回 403。", json.dumps({"approved": True}), r["status"], r["body"] or "(empty body)", t2,
    "只有 conversations.owner_id 可以审批。")

# === 17: 群主同意 ===
step(17, f"POST /conversations/{{id}}/join-requests/{{rid}}/handle - approve")
j17 = json.dumps({"approved": True})
r = Curl.post(
    f"{BASE}/conversations/{group_id}/join-requests/{request_id}/handle", j17, t1)
if r["status"] != 200: fail(f"approve failed: {r['status']}")
print("approved")
ok()
write_doc("17_handle_approve.md", "POST",
    f"/conversations/{group_id}/join-requests/{request_id}/handle",
    "群主同意入群申请。副作用：申请者加入群聊 + 刷新宫格头像。", j17, r["status"], r["body"], t1,
    params_desc=[
        {"name": "approved", "type": "bool", "required": "是", "desc": "true=同意, false=拒绝"},
    ])

# === 18: 验证申请者已加入 ===
step(18, "GET /conversations/search - verify applicant joined")
r = Curl.get(f"{BASE}/conversations/search?keyword=测试", t6)
if r["status"] != 200: fail(f"search failed: {r['status']}")
assert len(r["data"]) > 0
assert r["data"][0]["is_member"] == True
print(f"is_member: {r['data'][0]['is_member']}")
ok()
write_doc("18_verify_joined.md", "GET", "/conversations/search",
    "审批通过后，申请者搜索该群时 is_member=true。", None, r["status"], r["body"], t6,
    "验证 handle_join_request 的 add_member 副作用。")

# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs → {os.path.relpath(DOCS_DIR)}{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
