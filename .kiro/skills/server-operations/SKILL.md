---
name: server-operations
description: 后端服务启动与数据库操作规范。在需要启动后端服务、运行 API 测试、执行数据库迁移或遇到连接错误时激活，确保使用正确的命令和流程。
metadata:
  model: manual
  last_modified: Wed, 18 Jun 2026 00:00:00 GMT

---

# 后端服务操作

## 适用场景

- 需要启动后端服务时
- 运行 API 测试脚本前
- 执行数据库迁移时
- 遇到 `PoolTimedOut`、`Connection refused` 等连接错误时

## 启动后端服务

**永远使用** `python scripts/server/start.py`，**禁止直接 `cargo run`**。

该脚本自动处理：PostgreSQL 启动 → 停旧进程 → cargo build → cargo run。

### 操作步骤

```python
# 1. 启动（长时间运行命令）
control_pwsh_process(action="start", command="python scripts/server/start.py", cwd="项目根目录绝对路径")

# 2. 等待启动完成
execute_pwsh(command="Start-Sleep -Seconds 10")

# 3. 验证成功（确认输出含 "listening on"）
get_process_output(terminalId=xxx, lines=10)
```

### 启动失败排查

| 现象 | 原因 | 解法 |
|------|------|------|
| `PoolTimedOut` | PostgreSQL 没启动 | start.py 自动处理，检查日志 |
| `Failed to remove exe` | 旧进程锁文件 | start.py 自动 taskkill |
| 端口 9600 占用 | 旧进程未退出 | start.py 自动停止 |

## 停止服务

```python
control_pwsh_process(action="stop", terminalId=xxx)
```

## 数据库操作

```bash
# 执行单个迁移
$env:PGPASSWORD="postgres"; psql -h localhost -U postgres -d flash_im -f "server/migrations/xxx.sql"

# 重置数据库
python scripts/server/reset_db.py

# 查询数据
$env:PGPASSWORD="postgres"; psql -h localhost -U postgres -d flash_im -c "SELECT ..."
```

## 注意事项

- ❌ 禁止 `cargo run`（不启动 PostgreSQL）
- ❌ 禁止在 start.py 之前手动 `cargo build`
- ✅ 测试脚本运行前必须确认服务已就绪
- ✅ 启动后等待 10 秒再做任何请求
