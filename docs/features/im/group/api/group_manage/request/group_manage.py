#!/usr/bin/env python3
"""
group v0.0.3 - 群成员管理 API 测试链 + 文档生成器
用法: python docs/features/im/group/api/group_manage/request/group_manage.py

前置:
  1. python scripts/server/reset_db.py
  2. python scripts/server/start.py
  3. python scripts/server/im_seed/seed.py
  4. python scripts/server/im/send_friend_request.py 0001 0002-0005 --accept
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
        "# group_manage v0.0.3 - API test link",
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

step("pre", "Login users + create test group")
t1, uid1 = login("0001")  # 群主
t2, uid2 = login("0002")  # 成员
t3, uid3 = login("0003")  # 成员
t4, uid4 = login("0004")  # 非成员（将被邀请）
t5, uid5 = login("0005")  # 非成员（将被邀请）
print(f"群主={uid1}, 成员2={uid2}, 成员3={uid3}, 待邀请4={uid4}, 待邀请5={uid5}")

# 创建测试群（uid1 群主，uid2+uid3 成员）
j = json.dumps({"name": "管理测试群", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/groups", j, t1)
if r["status"] != 200: fail(f"create group failed: {r['status']}")
group_id = r["data"]["id"]
print(f"测试群: {group_id}")
ok()


# ═══════════════════════════════════════════
#  邀请入群
# ═══════════════════════════════════════════

# === 1: 邀请 uid4 和 uid5 入群 ===
step(1, "POST /groups/{id}/members - invite uid4 and uid5")
j = json.dumps({"member_ids": [uid4, uid5]})
r = Curl.post(f"{BASE}/groups/{group_id}/members", j, t1)
if r["status"] != 200: fail(f"invite failed: {r['status']} {r['body']}")
assert r["data"]["success"] == True
assert r["data"]["added_count"] == 2
print(f"added_count={r['data']['added_count']}")
ok()
write_doc("01_invite_members.md", "POST", f"/groups/{group_id}/members",
    "邀请新成员入群。群成员可邀请，直接加入不走审批。刷新宫格头像 + 发送系统消息。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "member_ids", "type": "array<i64>", "required": "是", "desc": "要邀请的用户 ID 列表"},
    ])

# === 2: 非成员邀请 → 403 ===
step(2, "POST /groups/{id}/members - non-member invites → 403")
# 登录一个不在群里的新用户
t6, uid6 = login("0006")
j = json.dumps({"member_ids": [uid6]})
r = Curl.post(f"{BASE}/groups/{group_id}/members", j, t6)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("02_invite_non_member.md", "POST", f"/groups/{group_id}/members",
    "非群成员邀请他人入群返回 403。", j, r["status"], r["body"] or "(empty body)", t6,
    "只有群成员才能邀请新成员。")

# === 3: 验证新成员出现在成员列表 ===
step(3, "GET /groups/{id}/detail - verify new members in list")
r = Curl.get(f"{BASE}/groups/{group_id}/detail", t1)
if r["status"] != 200: fail(f"detail failed: {r['status']}")
member_ids = [m["user_id"] for m in r["data"]["members"]]
assert uid4 in member_ids, f"uid4={uid4} not in members"
assert uid5 in member_ids, f"uid5={uid5} not in members"
print(f"members={len(r['data']['members'])}, uid4 ✓, uid5 ✓")
ok()
write_doc("03_verify_invite.md", "GET", f"/groups/{group_id}/detail",
    "验证邀请入群后，新成员出现在群详情的成员列表中。", None, r["status"], r["body"], t1,
    "邀请成功后 member_count 应增加，成员列表包含新成员。")


# ═══════════════════════════════════════════
#  踢人
# ═══════════════════════════════════════════

# === 4: 群主踢 uid5 ===
step(4, "DELETE /groups/{id}/members/{uid5} - owner kicks uid5")
r = Curl.delete(f"{BASE}/groups/{group_id}/members/{uid5}", t1)
if r["status"] != 200: fail(f"kick failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("04_kick_member.md", "DELETE", f"/groups/{group_id}/members/{uid5}",
    "群主踢人。被踢成员的 is_deleted 标记为 true，刷新宫格头像 + 发送系统消息。", None, r["status"], r["body"], t1,
    "只有群主可以踢人。")

# === 5: 非群主踢人 → 403 ===
step(5, "DELETE /groups/{id}/members/{uid5} - non-owner kicks → 403")
r = Curl.delete(f"{BASE}/groups/{group_id}/members/{uid5}", t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("05_kick_non_owner.md", "DELETE", f"/groups/{group_id}/members/{uid5}",
    "非群主踢人返回 403。", None, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以踢人。")

# === 6: 群主踢自己 → 400 ===
step(6, "DELETE /groups/{id}/members/{uid1} - owner kicks self → 400")
r = Curl.delete(f"{BASE}/groups/{group_id}/members/{uid1}", t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("06_kick_self.md", "DELETE", f"/groups/{group_id}/members/{uid1}",
    "群主不能踢自己，返回 400。群主需要先转让或解散群聊。", None, r["status"], r["body"] or "(empty body)", t1,
    "群主不能踢自己，避免群变成无主状态。")


# ═══════════════════════════════════════════
#  退群
# ═══════════════════════════════════════════

# === 7: uid4 退群 ===
step(7, "POST /groups/{id}/leave - uid4 leaves")
r = Curl.post(f"{BASE}/groups/{group_id}/leave", None, t4)
if r["status"] != 200: fail(f"leave failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("07_leave_group.md", "POST", f"/groups/{group_id}/leave",
    "普通成员退出群聊。退出后 is_deleted=true，刷新宫格头像 + 发送系统消息。", None, r["status"], r["body"], t4,
    "退群后可被重新邀请（ON CONFLICT 恢复 is_deleted=false）。")

# === 8: 群主退群 → 400 ===
step(8, "POST /groups/{id}/leave - owner leaves → 400")
r = Curl.post(f"{BASE}/groups/{group_id}/leave", None, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("08_leave_owner.md", "POST", f"/groups/{group_id}/leave",
    "群主不能退群，返回 400。群主必须先转让或解散。", None, r["status"], r["body"] or "(empty body)", t1,
    "群主不能退群，避免群变成无主状态。")


# ═══════════════════════════════════════════
#  转让群主
# ═══════════════════════════════════════════

# === 9: 群主转让给 uid2 ===
step(9, "PUT /groups/{id}/transfer - transfer to uid2")
j = json.dumps({"new_owner_id": uid2})
r = Curl.put(f"{BASE}/groups/{group_id}/transfer", j, t1)
if r["status"] != 200: fail(f"transfer failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("09_transfer_owner.md", "PUT", f"/groups/{group_id}/transfer",
    "群主转让。owner_id 更新为新群主，发送系统消息。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "new_owner_id", "type": "i64", "required": "是", "desc": "新群主的 user_id（必须是群成员）"},
    ])

# === 10: 非群主转让 → 403（uid1 已不是群主） ===
step(10, "PUT /groups/{id}/transfer - non-owner transfers → 403")
j = json.dumps({"new_owner_id": uid3})
r = Curl.put(f"{BASE}/groups/{group_id}/transfer", j, t1)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("10_transfer_non_owner.md", "PUT", f"/groups/{group_id}/transfer",
    "非群主转让返回 403。uid1 已不是群主，无权转让。", j, r["status"], r["body"] or "(empty body)", t1,
    "只有当前群主可以转让。")

# === 11: 验证 owner_id 已变更为 uid2 ===
step(11, "GET /groups/{id}/detail - verify owner changed to uid2")
r = Curl.get(f"{BASE}/groups/{group_id}/detail", t2)
if r["status"] != 200: fail(f"detail failed: {r['status']}")
assert r["data"]["owner_id"] == uid2, f"expected owner_id={uid2}, got {r['data']['owner_id']}"
print(f"owner_id={r['data']['owner_id']} (uid2={uid2}) ✓")
ok()
write_doc("11_verify_transfer.md", "GET", f"/groups/{group_id}/detail",
    "验证转让后 owner_id 已变更为 uid2。", None, r["status"], r["body"], t2,
    "转让成功后群详情中 owner_id 应为新群主。")


# ═══════════════════════════════════════════
#  转让回来（为后续测试恢复 uid1 为群主）
# ═══════════════════════════════════════════

# === 12: uid2 转让回 uid1 ===
step(12, "PUT /groups/{id}/transfer - uid2 transfers back to uid1")
j = json.dumps({"new_owner_id": uid1})
r = Curl.put(f"{BASE}/groups/{group_id}/transfer", j, t2)
if r["status"] != 200: fail(f"transfer back failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}, owner restored to uid1")
ok()
write_doc("12_transfer_back.md", "PUT", f"/groups/{group_id}/transfer",
    "uid2 转让回 uid1，恢复原群主以便后续测试。", j, r["status"], r["body"], t2,
    "转让是双向的，新群主可以再次转让。")


# ═══════════════════════════════════════════
#  群公告
# ═══════════════════════════════════════════

# === 13: 群主发布公告 ===
step(13, "PUT /groups/{id}/announcement - owner publishes")
j = json.dumps({"announcement": "本周六下午两点线下聚会"})
r = Curl.put(f"{BASE}/groups/{group_id}/announcement", j, t1)
if r["status"] != 200: fail(f"announcement failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("13_announcement.md", "PUT", f"/groups/{group_id}/announcement",
    "群主发布/编辑群公告。更新 group_info 的 announcement 字段。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "announcement", "type": "string", "required": "是", "desc": "群公告内容"},
    ])

# === 14: 非群主发布公告 → 403 ===
step(14, "PUT /groups/{id}/announcement - non-owner → 403")
j = json.dumps({"announcement": "我不是群主"})
r = Curl.put(f"{BASE}/groups/{group_id}/announcement", j, t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("14_announcement_non_owner.md", "PUT", f"/groups/{group_id}/announcement",
    "非群主发布公告返回 403。", j, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以发布/编辑群公告。")

# === 15: 验证公告字段 ===
step(15, "GET /groups/{id}/detail - verify announcement")
r = Curl.get(f"{BASE}/groups/{group_id}/detail", t1)
if r["status"] != 200: fail(f"detail failed: {r['status']}")
assert r["data"]["announcement"] == "本周六下午两点线下聚会"
print(f"announcement={r['data']['announcement']} ✓")
ok()
write_doc("15_verify_announcement.md", "GET", f"/groups/{group_id}/detail",
    "验证群公告已更新到群详情中。", None, r["status"], r["body"], t1,
    "群详情返回 announcement、announcement_updated_at、announcement_updated_by 字段。")


# ═══════════════════════════════════════════
#  修改群信息
# ═══════════════════════════════════════════

# === 16: 群主修改群名 ===
step(16, "PUT /groups/{id} - owner changes group name")
j = json.dumps({"name": "新群名-管理测试"})
r = Curl.put(f"{BASE}/groups/{group_id}", j, t1)
if r["status"] != 200: fail(f"update failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("16_update_name.md", "PUT", f"/groups/{group_id}",
    "群主修改群名。", j, r["status"], r["body"], t1,
    params_desc=[
        {"name": "name", "type": "string", "required": "否", "desc": "新群名"},
        {"name": "avatar", "type": "string", "required": "否", "desc": "新群头像 URL"},
    ])

# === 17: 空群名 → 400 ===
step(17, "PUT /groups/{id} - empty name → 400")
j = json.dumps({"name": ""})
r = Curl.put(f"{BASE}/groups/{group_id}", j, t1)
if r["status"] != 400: fail(f"expected 400, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("17_update_empty_name.md", "PUT", f"/groups/{group_id}",
    "群名为空返回 400。", j, r["status"], r["body"] or "(empty body)", t1,
    "群名不能为空字符串。")

# === 18: 非群主修改 → 403 ===
step(18, "PUT /groups/{id} - non-owner changes → 403")
j = json.dumps({"name": "我不是群主"})
r = Curl.put(f"{BASE}/groups/{group_id}", j, t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("18_update_non_owner.md", "PUT", f"/groups/{group_id}",
    "非群主修改群信息返回 403。", j, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以修改群名/头像。")


# ═══════════════════════════════════════════
#  解散群聊
# ═══════════════════════════════════════════

# === 19: 创建第二个群用于解散测试 ===
step(19, "Create second group for disband test")
j = json.dumps({"name": "待解散群", "member_ids": [uid2, uid3]})
r = Curl.post(f"{BASE}/groups", j, t1)
if r["status"] != 200: fail(f"create group2 failed: {r['status']}")
group_id2 = r["data"]["id"]
print(f"待解散群: {group_id2}")
ok()
write_doc("19_create_disband_group.md", "POST", "/groups",
    "创建第二个群用于解散测试，避免破坏主测试群。", j, r["status"], r["body"], t1,
    "解散操作不可逆（status=1），需要独立的群来测试。")

# === 20: 非群主解散 → 403 ===
step(20, "POST /groups/{id2}/disband - non-owner → 403")
r = Curl.post(f"{BASE}/groups/{group_id2}/disband", None, t2)
if r["status"] != 403: fail(f"expected 403, got {r['status']}")
print(f"HTTP {r['status']}")
ok()
write_doc("20_disband_non_owner.md", "POST", f"/groups/{group_id2}/disband",
    "非群主解散群聊返回 403。", None, r["status"], r["body"] or "(empty body)", t2,
    "只有群主可以解散群聊。")

# === 21: 群主解散群聊 ===
step(21, "POST /groups/{id2}/disband - owner disbands")
r = Curl.post(f"{BASE}/groups/{group_id2}/disband", None, t1)
if r["status"] != 200: fail(f"disband failed: {r['status']}")
assert r["data"]["success"] == True
print(f"success={r['data']['success']}")
ok()
write_doc("21_disband.md", "POST", f"/groups/{group_id2}/disband",
    "群主解散群聊。先发系统消息'群聊已解散'，再标记 status=1。不删除成员和消息。", None, r["status"], r["body"], t1,
    "解散顺序：先发系统消息（成员关系还在）→ 再 UPDATE status=1。")

# === 22: 验证已解散群 status=1 ===
step(22, "GET /groups/{id2}/detail - verify status=1")
r = Curl.get(f"{BASE}/groups/{group_id2}/detail", t1)
if r["status"] != 200: fail(f"detail failed: {r['status']}")
assert r["data"]["status"] == 1, f"expected status=1, got {r['data'].get('status')}"
print(f"status={r['data']['status']} ✓ (已解散)")
# 公告等字段仍可访问
if "announcement" in r["data"]:
    print(f"announcement still accessible ✓")
ok()
write_doc("22_verify_disband.md", "GET", f"/groups/{group_id2}/detail",
    "验证已解散群的 status=1。解散后成员和消息不删除，历史数据仍可查看。WS 发消息会被 MessageService.send 拦截。",
    None, r["status"], r["body"], t1,
    "status=1 表示已解散。前端检测 status 禁用输入框，后端 MessageService.send 拦截已解散群的消息。")


# === 生成 00_link.md ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs → {os.path.relpath(DOCS_DIR)}{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed}/{passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
