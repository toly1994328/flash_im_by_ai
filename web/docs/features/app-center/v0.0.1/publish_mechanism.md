# 版本发布确认机制 — 补充设计

## 背景

新增版本后立刻对客户端生效，存在风险：
- iOS/鸿蒙版本需要商店审核，审核通过前如果客户端已提示更新但商店还没上架，用户点"更新"跳转后找不到新版本
- 多平台发版时间不同步，需要逐个平台手动控制生效时间

## 方案

在 `app_versions` 表新增 `published` 字段，默认 `false`。客户端只能查到 `published = true` 的版本。

### 数据库变更

```sql
ALTER TABLE app_versions ADD COLUMN published BOOLEAN NOT NULL DEFAULT FALSE;
```

### 接口变更

**GET /api/app/version（客户端查询）**

查询条件加 `AND published = true`：

```sql
SELECT ... FROM app_versions
WHERE app_id = $1 AND platform = $2 AND published = true
ORDER BY created_at DESC LIMIT 1
```

**POST /api/app/version/publish**

发布指定版本（将 published 设为 true）。

请求参数（query）：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用标识 |
| platform | string | 是 | 平台 |
| version | string | 是 | 版本号 |

成功响应（200）：

```json
{"message": "version published"}
```

**POST /api/app/version/unpublish**

撤回发布（将 published 设为 false）。参数同上。

### Web 后台变更

版本列表表格新增"状态"列：
- `published = false` → 显示灰色 Tag "待发布" + "发布"按钮
- `published = true` → 显示绿色 Tag "已发布" + "撤回"按钮

### 工作流

```
新增版本（POST /api/app/version）
    ↓
状态：待发布（客户端查不到）
    ↓
商店审核通过 / 确认无误
    ↓
手动发布（POST /api/app/version/publish）
    ↓
状态：已发布（客户端可检测到更新）
```

### 向下兼容

- 已有版本数据 `published` 默认为 `false`，需要手动发布一次
- 或迁移时 `UPDATE app_versions SET published = true WHERE ...` 让已有数据自动生效
