# PUT /groups/33a71c87-efc8-414d-af0e-696879167e33/transfer

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
curl -s -X PUT "http://127.0.0.1:9600/groups/33a71c87-efc8-414d-af0e-696879167e33/transfer"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzc3MzMzNTExLCJpYXQiOjE3NzY3Mjg3MTF9.7Z1nZxpxZB41Zqe86nTUYAaYCJi5kWWiSRTNOrFNzvY"
  -H "Content-Type: application/json"
  -d '{"new_owner_id": 1}'
```

> 转让是双向的，新群主可以再次转让。