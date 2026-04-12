# DELETE /api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23

删除申请记录（侧滑删除）。

## Response `200`

```json
{"data":null}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/api/friends/requests/2b341702-4c15-4a4d-b01a-d0b02a868b23"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc2NTkzOTcxLCJpYXQiOjE3NzU5ODkxNzF9.zS0yoOjS3x0n-SO_8A6zqWxQ3MVfFKqmBR3Gzav0T5Q"
```

> 只有申请的发送方或接收方可以删除。