# 匠心闪讯 IM

一个完全由 AI 开发的全栈即时通讯项目。一次面向文档开发的探索。  
后端 Rust（Axum + PostgreSQL + WebSocket），前端 Flutter（多平台）。  
可产出: `Android`、`iOS`、`鸿蒙`、`Windows`、`MacOS`、`Linux`、`Web` 七端产品。

配套书籍: [《AI 全栈编程生存指南》](https://s.juejin.cn/ds/u2ouelAuNT8/) 记录了成长的全过程，以及依赖的方法论   
链接: https://s.juejin.cn/ds/u2ouelAuNT8/  
项目表现效果，已经如何运行、打包上架、可查看书籍，感谢支持~。

---


## 功能域

| 域 | 说明 | 后端模块 | 前端模块 |
|----|------|---------|---------|
| **Auth** | 认证与用户身份 | flash-auth, flash-user | flash_auth, flash_session |
| **IM** | 消息、会话、连接、缓存 | im-ws, im-conversation, im-message | flash_im_core, flash_im_conversation, flash_im_chat, flash_im_cache |
| **Social** | 好友、群聊 | im-friend, im-group | flash_im_friend, flash_im_group |
| **Search** | 全局搜索 | im-message (search routes) | flash_im_search |
| **Storage** | 文件上传与存储 | app-storage | — |

## 项目结构

```
flash_im_v1/
├── server/                 # Rust 后端（workspace 模式）
│   ├── src/                # 主入口
│   ├── modules/            # 业务模块
│   │   ├── flash-core/     # 公共基础（AppState, AppError）
│   │   ├── flash-auth/     # 认证（登录、OAuth、登录日志）
│   │   ├── flash-user/     # 用户资料
│   │   ├── im-ws/          # WebSocket 连接与帧分发
│   │   ├── im-conversation/# 会话管理
│   │   ├── im-message/     # 消息存储与广播
│   │   ├── im-friend/      # 好友关系
│   │   ├── im-group/       # 群聊管理
│   │   └── app-storage/    # 文件存储
│   └── migrations/         # 数据库迁移 SQL
├── client/                 # Flutter 前端
│   ├── lib/                # 主应用
│   ├── modules/            # 业务模块
│   │   ├── flash_auth/     # 认证 UI
│   │   ├── flash_session/  # 用户会话状态
│   │   ├── flash_im_core/  # WS 通信层 + Protobuf
│   │   ├── flash_im_conversation/ # 会话列表
│   │   ├── flash_im_chat/  # 聊天页面
│   │   ├── flash_im_friend/# 好友模块
│   │   ├── flash_im_group/ # 群聊模块
│   │   ├── flash_im_search/# 搜索模块
│   │   ├── flash_im_cache/ # 本地缓存（Drift）
│   │   └── flash_shared/   # 公共 UI 组件
│   └── packages/           # 工具包
│       └── fx_logger/      # 日志
├── proto/                  # Protobuf 协议定义
├── scripts/
│   ├── server/             # 后端脚本（启动、重置数据库）
│   ├── build_center/       # 构建中心（iOS/macOS 打包、签名、公证）
│   ├── deploy/             # 部署脚本
│   │   ├── build.py        # 本地交叉编译 + 上传
│   │   ├── flash.sh        # 服务管理（启停/日志/systemd）
│   │   ├── db.sh           # 数据库管理（迁移/重置/状态）
│   │   └── env_check.sh    # 运行环境检测
│   └── proto/              # Proto 代码生成
└── docs/                   # 文档
    └── features/           # 功能设计文档（按版本归档）
```

## 快速开始

### 后端

```bash
# 1. 启动 PostgreSQL + 重置数据库
python scripts/server/reset_db.py

# 2. 启动后端
python scripts/server/start.py
```

默认端口 9600，配置在 `server/.env`。

### 前端

```bash
# Android
python scripts/client/run.py

# Windows 桌面
python scripts/client/run.py --platform windows

# macOS 桌面（调试）
cd client && flutter run -d macos --dart-define-from-file=.env.dev
```

### macOS 构建与分发

```bash
# DMG 分发（构建 + 签名 + 打包 + 公证）
python3 scripts/build_center/macos/build.py --dmg

# App Store 上传（构建 + archive + 上传）
python3 scripts/build_center/macos/build.py --upload

# 仅上传（使用已有 archive）
python3 scripts/build_center/macos/build.py --upload-only

# 指定 Flutter SDK 路径
python3 scripts/build_center/macos/build.py --dmg --sdk ~/flutter_3.27
```

凭证配置在 `client/ios/.env.publish`（不纳入 git）。

### 部署

```bash
# 本地编译并上传到服务器（自动重启）
python scripts/deploy/build.py root@你的服务器IP

# 服务器上管理
bash flash.sh              # 启动
bash flash.sh stop         # 停止
bash flash.sh log          # 查看日志
bash db.sh migrate         # 执行数据库迁移
bash env_check.sh          # 环境检测
```

## 技术栈

| 层 | 技术 |
|----|------|
| 后端框架 | Axum 0.8 |
| 数据库 | PostgreSQL |
| 实时通信 | WebSocket + Protobuf |
| 前端框架 | Flutter（Android / iOS / macOS / Windows） |
| 状态管理 | flutter_bloc（Cubit） |
| 本地存储 | Drift（SQLite） |

## 功能网络

项目当前有 **141 个功能节点**，完整的功能网络图和归档记录见 [docs/features/archiver/index.md](docs/features/archiver/index.md)。
