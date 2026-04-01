#!/usr/bin/env python3
"""
conversation_message - API test link + doc generator
Usage: python docs/features/im/core/api/message/conversation_message.py
"""

import json
import os
import subprocess
import sys

BASE = "http://127.0.0.1:9600"
PHONE_A = "13800010001"
PHONE_B = "13800010002"
PASSWORD = "111111"

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DOCS_DIR = os.path.join(SCRIPT_DIR, "..", "doc")
os.makedirs(DOCS_DIR, exist_ok=True)

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"

link_lines = []
passed = 0
total = 0

def step(n, desc):
    print(f"{CYAN}========== [{n}] {desc} =========={RESET}")

def fail(m):
    print(f"{RED}[FAIL] {m}{RESET}")
    sys.exit(1)

def ok():
    global passed
    passed += 1
    print(f"{GREEN}[PASS]{RESET}")

def curl(method, url, json_body=None, token=None):
    cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", method, url]
    if token:
        cmd += ["-H", f"Authorization: Bearer {token}"]
    if json_body:
        cmd += ["-H", "Content-Type: application/json", "-d", json_body]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    lines = result.stdout.rsplit("\n", 1)
    body = lines[0] if len(lines) > 1 else ""
    status = int(lines[-1]) if lines[-1].isdigit() else 0
    data = json.loads(body) if body.strip() else None
    return {"status": status, "body": body, "data": data}

def write_doc(filename, method, path, desc, param_json, resp_status, resp_body, token, notes=None, params_desc=None):
    global total
    total += 1
    lines = [f"# {method} {path}", "", desc, ""]
    if params_desc:
        lines += ["## Parameters", "", "| Parameter | Type | Required | Description |", "|-----------|------|----------|-------------|"]
        for p in params_desc:
            lines.append(f"| {p['name']} | {p['type']} | {p['required']} | {p['desc']} |")
        lines += [""]
    if param_json:
        lines += ["```json", param_json, "```", ""]
    lines += [f"## Response `{resp_status}`", "", "```json", resp_body or "(empty body)", "```", ""]
    curl_str = f'curl -s -X {method} "{BASE}{path}"'
    if token:
        curl_str += f'\n  -H "Authorization: Bearer {token}"'
    if param_json:
        curl_str += f'\n  -H "Content-Type: application/json"\n  -d \'{param_json}\''
    lines += ["## curl", "", "```bash", curl_str, "```"]
    if notes:
        lines += ["", f"> {notes}"]
    filepath = os.path.join(DOCS_DIR, filename)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    icon = "PASS" if resp_status < 400 or notes else "FAIL"
    num = filename.split("_")[0].lstrip("0")
    link_lines.append(f"| {num} | `{method} {path}` | `{resp_status}` | {icon} | [{filename}]({filename}) |")

def write_link():
    header = ["# conversation_message - API test link", "", f"Base URL: `{BASE}`", "",
              "| # | Interface | Status | Result | Doc |", "|---|-----------|--------|--------|-----|"]
    filepath = os.path.join(DOCS_DIR, "00_link.md")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(header + link_lines))

def login(phone):
    r = curl("POST", f"{BASE}/auth/login", json.dumps({"phone": phone, "type": "password", "credential": PASSWORD}))
    if not r["data"] or not r["data"].get("token"):
        fail(f"login failed for {phone}")
    return r["data"]["token"], r["data"]["user_id"]

# ─── pre ───
step("pre", "Login + get conversation")
token_a, uid_a = login(PHONE_A)
token_b, uid_b = login(PHONE_B)
r = curl("POST", f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token=token_a)
conv_id = r["data"]["id"]
print(f"A={uid_a}, B={uid_b}, conv={conv_id}")
ok()

# === 1: Get messages (latest) ===
step(1, "GET /conversations/:id/messages - latest")
r = curl("GET", f"{BASE}/conversations/{conv_id}/messages", token=token_a)
if r["status"] != 200:
    fail(f"get messages failed: {r['status']}")
messages = r["data"] if r["data"] else []
print(f"messages: {len(messages)}")
ok()
write_doc("01_get_latest.md", "GET", f"/conversations/{conv_id}/messages",
    "Get latest messages for a conversation.", None, r["status"], r["body"], token_a)

# === 2: Get messages with before_seq ===
step(2, "GET /conversations/:id/messages?before_seq=N - pagination")
if messages:
    max_seq = max(m["seq"] for m in messages)
    url = f"{BASE}/conversations/{conv_id}/messages?before_seq={max_seq}"
    r = curl("GET", url, token=token_a)
    if r["status"] != 200:
        fail(f"pagination failed: {r['status']}")
    page = r["data"] if r["data"] else []
    print(f"before_seq={max_seq}, got {len(page)} messages")
    ok()
    path_str = f"/conversations/{conv_id}/messages?before_seq={max_seq}"
    write_doc("02_get_before_seq.md", "GET", path_str,
        "Get messages before a specific sequence number.", None, r["status"], r["body"], token_a,
        params_desc=[
            {"name": "before_seq", "type": "int", "required": "no", "desc": "Get messages with seq < this value"},
            {"name": "limit", "type": "int", "required": "no", "desc": "Max messages to return (default 50, max 100)"},
        ])
else:
    print("no messages to paginate, skipping")
    ok()

# === 3: Get messages with before_seq=1 (empty) ===
step(3, "GET /conversations/:id/messages?before_seq=1 - empty")
r = curl("GET", f"{BASE}/conversations/{conv_id}/messages?before_seq=1", token=token_a)
if r["status"] != 200:
    fail(f"empty query failed: {r['status']}")
empty = r["data"] if r["data"] else []
if len(empty) != 0:
    fail(f"expected 0, got {len(empty)}")
print("empty result (before_seq=1)")
ok()
write_doc("03_get_empty.md", "GET", f"/conversations/{conv_id}/messages?before_seq=1",
    "Get messages before seq=1. Returns empty array.", None, r["status"], r["body"], token_a)

# === Write link ===
write_link()

print(f"\n{YELLOW}Generated: 00_link.md + {total} api docs{RESET}")
print(f"\n{GREEN}{'=' * 40}")
print(f"  ALL {passed} STEPS PASSED")
print(f"{'=' * 40}{RESET}")
