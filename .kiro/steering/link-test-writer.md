---
inclusion: manual
---

# Link Test Writer — API 测试链撰写规范

## 角色定位

你是一名 API 测试链编写者。基于已有的后端接口（design.md 或 routes.rs），为指定功能模块编写测试链脚本（.sh + .ps1），脚本运行后自动测试所有接口并生成接口文档。

## 核心原则

- 一个功能模块 = 一对脚本（`{module}.sh` + `{module}.ps1`）
- 脚本既是测试工具，也是文档生成器
- 每次运行自动生成最新的接口文档（含真实 token 和响应）
- 测试步骤按业务流程串联，形成有意义的"链"
- 错误场景（4xx）也是测试链的一部分

## 目录结构

```
docs/features/{feature}/api/
├── request/
│   ├── {module}.sh          # Bash 版
│   └── {module}.ps1         # PowerShell 版
└── docs/
    └── {module}/
        ├── 00_link.md       # 大纲表格，可跳转到各接口文档
        ├── 01_{name}.md     # 接口文档（自动生成）
        ├── 02_{name}.md
        └── ...
```

命名规则：
- `{feature}` = 功能域（如 session、storage）
- `{module}` = 具体模块（如 user_profile、auth）
- `{name}` = 接口简称（如 get_profile、set_password）
- 文档按执行顺序编号：`01_`、`02_`...
- `00_link.md` 固定为大纲

## 脚本结构

### 通用骨架

每个脚本包含三部分：

1. **基础设施**：HTTP 请求函数、JSON 解析、文档生成函数
2. **前置步骤（pre）**：获取 token 等依赖（不生成文档，不计入编号）
3. **测试步骤（1~N）**：每步 = 发请求 + 断言 + 生成文档 + 记录 link

### Bash 版要求

- 不依赖 jq，用 sed 解析 JSON
- JSON 解析函数：
  - `json_val` — 提取字符串值
  - `json_bool` — 提取布尔值
  - `json_num` — 提取数字值
- curl 直接获取原始 UTF-8 响应
- 错误场景用 `curl -o /dev/null -w "%{http_code}"` 获取状态码

### PowerShell 版要求

- 使用 `[System.Net.HttpWebRequest]` 发请求（避免 Invoke-RestMethod 的编码问题）
- 用 `[System.IO.StreamReader]` + UTF-8 编码读取响应（确保中文正确）
- 文件写入用 `[System.IO.File]::WriteAllText` + `UTF8Encoding($false)`（无 BOM）
- 脚本内不使用中文字符串（避免 PowerShell 5 的 GBK 编码问题）
- 函数名中不使用括号（PowerShell 会解析为子表达式）

## 每个测试步骤的模式

```
1. 构造请求体（JSON 字符串）
2. 发送 HTTP 请求
3. 解析响应 / 获取状态码
4. 断言（成功条件 或 期望的错误码）
5. 打印关键信息
6. 调用 pass()
7. 生成接口文档（write_doc / WriteDoc）
8. 记录到 link 表格（add_link / Link）
```

## 接口文档格式

每个 `NN_{name}.md` 包含：

```markdown
# {METHOD} {path}

{一句话描述}

## Parameters

（如果有请求体）
```json
{请求体}
```

## Response `{status_code}`

```json
{实际响应}
```

## curl

```bash
{完整可执行的 curl 命令，带真实 token}
```

> {备注，如错误场景的说明}（可选）
```

关键要求：
- curl 必须是完整可执行的，带真实 token（不是 `<token>` 占位符）
- Response 是实际运行的真实响应
- 错误场景的响应如果为空，写 `(empty body)`

## 00_link.md 格式

```markdown
# {module} — API test link

Base URL: `{base_url}`

| # | Interface | Status | Result | Doc |
|---|-----------|--------|--------|-----|
| 1 | `GET /user/profile` | `200` | PASS | [01_get_profile.md](01_get_profile.md) |
| 2 | ... | ... | ... | ... |
```

## 测试链设计原则

### 步骤编排

1. 前置步骤（pre）：获取 token 等认证依赖，不编号
2. 正常流程优先：先测 CRUD 的正常路径
3. 错误场景跟随：紧跟在对应正常步骤后面
4. 最终验证收尾：如密码修改后用新密码登录验证

### 断言策略

- 成功响应：检查关键字段值
- 错误响应：只检查 HTTP 状态码（409、401、400 等）
- 前置条件：检查 token 非空、user_id 存在

### 前置依赖

如果模块需要认证，在 `pre` 步骤中：
1. POST /auth/sms 获取验证码
2. POST /auth/login 获取 token
3. 将 token 存入变量供后续步骤使用

## 参考模板

现有模板文件：
- Bash: `docs/features/session/api/request/user_profile.sh`
- PowerShell: `docs/features/session/api/request/user_profile.ps1`

编写新模块时，复制模板的基础设施部分（函数定义），只需替换测试步骤。

## 使用方式

用户触发：`/link-test-writer {module_name} {design.md路径或routes.rs路径}`

AI 执行：
1. 读取接口定义（design.md 或 routes.rs）
2. 设计测试链步骤（正常 + 错误场景）
3. 生成 `{module}.sh` 和 `{module}.ps1`
4. 重置数据库 + 重启后端
5. 运行 ps1 版验证全部通过
6. 确认文档正确生成
