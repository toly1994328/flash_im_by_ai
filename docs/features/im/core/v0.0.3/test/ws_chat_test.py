#!/usr/bin/env python3
"""
WebSocket 消息收发全链路测试
用法: python scripts/test/ws_chat_test.py
依赖: pip install websockets protobuf
前置: 后端已启动，数据库已重置+种子数据已导入
"""

import asyncio
import json
import subprocess
import sys
import os

# 添加 proto 目录到 path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "proto"))

import ws_pb2 as ws
import message_pb2 as msg

BASE = "http://127.0.0.1:9600"
WS_URL = "ws://127.0.0.1:9600/ws/im"
PHONE_A = "13800010001"  # 朱红
PHONE_B = "13800010002"  # 橘橙
PASSWORD = "111111"

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"

def step(n, desc):
    print(f"{CYAN}========== [{n}] {desc} =========={RESET}")

def fail(m):
    print(f"{RED}[FAIL] {m}{RESET}")
    sys.exit(1)

def ok():
    print(f"{GREEN}[PASS]{RESET}")

# ─── HTTP 工具 ───

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

def login(phone):
    r = curl("POST", f"{BASE}/auth/login", json.dumps({
        "phone": phone, "type": "password", "credential": PASSWORD
    }))
    if not r["data"] or not r["data"].get("token"):
        fail(f"login failed for {phone}: {r['body']}")
    return r["data"]["token"], r["data"]["user_id"]

# ─── Protobuf 帧工具 ───

def make_frame(frame_type, payload_bytes):
    frame = ws.WsFrame()
    frame.type = frame_type
    frame.payload = payload_bytes
    return frame.SerializeToString()

def parse_frame(data):
    frame = ws.WsFrame()
    frame.ParseFromString(data)
    return frame

def make_auth_frame(token):
    auth = ws.AuthRequest()
    auth.token = token
    return make_frame(ws.AUTH, auth.SerializeToString())

def make_chat_frame(conversation_id, content):
    req = msg.SendMessageRequest()
    req.conversation_id = conversation_id
    req.type = msg.TEXT
    req.content = content
    return make_frame(ws.CHAT_MESSAGE, req.SerializeToString())

# ─── 主测试 ───

async def main():
    import websockets

    # pre: 登录
    step("pre", "Login users")
    token_a, uid_a = login(PHONE_A)
    token_b, uid_b = login(PHONE_B)
    print(f"User A: id={uid_a}, User B: id={uid_b}")

    # 确保朱红和橘橙之间有会话（幂等创建）
    r = curl("POST", f"{BASE}/conversations", json.dumps({"peer_user_id": uid_b}), token=token_a)
    if r["status"] != 200:
        fail(f"create conversation failed: {r['status']}")
    conv_id = r["data"]["id"]
    print(f"conversation_id: {conv_id} (between A and B)")
    ok()

    # 1: 建立 WebSocket 连接
    step(1, "Connect WebSocket")
    ws_a = await websockets.connect(WS_URL)
    ws_b = await websockets.connect(WS_URL)
    print("both connected")
    ok()

    # 2: 认证
    step(2, "Authenticate")
    await ws_a.send(make_auth_frame(token_a))
    await ws_b.send(make_auth_frame(token_b))

    # 读取 AUTH_RESULT
    frame_a = parse_frame(await ws_a.recv())
    frame_b = parse_frame(await ws_b.recv())
    result_a = ws.AuthResult()
    result_a.ParseFromString(frame_a.payload)
    result_b = ws.AuthResult()
    result_b.ParseFromString(frame_b.payload)
    if not result_a.success or not result_b.success:
        fail(f"auth failed: A={result_a.success}, B={result_b.success}")
    print(f"A auth: {result_a.message}, B auth: {result_b.message}")
    ok()

    # 3: A 发送消息
    step(3, "A sends CHAT_MESSAGE")
    await ws_a.send(make_chat_frame(conv_id, "hello from A"))
    print("sent: hello from A")
    ok()

    # 4: A 收到 MESSAGE_ACK
    step(4, "A receives MESSAGE_ACK")
    ack_received = False
    first_seq = None
    # A 可能收到 ACK 和 CONVERSATION_UPDATE，顺序不定
    for _ in range(3):
        try:
            data = await asyncio.wait_for(ws_a.recv(), timeout=5)
            frame = parse_frame(data)
            if frame.type == ws.MESSAGE_ACK:
                ack = msg.MessageAck()
                ack.ParseFromString(frame.payload)
                first_seq = ack.seq
                print(f"ACK: message_id={ack.message_id}, seq={ack.seq}")
                ack_received = True
                break
        except asyncio.TimeoutError:
            break
    if not ack_received:
        fail("no MESSAGE_ACK received")
    ok()

    # 5: B 收到 CHAT_MESSAGE
    step(5, "B receives CHAT_MESSAGE")
    chat_received = False
    for _ in range(3):
        try:
            data = await asyncio.wait_for(ws_b.recv(), timeout=5)
            frame = parse_frame(data)
            if frame.type == ws.CHAT_MESSAGE:
                chat = msg.ChatMessage()
                chat.ParseFromString(frame.payload)
                print(f"ChatMessage: seq={chat.seq}, content={chat.content}")
                if chat.content != "hello from A":
                    fail(f"wrong content: {chat.content}")
                chat_received = True
                break
        except asyncio.TimeoutError:
            break
    if not chat_received:
        fail("no CHAT_MESSAGE received by B")
    ok()

    # 6: 双方收到 CONVERSATION_UPDATE
    step(6, "Both receive CONVERSATION_UPDATE")
    # 收集剩余帧
    updates = {"A": None, "B": None}
    for label, ws_conn in [("A", ws_a), ("B", ws_b)]:
        for _ in range(3):
            try:
                data = await asyncio.wait_for(ws_conn.recv(), timeout=3)
                frame = parse_frame(data)
                if frame.type == ws.CONVERSATION_UPDATE:
                    update = msg.ConversationUpdate()
                    update.ParseFromString(frame.payload)
                    updates[label] = update
                    print(f"{label}: preview={update.last_message_preview}, unread={update.unread_count}")
                    break
            except asyncio.TimeoutError:
                break
    if updates["A"] is None:
        print(f"{YELLOW}[WARN] A did not receive CONVERSATION_UPDATE{RESET}")
    if updates["B"] is None:
        print(f"{YELLOW}[WARN] B did not receive CONVERSATION_UPDATE{RESET}")
    ok()

    # 7: HTTP 查询历史消息
    step(7, "GET /conversations/:id/messages")
    r = curl("GET", f"{BASE}/conversations/{conv_id}/messages", token=token_a)
    if r["status"] != 200:
        fail(f"get messages failed: {r['status']}")
    messages = r["data"]
    print(f"messages count: {len(messages)}")
    if len(messages) < 1:
        fail("no messages found")
    if messages[0]["content"] != "hello from A":
        fail(f"wrong content: {messages[0]['content']}")
    print(f"seq={messages[0]['seq']}, content={messages[0]['content']}")
    ok()

    # 8: A 再发一条，验证 seq 递增
    step(8, "A sends second message, verify seq increments")
    await ws_a.send(make_chat_frame(conv_id, "second message"))
    for _ in range(3):
        try:
            data = await asyncio.wait_for(ws_a.recv(), timeout=5)
            frame = parse_frame(data)
            if frame.type == ws.MESSAGE_ACK:
                ack2 = msg.MessageAck()
                ack2.ParseFromString(frame.payload)
                print(f"ACK: seq={ack2.seq}")
                if ack2.seq != first_seq + 1:
                    fail(f"expected seq={first_seq + 1}, got {ack2.seq}")
                break
        except asyncio.TimeoutError:
            fail("no ACK for second message")
    ok()

    # 清理
    await ws_a.close()
    await ws_b.close()

    print(f"\n{GREEN}{'=' * 40}")
    print(f"  ALL STEPS PASSED")
    print(f"{'=' * 40}{RESET}")

if __name__ == "__main__":
    asyncio.run(main())
