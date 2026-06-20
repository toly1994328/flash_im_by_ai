# 后端接口补充 — app-center 管理接口

为 Web 后台补充的管理接口，基于已有的 apps + app_versions 表。

---

## 补充接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/app/list | 获取所有应用列表 |
| POST | /api/app | 新增应用 |
| GET | /api/app/versions?app_id=xxx | 获取某应用全部版本记录（所有平台） |

---

### GET /api/app/list

返回所有注册的应用。

响应（200）：

```json
[
  {
    "id": "1",
    "name": "闪讯",
    "description": "跨平台即时通讯应用",
    "created_at": "2026-06-05T00:00:00Z"
  }
]
```

---

### POST /api/app

新增应用。

请求体：

```json
{
  "id": "my_new_app",
  "name": "新应用",
  "description": "应用描述"
}
```

成功响应（201）：

```json
{"message": "app created"}
```

错误：409 如果 id 已存在。

---

### GET /api/app/versions?app_id=xxx

获取某应用的所有版本记录（所有平台），按创建时间降序。

响应（200）：

```json
[
  {
    "id": 1,
    "platform": "android",
    "version": "1.0.0",
    "download_url": "https://...",
    "file_size": 25000000,
    "sha256": "abc123",
    "release_notes": "首个版本",
    "force_update": false,
    "created_at": "2026-06-05T00:00:00Z"
  }
]
```
