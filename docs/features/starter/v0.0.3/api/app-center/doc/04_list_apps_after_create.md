# GET /api/app/list

新增应用后验证列表包含新应用。

## Response `200`

```json
[{"id":"1","name":"闪讯","description":"跨平台即时通讯应用","created_at":"2026-06-05T13:50:59.040437Z"},{"id":"test_app","name":"测试应用","description":"用于测试的应用","created_at":"2026-06-05T22:31:45.717788Z"}]
```

## curl

```bash
curl -s -X GET "http://127.0.0.1:9600/api/app/list"
```