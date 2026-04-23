# PUT /groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer

uid2 转让回 uid1，恢复原群主以便后续测试。

```json
{"new_owner_id": 1}
```

## Response `200`

```json
{"success":true}
```

## curl

```bash
curl -s -X PUT "http://127.0.0.1:9600/groups/0756c679-62de-4f8f-a274-43d29187d18b/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3NTA2ODU1LCJpYXQiOjE3NzY5MDIwNTV9.aSX1haVYCWshpi-kSMQipO4ftHQnprzE1Y6FSs6YpGE"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 1}'
```

> 转让是双向的，新群主可以再次转让。