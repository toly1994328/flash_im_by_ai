# GET /api/app/list

获取所有注册的应用列表。

## Response `200`

```json
[{"id":"1","name":"闪讯","description":"跨平台即时通讯应用","created_at":"2026-06-05T13:50:59.040437Z"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/list"
```

> 返回数组，按创建时间排序