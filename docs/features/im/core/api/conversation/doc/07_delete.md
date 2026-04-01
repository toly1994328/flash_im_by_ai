# DELETE /conversations/d1752cc9-8a9c-428c-b97b-f030655c7afb

软删除会话，仅影响当前用户。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | UUID | 是 | 会话 ID（路径参数） |

## Response `200`

```json
{"message":"会话已删除"}
```

## curl

```bash
curl -s -X DELETE "http://127.0.0.1:9600/conversations/d1752cc9-8a9c-428c-b97b-f030655c7afb"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NDA1OTIyLCJpYXQiOjE3NzQ4MDExMjJ9.giI1rG-7ytHzmEykcXLygkv98s60ITQA3fVgBRiH8gY"
```