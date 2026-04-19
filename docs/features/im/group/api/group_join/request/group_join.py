#!/usr/bin/env python3
"""
group v0.0.2 - 搜索加群与入群审批 API 测试链 + 文档生成器
用法: python docs/features/im/group/api/group_join/request/group_join.py

前置:
  1. python scripts/server/reset_db.py
  2. python scripts/server/start.py
  3. python scripts/server/im_seed/seed.py
  4. python scripts/server/im/send_friend_request.py 0001 0002-0005 --accept
  5. python scripts/server/im/create_group.py 0001 0002-0003 "开放群"
  6. python scripts/server/im/create_group.py 0001 0002-0003 "验证群"

注意: 步骤 5 创建的群默认 join_verification=false（开放群）
     步骤 6 创建的群需要手动设置 join_verification=true（验证群）
     脚本内部会自动处理这些前置条件
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
        "# group_join v0.0.2 - API test link",
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
    """直接执行 SQL（用于设置测试数据）"""
    cmd = ["psql.exe", "-U", "postgres", "-h", "127.0.0.1", "-p", "5432",
           "-d", "flash_im", "-w", "-t", "-A", "-c", sql]
    env = os.environ.copy()
    env["PGPASSWORD"] = "postgres"
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", env=env)
    return result.stdout.strip()


# ─── pre: 登录测试用户 + 创建测试群 ───

step("pre", "Login users + create test groups")
t1, uid1 = login("0001")  # 群主
t2, uid2 = login("0002")  # 成员
t3, uid3 = login("0003")  # 成员
t4, uid4 = login("0004")  # 非成员（将搜索加入）
t5, uid5 = login("0005")  # 非成员（将申请加入）
print(f"群主={uid1}, 成员2={uid2}, 成员3={uid3}, 搜索者={uid4}, 申请者={uid5}")

# 创建开放群（join_verification=false，默认）
j = json.dumps({"name": "开放群聊", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/groups", j, t1)
if r["status"] != 200: fail(f"create open group failed: {r['status']}")
open_group_id = r["data"]["id"]
print(f"开放群: {open_group_id}")

# 创建验证群（需要手动设置 join_verification=true）
j = json.dumps({"name": "验证群聊", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/groups", j, t1)
if r["status"] != 200: fail(f"create verify group failed: {r['status']}")
verify_group_id = r["data"]["id"]
print(f"验证群: {verify_group_id}")

# 设置验证群的 join_verification=true
psql(f"UPDATE group_info SET join_verification = true WHERE conversation_id = '{verify_group_id}'")
print("已设置验证群 join_verification=true")

# 查询开放群的 group_no
open_group_no = psql(f"SELECT group_no FROM group_info WHERE conversation_id = '{open_group_id}'")
print(f"开放群 group_no: {open_group_no}")
ok()


# === 1: 搜索群聊（按群名） ===
step(1, "GET /groups/search?keyword=开放 - search by name")
r = Curl.get(f"{BASE}/groups/search?keyword=开放", t4)
if r["status"] != 200: fail(f"search failed: {r['status']}")
print(f"results: {len(r['data'])}")
assert len(r["data"]) > 0
found = [g for g in r["data"] if g["id"] == open_group_id][0]
assert found["is_member"] == False
assert found["join_verification"] == False
assert found["has_pending_request"] == False
assert "group_no" in found
assert "member_count" in found
print(f"group_no={found['group_no']}, member_count={found['member_count']}, is_member={found['is_member']}")
ok()
write_doc("01_search_by_name.md", "GET", "/groups/search?keyword=开放",
    "按群名模糊搜索群聊。返回成员数、是否已加入、是否需验证、是否已申请。", None, r["status"], r["body"], t4,
    params_desc=[
        {"name": "keyword", "type": "string", "required": "是", "desc": "搜索关键词（≥2 字符，纯数字按群号精确匹配，否则按群名模糊搜索）"},
    ])

# === 2: 搜索群聊（按群号） ===
step(2, f"GET /groups/search?keyword={open_group_no} - search by group_no")
r = Curl.get(f"{BASE}/groups/search?keyword={open_group_no}", t4)
if r["status"] != 200: fail(f"search by no failed: {r['status']}")
print(f"results: {len(r['data'])}")
assert len(r["data"]) == 1
assert r["data"][0]["group_no"] == int(open_group_no)
ok()
write_doc("02_search_by_group_no.md", "GET", f"/groups/search?keyword={open_group_no}",
    "按群号精确搜索群聊。keyword 为纯数字时走群号匹配。", None, r["status"], r["body"], t4,
    "纯数字 keyword 按 group_no 精确匹配，非数字按群名 ILIKE 模糊搜索。")

# === 3: 单字搜索也能匹配 ===
step(3, "GET /groups/search?keyword=开 - single char search works")
r = Curl.get(f"{BASE}/groups/search?keyword=开", t4)
if r["status"] != 200: fail(f"search failed: {r['status']}")
print(f"results: {len(r['data'])}")
assert len(r["data"]) > 0
ok()
write_doc("03_search_single_char.md", "GET", "/groups/search?keyword=开",
    "单字搜索也能匹配群名。", None, r["status"], r["body"], t4,
    "不限制最小搜索字符数，输入即搜。")

# === 4: 已是成员搜索 → is_member=true ===
step(4, "GET /groups/search - member sees is_member=true")
r = Curl.get(f"{BASE}/groups/search?keyword=开放", t2)
if r["status"] != 200: fail(f"search failed: {r['status']}")
found = r["data"][0]
assert found["is_member"] == True
print(f"is_member={found['is_member']}")
ok()
write_doc("04_search_is_member.md", "GET", "/groups/search?keyword=开放",
    "已是群成员时搜索结果中 is_member=true。", None, r["status"], r["body"], t2,
    "前端根据 is_member 显示'已加入'灰色标签。")

# === 5: 入群（无需验证）→ auto_approved=true ===
step(5, "POST /groups/{id}/join - no verification, auto approve")
j = json.dumps({"message": "我想加入"})
r = Curl.post(f"{BASE}/groups/{open_group_id}/join", j, t4)
if r["status"] != 200: fail(f"join failed: {r['status']}")
assert r["data"]["auto_approved"] == True
print(f"auto_approved={r['data']['auto_approved']}")
ok()
write_doc("05_join_no_verify.md", "POST", f"/groups/{open_group_id}/join",
    "入群（无需验证）：直接加入成功，返回 auto_approved=true。自动刷新宫格头像并发送系统消息。", j, r["status"], r["body"], t4,
    params_desc=[
        {"name": "message", "type": "string", "required": "否", "desc": "申请留言（无需验证时忽略）"},
    ])

# === 6: 重复入群 → 400（已是成员） ===
step(6, "POST /groups/{id}/join - already member")
r = Curl.post(f"{BASE}/groups/{open_group_id}/join", j, t4)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("06_join_already_member.md", "POST", f"/groups/{open_group_id}/join",
    "已是群成员时再次入群返回 400。", j, r["status"], r["body"] or "(empty body)", t4,
    "已加入的用户不能重复加入。")

# === 7: 入群（需验证）→ auto_approved=false ===
step(7, "POST /groups/{id}/join - with verification, pending")
j = json.dumps({"message": "请让我加入验证群"})
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join", j, t5)
if r["status"] != 200: fail(f"join failed: {r['status']}")
assert r["data"]["auto_approved"] == False
print(f"auto_approved={r['data']['auto_approved']}")
ok()
write_doc("07_join_with_verify.md", "POST", f"/groups/{verify_group_id}/join",
    "入群（需验证）：创建入群申请，返回 auto_approved=false。WS 推送 GROUP_JOIN_REQUEST 帧给群主。", j, r["status"], r["body"], t5,
    params_desc=[
        {"name": "message", "type": "string", "required": "否", "desc": "申请留言"},
    ])

# === 8: 重复申请 → 400 ===
step(8, "POST /groups/{id}/join - duplicate request")
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join", j, t5)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("08_join_duplicate_request.md", "POST", f"/groups/{verify_group_id}/join",
    "已有待处理申请时再次申请返回 400。", j, r["status"], r["body"] or "(empty body)", t5,
    "同一用户对同一群只能有一条 status=0 的申请。")

# === 9: 搜索验证群 → has_pending_request=true ===
step(9, "GET /groups/search - has_pending_request=true")
r = Curl.get(f"{BASE}/groups/search?keyword=验证", t5)
if r["status"] != 200: fail(f"search failed: {r['status']}")
found = [g for g in r["data"] if g["id"] == verify_group_id]
assert len(found) == 1
assert found[0]["has_pending_request"] == True
print(f"has_pending_request={found[0]['has_pending_request']}")
ok()
write_doc("09_search_pending.md", "GET", "/groups/search?keyword=验证",
    "有待处理申请时搜索结果中 has_pending_request=true。", None, r["status"], r["body"], t5,
    "前端根据 has_pending_request 显示'已申请'灰色标签。")

# === 10: 群主查看入群申请列表 ===
step(10, "GET /groups/join-requests - owner lists requests")
r = Curl.get(f"{BASE}/groups/join-requests", t1)
if r["status"] != 200: fail(f"list failed: {r['status']}")
print(f"requests: {len(r['data'])}")
assert len(r["data"]) > 0
req = r["data"][0]
assert "nickname" in req
assert "group_name" in req
assert req["status"] == 0
request_id = req["id"]
print(f"request_id={request_id}, applicant={req['nickname']}, group={req['group_name']}")
ok()
write_doc("10_list_join_requests.md", "GET", "/groups/join-requests",
    "查询当前用户作为群主的所有入群申请。包含申请者信息和群名。", None, r["status"], r["body"], t1,
    "按 created_at DESC 排序，包含所有状态（0/1/2）。")

# === 11: 非群主审批 → 403 ===
step(11, "POST /groups/{id}/join-requests/{rid}/handle - non-owner forbidden")
j = json.dumps({"approved": True})
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join-requests/{request_id}/handle", j, t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("11_handle_non_owner.md", "POST", f"/groups/{verify_group_id}/join-requests/{request_id}/handle",
    "非群主审批返回 403。", j, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以处理入群申请。")

# === 12: 群主同意入群申请 ===
step(12, "POST /groups/{id}/join-requests/{rid}/handle - approve")
j = json.dumps({"approved": True})
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join-requests/{request_id}/handle", j, t1)
if r["status"] != 200: fail(f"approve failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("12_handle_approve.md", "POST", f"/groups/{verify_group_id}/join-requests/{request_id}/handle",
    "群主同意入群申请。申请者自动加入群聊，刷新宫格头像，发送系统消息。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "approved", "type": "bool", "required": "是", "desc": "true=同意, false=拒绝"},
    ])

# === 13: 重复审批 → 400 ===
step(13, "POST /groups/{id}/join-requests/{rid}/handle - already handled")
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join-requests/{request_id}/handle", j, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("13_handle_already_done.md", "POST", f"/groups/{verify_group_id}/join-requests/{request_id}/handle",
    "已处理的申请再次审批返回 400。", j, r["status"], r["body"] or "(empty body)", t1,
    "status != 0 的申请不能再次处理。")

# === 14: 验证申请者已加入（搜索 is_member=true） ===
step(14, "GET /groups/search - approved user is now member")
r = Curl.get(f"{BASE}/groups/search?keyword=验证", t5)
if r["status"] != 200: fail(f"search failed: {r['status']}")
found = [g for g in r["data"] if g["id"] == verify_group_id]
assert len(found) == 1
assert found[0]["is_member"] == True
assert found[0]["has_pending_request"] == False
print(f"is_member={found[0]['is_member']}, has_pending_request={found[0]['has_pending_request']}")
ok()
write_doc("14_verify_approved_member.md", "GET", "/groups/search?keyword=验证",
    "审批通过后，申请者搜索该群时 is_member=true，has_pending_request=false。", None, r["status"], r["body"], t5,
    "验证审批流程完整性：申请 → 审批通过 → 成为成员。")

# === 15: 群主拒绝入群申请（用 uid4 申请验证群，然后拒绝） ===
step(15, "POST /groups/{id}/join + handle reject")
# uid4 申请验证群
j_apply = json.dumps({"message": "我也想加入"})
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join", j_apply, t4)
if r["status"] != 200: fail(f"join failed: {r['status']}")
assert r["data"]["auto_approved"] == False

# 查询新申请的 ID
r = Curl.get(f"{BASE}/groups/join-requests", t1)
new_reqs = [rq for rq in r["data"] if rq["user_id"] == uid4 and rq["status"] == 0]
if not new_reqs: fail("new request not found")
new_request_id = new_reqs[0]["id"]

# 群主拒绝
j_reject = json.dumps({"approved": False})
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join-requests/{new_request_id}/handle", j_reject, t1)
if r["status"] != 200: fail(f"reject failed: {r['status']}")
assert r["data"]["success"] == True
print(f"rejected request_id={new_request_id}")
ok()
write_doc("15_handle_reject.md", "POST", f"/groups/{verify_group_id}/join-requests/{new_request_id}/handle",
    "群主拒绝入群申请。申请状态变为 2（已拒绝），申请者不加入群聊。", j_reject, r["status"], r["body"], t1,
    "拒绝后申请者可以重新申请。")

# === 16: 被拒绝后可重新申请 ===
step(16, "POST /groups/{id}/join - re-apply after rejection")
r = Curl.post(f"{BASE}/groups/{verify_group_id}/join", j_apply, t4)
if r["status"] != 200: fail(f"re-apply failed: {r['status']}")
assert r["data"]["auto_approved"] == False
print(f"re-apply auto_approved={r['data']['auto_approved']}")
ok()
write_doc("16_reapply_after_reject.md", "POST", f"/groups/{verify_group_id}/join",
    "被拒绝后可以重新申请入群。", j_apply, r["status"], r["body"], t4,
    "被拒绝的申请 status=2，不阻止新的 status=0 申请。")

# === 17: 群详情（群成员查看） ===
step(17, "GET /groups/{id}/detail - member views group detail")
r = Curl.get(f"{BASE}/groups/{open_group_id}/detail", t1)
if r["status"] != 200: fail(f"detail failed: {r['status']}")
d = r["data"]
assert d["name"] == "开放群聊"
assert "group_no" in d
assert "members" in d
assert len(d["members"]) > 0
assert "join_verification" in d
print(f"name={d['name']}, group_no={d['group_no']}, members={len(d['members'])}, join_verification={d['join_verification']}")
ok()
write_doc("17_group_detail.md", "GET", f"/groups/{open_group_id}/detail",
    "获取群详情：群信息 + 成员列表。当前用户必须是群成员。", None, r["status"], r["body"], t1,
    "返回群名、群号、群头像、成员数、入群验证开关、成员列表（user_id + nickname + avatar）。")

# === 18: 群详情（非成员 → 403） ===
step(18, "GET /groups/{id}/detail - non-member forbidden")
r = Curl.get(f"{BASE}/groups/{verify_group_id}/detail", t4)
# t4 对验证群有 pending 申请但不是成员
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("18_detail_non_member.md", "GET", f"/groups/{verify_group_id}/detail",
    "非群成员查看群详情返回 403。", None, r["status"], r["body"] or "(empty body)", t4,
    "只有群成员可以查看群详情。")

# === 19: 群主开启入群验证 ===
step(19, "PUT /groups/{id}/settings - owner enables join verification")
j = json.dumps({"join_verification": True})
r = Curl.request("PUT", f"{BASE}/groups/{open_group_id}/settings", j, t1)
if r["status"] != 200: fail(f"settings failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("19_settings_enable_verify.md", "PUT", f"/groups/{open_group_id}/settings",
    "群主开启入群验证。开启后新成员需要群主审批才能加入。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "join_verification", "type": "bool", "required": "否", "desc": "入群验证开关"},
    ])

# === 20: 验证开启后搜索结果 join_verification=true ===
step(20, "GET /groups/search - verify join_verification changed")
r = Curl.get(f"{BASE}/groups/search?keyword=开放", t5)
if r["status"] != 200: fail(f"search failed: {r['status']}")
found = [g for g in r["data"] if g["id"] == open_group_id]
assert len(found) == 1
assert found[0]["join_verification"] == True
print(f"join_verification={found[0]['join_verification']}")
ok()
write_doc("20_verify_setting_changed.md", "GET", "/groups/search?keyword=开放",
    "群主开启入群验证后，搜索结果中 join_verification=true。", None, r["status"], r["body"], t5,
    "验证群设置修改即时生效。")

# === 21: 群主关闭入群验证 ===
step(21, "PUT /groups/{id}/settings - owner disables join verification")
j = json.dumps({"join_verification": False})
r = Curl.request("PUT", f"{BASE}/groups/{open_group_id}/settings", j, t1)
if r["status"] != 200: fail(f"settings failed: {r['status']}")
print(f"success={r['data']['success']}")
ok()
write_doc("21_settings_disable_verify.md", "PUT", f"/groups/{open_group_id}/settings",
    "群主关闭入群验证。", j, r["status"], r["body"], t1)

# === 22: 非群主修改设置 → 403 ===
step(22, "PUT /groups/{id}/settings - non-owner forbidden")
j = json.dumps({"join_verification": True})
r = Curl.request("PUT", f"{BASE}/groups/{open_group_id}/settings", j, t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("22_settings_non_owner.md", "PUT", f"/groups/{open_group_id}/settings",
    "非群主修改群设置返回 403。", j, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以修改群设置。")


# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs → {os.path.relpath(DOCS_DIR)}{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
