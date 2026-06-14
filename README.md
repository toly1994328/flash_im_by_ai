# 匠心闪讯 IM

<h1 align="center" style="border-bottom: none">
    <b>
        <a href="https://github.com/toly1994328/flash_im_by_ai">匠心闪讯</a><br>
    </b>
    ⭐️   AI 全栈全端 IM 编程探索  ⭐️ <br>
</h1>

<p align="center">
这是一个完全由 AI 开发的全栈即时通讯项目。一次新时代 AI 面向文档开发的探索。  
</p>

<p align="center">
<a href="https://github.com/toly1994328/flash_im_by_ai"><img src="https://img.shields.io/github/stars/toly1994328/flash_im_by_ai.svg?style=flat&logo=github&colorB=deeppink&label=stars"></a>
<a href="https://github.com/toly1994328/flash_im_by_ai"><img src="https://img.shields.io/github/forks/toly1994328/flash_im_by_ai.svg"></a>
<a href="https://www.apache.org/licenses/LICENSE-2.0"><img src="https://img.shields.io/badge/license-Apache%202.0-blue.svg" alt="License: Apache 2.0"></a>
</p>


### 方法论

配套书籍: [《AI 全栈编程生存指南》](https://s.juejin.cn/ds/u2ouelAuNT8/) 记录了成长的全过程，以及方法论探索   
链接: https://s.juejin.cn/ds/u2ouelAuNT8/  
项目表现效果，已经如何运行、打包上架、可查看书籍，感谢支持~。


---

### 项目架构与体验

后端 Rust（Axum + PostgreSQL + WebSocket），前端 Flutter（七端平台支持）。  
可产出: `Android`、`iOS`、`鸿蒙`、`Windows`、`MacOS`、`Linux`、`Web` 七端产品。

| 平台 | 状态 | 下载体验 | 备用链接 |
|------|------|----------|----------|
| Android | 可构建 | 准备中| — |
| iOS | ✅ 已上架 | [App Store](https://apps.apple.com/app/id6772819751) | — |
| Windows | 可构建 | 准备中 | — |
| macOS | ✅ 已上线 | [Mac App Store](https://apps.apple.com/app/id6772819751) | — |
| Linux | 可构建 | 准备中 | — |
| Web | 可构建 | 准备中 | — |
| 鸿蒙 | 可构建 | 准备中 | — |


---


### 功能域

| 域 | 说明 | 后端模块 | 前端模块 |
|----|------|---------|---------|
| **Auth** | 认证与用户身份 | flash-auth, flash-user | flash_auth, flash_session |
| **IM** | 消息、会话、连接、缓存 | im-ws, im-conversation, im-message | flash_im_core, flash_im_conversation, flash_im_chat, flash_im_cache |
| **Social** | 好友、群聊 | im-friend, im-group | flash_im_friend, flash_im_group |
| **Search** | 全局搜索 | im-message (search routes) | flash_im_search |
| **Storage** | 文件上传与存储 | app-storage | — |

---

### 项目结构

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

---

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
