# GET /conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=10

Get messages before a specific sequence number.

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| before_seq | int | no | Get messages with seq < this value |
| limit | int | no | Max messages to return (default 50, max 100) |

## Response `200`

```json
[{"content":"hello from A","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:51:26.241130Z","extra":null,"id":"6a003bec-bf92-44d6-96eb-7ee8b9a8d7e9","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":9,"status":0},{"content":"second message","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:49:18.308777Z","extra":null,"id":"ba0a0862-9643-4205-a13b-364f6dc1f2bb","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":8,"status":0},{"content":"hello from A","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:49:15.261069Z","extra":null,"id":"efc1e7fa-3f2e-48aa-945e-457b38b77f1a","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":7,"status":0},{"content":"second message","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:46:42.187133Z","extra":null,"id":"10e7f220-838b-43a2-9282-e1d216b4e7a4","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":6,"status":0},{"content":"hello from A","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:46:39.130147Z","extra":null,"id":"a0ed7ad9-0da0-4808-9dcd-d09951d57207","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":5,"status":0},{"content":"second message","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:46:20.128301Z","extra":null,"id":"cce6ec34-70fb-4336-9ca6-4794ed5936f9","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":4,"status":0},{"content":"hello from A","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-04-01T22:46:17.059120Z","extra":null,"id":"c8d4343a-0382-4007-aedd-8ce7078eebee","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":3,"status":0},{"content":"second message","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-03-30T23:20:06.283352Z","extra":null,"id":"65112ac0-8766-4cf6-8bbf-853c11be687d","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":2,"status":0},{"content":"hello from A","conversation_id":"9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8","created_at":"2026-03-30T23:20:03.232968Z","extra":null,"id":"796d6696-5823-44ff-ae78-400dd951c971","msg_type":0,"sender_avatar":"identicon:1:ed5126","sender_id":1,"sender_name":"朱红","seq":1,"status":0}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=10"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NjkwMjc1LCJpYXQiOjE3NzUwODU0NzV9.ZbbthHvgsv14ryRsz4NVHth1zrZlnRnyOILchE21fN4"
```