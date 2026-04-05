#!/usr/bin/env python3
"""
发送一条消息
用法: python send_message.py --from 6 --to 1 --msg "来自 python 脚本的消息"

参数:
  --from  发送者用户 ID
  --to    接收者用户 ID（用于查找/创建会话）
  --msg   消息内容
  --base  服务端地址（默认 http://127.0.0.1:9600）
  --ws    WebSocket 地址（默认 ws://127.0.0.1:9600/ws/im）
"""

import argparse
import asyncio
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "proto"))

import ws_pb2 as ws
import message_pb2 as msg

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
    return {"status": status, "data": data}

def login_by_id(base, user_id):
    """通过用户 ID 推算手机号登录（种子数据规则：1380001xxxx）"""
    phone = f"138000{10000 + user_id}"
    r = curl("POST", f"{base}/auth/login", json.dumps({
        "phone": phone, "type": "password", "credential": "111111"
    }))
    if not r["data"] or not r["data"].get("token"):
        print(f"登录失败: user_id={user_id}, phone={phone}")
        sys.exit(1)
    return r["data"]["token"]

async def send(base, ws_url, from_id, to_id, content):
    import websockets

    # 1. 登录
    token = login_by_id(base, from_id)
    print(f"✅ 登录成功: user_id={from_id}")

    # 2. 获取/创建会话
    r = curl("POST", f"{base}/conversations", json.dumps({"peer_user_id": to_id}), token=token)
    if r["status"] != 200:
        print(f"创建会话失败: {r['status']}")
        sys.exit(1)
    conv_id = r["data"]["id"]
    print(f"✅ 会话: {conv_id}")

    # 3. 连接 WebSocket + 认证
    ws_conn = await websockets.connect(ws_url)
    auth = ws.AuthRequest()
    auth.token = token
    frame = ws.WsFrame()
    frame.type = ws.AUTH
    frame.payload = auth.SerializeToString()
    await ws_conn.send(frame.SerializeToString())

    # 等待 AUTH_RESULT
    data = await asyncio.wait_for(ws_conn.recv(), timeout=5)
    resp = ws.WsFrame()
    resp.ParseFromString(data)
    result = ws.AuthResult()
    result.ParseFromString(resp.payload)
    if not result.success:
        print(f"认证失败: {result.message}")
        sys.exit(1)
    print(f"✅ WebSocket 认证成功")

    # 4. 发送消息
    req = msg.SendMessageRequest()
    req.conversation_id = conv_id
    req.type = msg.TEXT
    req.content = content
    send_frame = ws.WsFrame()
    send_frame.type = ws.CHAT_MESSAGE
    send_frame.payload = req.SerializeToString()
    await ws_conn.send(send_frame.SerializeToString())

    # 5. 等待 ACK
    for _ in range(5):
        try:
            data = await asyncio.wait_for(ws_conn.recv(), timeout=5)
            f = ws.WsFrame()
            f.ParseFromString(data)
            if f.type == ws.MESSAGE_ACK:
                ack = msg.MessageAck()
                ack.ParseFromString(f.payload)
                print(f"✅ 消息已发送: id={ack.message_id}, seq={ack.seq}")
                break
        except asyncio.TimeoutError:
            print("⚠️ 等待 ACK 超时")
            break

    await ws_conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="发送一条消息")
    parser.add_argument("--from", dest="from_id", type=int, required=True, help="发送者用户 ID")
    parser.add_argument("--to", dest="to_id", type=int, required=True, help="接收者用户 ID")
    parser.add_argument("--msg", type=str, required=True, help="消息内容")
    parser.add_argument("--base", type=str, default="http://127.0.0.1:9600", help="服务端地址")
    parser.add_argument("--ws", type=str, default="ws://127.0.0.1:9600/ws/im", help="WebSocket 地址")
    args = parser.parse_args()

    asyncio.run(send(args.base, args.ws, args.from_id, args.to_id, args.msg))
