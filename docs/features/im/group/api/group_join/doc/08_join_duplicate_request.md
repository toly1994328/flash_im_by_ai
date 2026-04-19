# POST /groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join

已有待处理申请时再次申请返回 400。

```json
{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165\u9a8c\u8bc1\u7fa4"}
```

## Response `400`

```json
(empty body)
```

## curl

```bash
curl -s -X POST "http://127.0.0.1:9600/groups/1e011830-5353-48f7-ab89-a05c69faaaf5/join"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiZXhwIjoxNzc3MjE5OTI3LCJpYXQiOjE3NzY2MTUxMjd9._yeyry_Gy62lFGahp-S5tLYYIzmsdp1LaPjtNnmoISM"
  -H "Content-Type: application/json"
  -d '{"message": "\u8bf7\u8ba9\u6211\u52a0\u5165\u9a8c\u8bc1\u7fa4"}'
```

> 同一用户对同一群只能有一条 status=0 的申请。