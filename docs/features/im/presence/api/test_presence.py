#!/usr/bin/env python3
"""
在线状态与已读回执 WS 测试脚本

前置条件：
1. python scripts/server/data_handler.py（重置数据库 + 启动服务 + seed）
2. 服务运行在 127.0.0.1:9600

测试流程：
1. 用户1 登录获取 token
2. 用户1 WS 连接 + 认证 → 收到 ONLINE_LIST（空）
3. 用户2 登录获取 token
4. 用户2 WS 连接 + 认证 → 收到 ONLINE_LIST（含用户1）
5. 用户1 收到 USER_ONLINE（用户2）
6. 用户2 发送 READ_RECEIPT → 用户1 收到 READ_RECEIPT 通知
7. 用户2 断开 → 用户1 收到 USER_OFFLINE（用户2）
"""

import asyncio
import json
import subprocess
import sys
import time

import websockets

# 添加 proto 目录到 path
sys.path.insert(0, "docs/features/im/presence/api/proto/proto")
import ws_pb2 as ws_proto
import message_pb2 as msg_proto

BASE = "http://127.0.0.1:9600"
WS_URL = "ws://127.0.0.1:9600/ws/im"

CYAN = "\033[36m"
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"


def login(phone):
    """SMS 登录，返回 token"""
    r = curl_post(f"{BASE}/auth/sms", {"phone": phone})
    code = r["code"]
    r2 = curl_post(f"{BASE}/auth/login", {
        "phone": phone, "type": "sms", "credential": code
    })
    return r2["token"], r2["user_id"]


def curl_post(url, data):
    cmd = ["curl.exe", "-s", "-X", "POST", url,
           "-H", "Content-Type: application/json",
           "-d", json.dumps(data)]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    return json.loads(r.stdout)


def build_auth_frame(token):
    """构建 AUTH 帧"""
    auth_req = ws_proto.AuthRequest()
    auth_req.token = token
    frame = ws_proto.WsFrame()
    frame.type = ws_proto.WsFrameType.Value("AUTH")
    frame.payload = auth_req.SerializeToString()
    return frame.SerializeToString()


def build_read_receipt_frame(conversation_id, read_seq):
    """构建 READ_RECEIPT 帧"""
    req = msg_proto.ReadReceiptRequest()
    req.conversation_id = conversation_id
    req.read_seq = read_seq
    frame = ws_proto.WsFrame()
    frame.type = ws_proto.WsFrameType.Value("READ_RECEIPT")
    frame.payload = req.SerializeToString()
    return frame.SerializeToString()


def parse_frame(data):
    """解析 WS 帧，返回 (type_name, payload_bytes)"""
    frame = ws_proto.WsFrame()
    frame.ParseFromString(data)
    type_name = ws_proto.WsFrameType.Name(frame.type)
    return type_name, frame.payload


def parse_auth_result(payload):
    result = ws_proto.AuthResult()
    result.ParseFromString(payload)
    return result.success, result.message


def parse_online_list(payload):
    notif = msg_proto.OnlineListNotification()
    notif.ParseFromString(payload)
    return list(notif.user_ids)


def parse_user_status(payload):
    notif = msg_proto.UserStatusNotification()
    notif.ParseFromString(payload)
    return notif.user_id


def parse_read_receipt(payload):
    notif = msg_proto.ReadReceiptNotification()
    notif.ParseFromString(payload)
    return notif.conversation_id, notif.user_id, notif.read_seq


async def recv_frame(ws, timeout=3):
    """接收一个帧，超时返回 None"""
    try:
        data = await asyncio.wait_for(ws.recv(), timeout=timeout)
        return parse_frame(data)
    except asyncio.TimeoutError:
        return None, None


async def recv_until(ws, target_type, timeout=5):
    """持续接收帧直到收到指定类型，返回 payload（可能是 b""）。超时返回 None。"""
    deadline = time.time() + timeout
    while time.time() < deadline:
        remaining = deadline - time.time()
        type_name, payload = await recv_frame(ws, timeout=max(0.5, remaining))
        if type_name == target_type:
            return payload if payload is not None else b""
        if type_name:
            print(f"  (跳过帧: {type_name})")
    return None


passed = 0
failed = 0


def check(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  {GREEN}[PASS]{RESET} {name}")
    else:
        failed += 1
        print(f"  {RED}[FAIL]{RESET} {name} {detail}")


async def main():
    global passed, failed
    print(f"\n{CYAN}========== 在线状态与已读回执 WS 测试 =========={RESET}\n")

    # 登录两个用户
    phone1 = "13800010001"
    phone2 = "13800010002"
    print(f"[1] 登录用户1: {phone1}")
    token1, uid1 = login(phone1)
    print(f"    token={token1[:20]}... uid={uid1}")

    print(f"[2] 登录用户2: {phone2}")
    token2, uid2 = login(phone2)
    print(f"    token={token2[:20]}... uid={uid2}")

    # ─── 用户1 连接 ───
    print(f"\n{CYAN}[3] 用户1 WS 连接 + 认证{RESET}")
    ws1 = await websockets.connect(WS_URL)
    await ws1.send(build_auth_frame(token1))

    # 收到 AUTH_RESULT
    payload = await recv_until(ws1, "AUTH_RESULT")
    success, msg = parse_auth_result(payload)
    check("用户1 认证成功", success, msg)

    # 收到 ONLINE_LIST（应该为空，因为只有自己）
    # 注意：空 repeated 字段序列化为 0 字节，payload 是 b""
    payload = await recv_until(ws1, "ONLINE_LIST", timeout=3)
    if payload is not None:
        online_ids = parse_online_list(payload)
        check("用户1 收到 ONLINE_LIST（空）", len(online_ids) == 0,
              f"实际: {online_ids}")
    else:
        check("用户1 收到 ONLINE_LIST", False, "超时未收到")

    # ─── 用户2 连接 ───
    print(f"\n{CYAN}[4] 用户2 WS 连接 + 认证{RESET}")
    ws2 = await websockets.connect(WS_URL)
    await ws2.send(build_auth_frame(token2))

    # 用户2 收到 AUTH_RESULT
    payload = await recv_until(ws2, "AUTH_RESULT")
    success, msg = parse_auth_result(payload)
    check("用户2 认证成功", success, msg)

    # 用户2 收到 ONLINE_LIST（应该含用户1）
    payload = await recv_until(ws2, "ONLINE_LIST")
    if payload:
        online_ids = parse_online_list(payload)
        check("用户2 收到 ONLINE_LIST（含用户1）",
              str(uid1) in online_ids,
              f"实际: {online_ids}")
    else:
        check("用户2 收到 ONLINE_LIST", False, "超时未收到")

    # 用户1 收到 USER_ONLINE（用户2）
    print(f"\n{CYAN}[5] 用户1 收到用户2上线通知{RESET}")
    payload = await recv_until(ws1, "USER_ONLINE")
    if payload:
        online_uid = parse_user_status(payload)
        check("用户1 收到 USER_ONLINE（用户2）",
              online_uid == str(uid2),
              f"实际: {online_uid}")
    else:
        check("用户1 收到 USER_ONLINE", False, "超时未收到")

    # ─── 已读回执测试 ───
    print(f"\n{CYAN}[6] 已读回执测试{RESET}")

    # 先创建一个会话（用 HTTP，带 token1）
    cmd = ["curl.exe", "-s", "-X", "POST", f"{BASE}/conversations",
           "-H", "Content-Type: application/json",
           "-H", f"Authorization: Bearer {token1}",
           "-d", json.dumps({"peer_user_id": uid2})]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    conv = json.loads(r.stdout) if r.stdout.strip() else {}
    conv_id = conv.get("id", "")
    print(f"    会话ID: {conv_id[:8]}...")

    # 用户1 通过 HTTP 发一条消息（拿到 msg_id 和 seq）
    msg_id = ""
    msg_seq = 0
    if conv_id:
        cmd = ["curl.exe", "-s", "-X", "POST",
               f"{BASE}/conversations/{conv_id}/messages",
               "-H", "Content-Type: application/json",
               "-H", f"Authorization: Bearer {token1}",
               "-d", json.dumps({"content": "hello for read test"})]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        msg_data = json.loads(r.stdout) if r.stdout.strip() else {}
        msg_id = msg_data.get("id", "")
        msg_seq = msg_data.get("seq", 0)
        print(f"    消息ID: {msg_id[:8]}... seq={msg_seq}")

        # 消耗掉用户1和用户2收到的 CHAT_MESSAGE / CONVERSATION_UPDATE 帧
        await asyncio.sleep(0.5)
        for _ in range(5):
            t, _ = await recv_frame(ws1, timeout=0.3)
            if not t: break
        for _ in range(5):
            t, _ = await recv_frame(ws2, timeout=0.3)
            if not t: break

    # 用户2 发送 READ_RECEIPT
    if conv_id and msg_seq > 0:
        await ws2.send(build_read_receipt_frame(conv_id, msg_seq))
        print(f"    用户2 发送 READ_RECEIPT (seq={msg_seq})")

        # 用户1 收到 READ_RECEIPT 通知
        payload = await recv_until(ws1, "READ_RECEIPT", timeout=5)
        if payload is not None:
            r_conv_id, r_uid, r_seq = parse_read_receipt(payload)
            check("用户1 收到 READ_RECEIPT",
                  r_uid == str(uid2) and r_seq == msg_seq,
                  f"实际: uid={r_uid}, seq={r_seq}")
        else:
            check("用户1 收到 READ_RECEIPT", False, "超时未收到")

    # ─── read-status HTTP 接口测试 ───
    print(f"\n{CYAN}[6b] 已读详情接口测试{RESET}")

    if conv_id and msg_id:
        # 先测 read-seq 接口
        cmd = ["curl.exe", "-s", "-X", "GET",
               f"{BASE}/conversations/{conv_id}/read-seq",
               "-H", f"Authorization: Bearer {token1}"]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        seq_data = json.loads(r.stdout) if r.stdout.strip() else {}
        members_seq = seq_data.get("members_read_seq", {})
        peer_seq = members_seq.get(str(uid2), 0)
        check("read-seq: 用户2 的已读位置 >= 消息 seq",
              peer_seq >= msg_seq,
              f"peer_seq={peer_seq}, msg_seq={msg_seq}")

        # 再测 read-status 接口
        cmd = ["curl.exe", "-s", "-X", "GET",
               f"{BASE}/conversations/{conv_id}/messages/{msg_id}/read-status",
               "-H", f"Authorization: Bearer {token1}"]
        r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
        status_data = json.loads(r.stdout) if r.stdout.strip() else {}
        read_members = status_data.get("read_members", [])
        unread_members = status_data.get("unread_members", [])

        read_uids = [m["user_id"] for m in read_members]
        check("read-status: 用户2 在已读列表中",
              uid2 in read_uids,
              f"read={read_uids}, unread={[m['user_id'] for m in unread_members]}")

        check("read-status: 发送者(用户1)不在列表中",
              uid1 not in read_uids and uid1 not in [m["user_id"] for m in unread_members],
              "发送者应被排除")

    # ─── 用户2 断开 ───
    print(f"\n{CYAN}[7] 用户2 断开，用户1 收到下线通知{RESET}")
    await ws2.close()
    await asyncio.sleep(0.5)

    payload = await recv_until(ws1, "USER_OFFLINE", timeout=5)
    if payload:
        offline_uid = parse_user_status(payload)
        check("用户1 收到 USER_OFFLINE（用户2）",
              offline_uid == str(uid2),
              f"实际: {offline_uid}")
    else:
        check("用户1 收到 USER_OFFLINE", False, "超时未收到")

    # 清理
    await ws1.close()

    # 结果
    total = passed + failed
    print(f"\n{CYAN}========== 结果 =========={RESET}")
    print(f"  通过: {GREEN}{passed}{RESET} / {total}")
    if failed > 0:
        print(f"  失败: {RED}{failed}{RESET} / {total}")
    print()


if __name__ == "__main__":
    asyncio.run(main())
