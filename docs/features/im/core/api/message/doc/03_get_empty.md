# GET /conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=1

Get messages before seq=1. Returns empty array.

## Response `200`

```json
[]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/conversations/9e7ec25e-bd37-4f5f-8bac-eb54bed10dd8/messages?before_seq=1"
  -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjoxNzc1NjkwMjc1LCJpYXQiOjE3NzUwODU0NzV9.ZbbthHvgsv14ryRsz4NVHth1zrZlnRnyOILchE21fN4"
```