# 综合搜索 — 客户端局域网络

涉及节点：F-14、P-44 ~ P-47

---

## 一、远景：模块与依赖

### 涉及模块

| 模块 | 位置 | 职责 |
|------|------|------|
| flash_im_search | client/modules/flash_im_search/ | 搜索数据层 + 逻辑层 + 视图层 |

### 节点详情

| 编号 | 功能节点 | 模块 | 职责 |
|------|---------|------|------|
| F-14 | 搜索模块 | flash_im_search | SearchRepository（四个 API）+ SearchCubit（300ms 防抖 + 三路并发） |
| P-44 | 综合搜索页 | flash_im_search/search_page | 搜索历史 + 分区结果（联系人/群聊/聊天记录） |
| P-45 | 消息搜索详情页 | flash_im_search/message_detail_page | 某会话匹配消息列表（分页加载） |
| P-46 | 会话内搜索页 | flash_im_search/conversation_search_page | 单会话内搜索 + 300ms 防抖 |
| P-47 | 单条消息详情页 | flash_im_search/single_message_page | 展示消息完整信息（发送者 + 内容高亮 + 时间） |

---

## 三、近景：生命周期与订阅

### 核心对象生命周期

| 对象 | 创建时机 | 销毁时机 | 生命跨度 |
|------|---------|---------|---------|
| SearchCubit | SearchPage 创建时（BlocProvider） | SearchPage 销毁时 | 页面级 |
| SearchCubit._debounceTimer | search() 调用 | close() 或下次 search() | 页面级 |
| ConversationSearchPage._debounceTimer | onChanged 调用 | dispose() | 页面级 |

---

## 四、版本演进

| 版本 | 变更 |
|------|------|
| v0.0.1_search | 初始实现：SearchRepository + SearchCubit + SearchPage + MessageDetailPage（分页）+ ConversationSearchPage + SingleMessagePage + HighlightText + 搜索历史 |
