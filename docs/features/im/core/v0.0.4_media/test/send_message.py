#!/usr/bin/env python3
"""
发送富媒体消息（图片 / 视频 / 文件）

用法:
  python send_message.py image
  python send_message.py video
  python send_message.py file
  python send_message.py image --from 2 --to 1

自动使用 assets/ 目录下的测试资源。
依赖: pip install websockets protobuf
"""

import asyncio
import argparse
import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "proto"))
import ws_pb2 as ws
import message_pb2 as msg

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(SCRIPT_DIR, "assets")


def asset(name):
    return os.path.join(ASSETS_DIR, name)


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
    return status, data


def curl_upload(url, file_path, field_name="file", extra_fields=None):
    cmd = ["curl.exe", "-s", "-w", "\n%{http_code}", "-X", "POST", url]
    cmd += ["-F", f"{field_name}=@{file_path}"]
    if extra_fields:
        for k, v in extra_fields.items():
            if isinstance(v, str) and os.path.isfile(v):
                cmd += ["-F", f"{k}=@{v}"]
            else:
                cmd += ["-F", f"{k}={v}"]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    lines = result.stdout.rsplit("\n", 1)
    body = lines[0] if len(lines) > 1 else ""
    status = int(lines[-1]) if lines[-1].isdigit() else 0
    data = json.loads(body) if body.strip() else None
    return status, data


def login_by_id(base, user_id):
    phone = f"138000{10000 + user_id}"
    s, data = curl("POST", f"{base}/auth/login", json.dumps({
        "phone": phone, "type": "password", "credential": "111111"
    }))
    if not data or not data.get("token"):
        print(f"❌ 登录失败: user_id={user_id}")
        sys.exit(1)
    return data["token"]


def upload_image(base):
    path = asset("test.webp")
    print(f"\n📸 上传图片: {os.path.basename(path)}")
    s, data = curl_upload(f"{base}/api/upload/image", path)
    if s != 200 or not data:
        print(f"❌ 失败: status={s}")
        sys.exit(1)
    print(f"   {data['width']}x{data['height']}, {data['size']} bytes")
    print(f"   original:  {data['original_url']}")
    print(f"   thumbnail: {data['thumbnail_url']}")
    return data


def upload_video(base):
    path = asset("test.mp4")
    print(f"\n🎬 上传视频: {os.path.basename(path)}")

    with open(asset("test_meta.json"), "r", encoding="utf-8") as f:
        meta = json.load(f)["video"]

    s, data = curl_upload(
        f"{base}/api/upload/video", path, field_name="video",
        extra_fields={
            "thumbnail": asset(meta["thumbnail"]),
            "duration_ms": str(meta["duration_ms"]),
            "width": str(meta["width"]),
            "height": str(meta["height"]),
        }
    )
    if s != 200 or not data:
        print(f"❌ 失败: status={s}")
        sys.exit(1)
    print(f"   {data['width']}x{data['height']}, {data['duration_ms']}ms, {data['file_size']} bytes")
    print(f"   video:     {data['video_url']}")
    print(f"   thumbnail: {data['thumbnail_url']}")
    return data


def upload_file(base):
    path = asset("sky_engine.zip")
    print(f"\n📄 上传文件: {os.path.basename(path)}")
    s, data = curl_upload(f"{base}/api/upload/file", path)
    if s != 200 or not data:
        print(f"❌ 失败: status={s}")
        sys.exit(1)
    print(f"   {data['file_name']}, {data['file_size']} bytes")
    print(f"   url: {data['file_url']}")
    return data


async def ws_send(ws_conn, req):
    """发送消息帧并等待 ACK"""
    frame = ws.WsFrame()
    frame.type = ws.CHAT_MESSAGE
    frame.payload = req.SerializeToString()
    await ws_conn.send(frame.SerializeToString())

    for _ in range(10):
        try:
            data = await asyncio.wait_for(ws_conn.recv(), timeout=5)
            f = ws.WsFrame()
            f.ParseFromString(data)
            if f.type == ws.MESSAGE_ACK:
                ack = msg.MessageAck()
                ack.ParseFromString(f.payload)
                print(f"   ✅ ACK: id={ack.message_id}, seq={ack.seq}")
                return ack
        except asyncio.TimeoutError:
            break
    print("   ⚠️ ACK 超时")
    return None
async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("type", choices=["image", "video", "file"], help="消息类型")
    parser.add_argument("--from", dest="from_id", type=int, default=2)
    parser.add_argument("--to", dest="to_id", type=int, default=1)
    parser.add_argument("--base", default="http://127.0.0.1:9600")
    parser.add_argument("--ws", default="ws://127.0.0.1:9600/ws/im")
    args = parser.parse_args()

    import websockets

    # 登录
    token = login_by_id(args.base, args.from_id)
    print(f"✅ 登录: user_id={args.from_id}")

    # 获取/创建会话
    s, conv = curl("POST", f"{args.base}/conversations",
                    json.dumps({"peer_user_id": args.to_id}), token=token)
    conv_id = conv["id"]
    print(f"✅ 会话: {conv_id}")

    # 连接 WS + 认证
    ws_conn = await websockets.connect(args.ws)
    auth_req = ws.AuthRequest()
    auth_req.token = token
    frame = ws.WsFrame()
    frame.type = ws.AUTH
    frame.payload = auth_req.SerializeToString()
    await ws_conn.send(frame.SerializeToString())
    data = await asyncio.wait_for(ws_conn.recv(), timeout=5)
    resp = ws.WsFrame()
    resp.ParseFromString(data)
    result = ws.AuthResult()
    result.ParseFromString(resp.payload)
    if not result.success:
        print(f"❌ WS 认证失败")
        sys.exit(1)
    print(f"✅ WebSocket 认证成功")

    req = msg.SendMessageRequest()
    req.conversation_id = conv_id

    if args.type == "image":
        img = upload_image(args.base)
        req.type = msg.IMAGE
        req.content = img["original_url"]
        req.extra = json.dumps({
            "width": img["width"],
            "height": img["height"],
            "size": img["size"],
            "format": img["format"],
            "thumbnail_url": img["thumbnail_url"],
        }).encode("utf-8")

    elif args.type == "video":
        vid = upload_video(args.base)
        req.type = msg.VIDEO
        req.content = vid["video_url"]
        req.extra = json.dumps({
            "thumbnail_url": vid["thumbnail_url"],
            "duration_ms": vid["duration_ms"],
            "width": vid["width"],
            "height": vid["height"],
            "file_size": vid["file_size"],
        }).encode("utf-8")

    elif args.type == "file":
        fil = upload_file(args.base)
        req.type = msg.FILE
        req.content = fil["file_url"]
        req.extra = json.dumps({
            "file_name": fil["file_name"],
            "file_size": fil["file_size"],
            "file_url": fil["file_url"],
            "file_type": fil["file_type"],
        }).encode("utf-8")

    await ws_send(ws_conn, req)
    await ws_conn.close()


if __name__ == "__main__":
    asyncio.run(main())
