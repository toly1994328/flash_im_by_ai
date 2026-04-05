# 会话域 — 局域网络

涉及节点：D-01~D-05, D-11, P-01~P-05, P-10

---

## 节点详情

| 编号 | 功能节点 | 模块 | 端 | 职责 |
|------|---------|------|-----|------|
| D-01 | 会话创建 | im-conversation | 后端 | 创建私聊/群聊会话 + 成员关系 |
| D-02 | 会话列表查询 | im-conversation | 后端 | 分页查询，关联 user_profiles 返回对方信息 |
| D-03 | 会话删除 | im-conversation | 后端 | 软删除（conversation_members 标记） |
| D-04 | 未读数管理 | im-conversation | 后端 | increment_unread / 被 D-08、D-10 调用 |
| D-05 | 标记已读 | im-conversation | 后端 | POST /conversations/:id/read，unread_count 置 0 |
| D-11 | 获取单个会话详情 | im-conversation | 后端 | GET /conversations/:id，验证成员 + 关联 user_profiles |
| P-01 | 会话列表展示 | flash_im_conversation | 前端 | ConversationListPage + ConversationTile |
| P-02 | 分页加载 | flash_im_conversation | 前端 | 滚动到底部触发 loadMore |
| P-03 | 会话实时更新 | flash_im_conversation | 前端 | 监听 conversationUpdateStream，本地更新 preview/time/unread |
| P-04 | 未读角标 | flash_im_conversation | 前端 | 头像右上角角标 + 底部导航 totalUnread |
| P-05 | 清除未读 | flash_im_conversation | 前端 | 进入聊天页时本地置 0 + 后端 POST read |
| P-10 | 未知会话骨架处理 | flash_im_conversation | 前端 | 收到未知会话 UPDATE 时骨架插入 + 异步拉取 D-11 补全 |

---

## 边界接口

### HTTP 接口

| 接口 | 提供节点 | 消费节点 |
|------|---------|---------|
| GET /conversations | D-02 | P-01 |
| POST /conversations | D-01 | P-01 |
| DELETE /conversations/:id | D-03 | P-01 |
| POST /conversations/:id/read | D-05 | P-05 |
| GET /conversations/:id | D-11 | P-10 |

---

## 版本演进

| 版本 | 变更 |
|------|------|
| v0.0.2 | 初始：D-01~D-03, P-01~P-02 |
| v0.0.3 | 新增 D-04 未读数管理、D-05 标记已读、P-03~P-05 会话实时更新/角标/清除未读 |
| v0.0.3-p1 | 新增 D-11 会话详情查询、P-10 未知会话骨架处理。flash_im_conversation 依赖从 flash_session 改为 flash_shared |
