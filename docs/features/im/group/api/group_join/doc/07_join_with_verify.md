# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join

入群（需验证）：创建入群申请，返回 auto_approved=false。WS 推送 GROUP_JOIN_REQUEST 帧给群主。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| message | string | 否 | 申请留言 |

```json
{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165\u9a8c\u8bc1\u7fa4"}
```

## Response `200`

```json
{"auto_approved":false}
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9._yeyry_Gy62lFGahp-S5tLYYIzmsdp1LaPjtNnmoISM"
  -H "Content-Type: application/json"
  -d '{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165\u9a8c\u8bc1\u7fa4"}'
```