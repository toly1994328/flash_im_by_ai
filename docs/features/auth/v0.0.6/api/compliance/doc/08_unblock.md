# DELETE /api/blocks/3

取消拉黑用户。

## Response `200`

```json
{"message":"已取消拉黑"}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/api/blocks/3"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiZXhwIjoxNzgxNzM5MjA4LCJpYXQiOjE3ODExMzQ0MDh9.EMBPh2qwXnrst4SJ4KfJqmrnmTVI6_f7xTosC3742NE"
```