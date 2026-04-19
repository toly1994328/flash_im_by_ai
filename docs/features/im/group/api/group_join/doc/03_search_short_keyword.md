# GET /groups/search?keyword=开

关键词长度不足 2 字符时返回空数组。

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/groups/search?keyword=开"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0IiwiZXhwIjoxNzc3MTQwNjY5LCJpYXQiOjE3NzY1MzU4Njl9.JNl-a0YEr2TO0EUN2Pm32l3zoqIAZ9PABVOA3KmfAvY"
```

> keyword < 2 字符直接返回空，不查数据库。