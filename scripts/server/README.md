# 后端脚本

所有脚本使用 Python，支持 Windows / macOS / Linux。

## 脚本一览

| 脚本 | 用途 |
|------|------|
| `start.py` | 启动后端服务（自动检查 PG → 停旧进程 → cargo build → cargo run） |
| `reset_db.py` | 重置数据库（删库 → 建库 → 执行全部迁移） |
| `im_seed/seed.py` | 注入种子数据（52 个测试用户 + 会话） |

## 常用流程

```bash
# 首次启动 / 全新环境
python scripts/server/reset_db.py
python scripts/server/start.py
# 新开终端
python scripts/server/im_seed/seed.py

# 日常开发
python scripts/server/start.py

# 数据库结构变更后
python scripts/server/reset_db.py
# 重启服务 + 重新注入种子
python scripts/server/start.py
python scripts/server/im_seed/seed.py
```

## 种子数据

`im_seed/seed-data.json` 定义了 52 个以中国传统色命名的测试用户。

主用户：朱红（13800010001），密码：111111

种子脚本依赖后端服务已启动，通过 HTTP 接口注册用户、设置资料、创建会话。
