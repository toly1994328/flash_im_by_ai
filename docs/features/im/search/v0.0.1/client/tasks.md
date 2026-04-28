# 综合搜索 — 客户端任务清单

基于 [design.md](design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 新建 flash_im_search 模块，不修改已有模块的内部逻辑
- 搜索模块通过回调与外部通信（onFriendTap / onGroupTap / onMessageTap）
- 搜索历史用 SharedPreferences 本地存储
- 关键词高亮用 RichText + TextSpan

---

## 执行顺序

1. ✅ 任务 1 — 创建 flash_im_search 模块骨架
2. ✅ 任务 2 — 数据模型（search_models.dart）
3. ✅ 任务 3 — SearchRepository（三个搜索 API + 会话内搜索）
4. ✅ 任务 4 — SearchCubit + SearchState（300ms 防抖 + 并发 + 部分失败）
5. ✅ 任务 5 — HighlightText 组件
6. ✅ 任务 6 — 搜索结果子组件（FriendSearchItem / GroupSearchItem / MessageSearchItem）
7. ✅ 任务 7 — SearchPage（综合搜索页 + 搜索历史）
8. ✅ 任务 8 — MessageDetailPage（消息搜索详情页，分页加载，每页 20 条）
9. ✅ 任务 9 — ConversationSearchPage（会话内搜索页）
10. ✅ 任务 10 — SingleMessagePage（单条消息详情页）
11. ✅ 任务 11 — 详情页集成"查找聊天内容"入口（单聊 + 群聊）
12. ✅ 任务 12 — home_page 集成（消息 Tab + 通讯录 Tab 搜索栏 + SearchRepository 注入）
13. ✅ 任务 13 — FlashSearchInput 背景色参数 + 搜索页统一使用
14. ✅ 任务 14 — 编译验证（flutter analyze 通过，无 error）

---

## 任务 1：创建模块骨架 `⬜ 待处理`

### 1.1 pubspec.yaml `⬜`

```yaml
name: flash_im_search
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.0
  shared_preferences: ^2.5.0
  flash_shared:
    path: ../flash_shared
```

### 1.2 barrel export `⬜`

```dart
// flash_im_search.dart
export 'src/data/search_models.dart';
export 'src/data/search_repository.dart';
export 'src/logic/search_cubit.dart';
export 'src/logic/search_state.dart';
export 'src/view/search_page.dart';
export 'src/view/message_detail_page.dart';
export 'src/view/conversation_search_page.dart';
```

### 1.3 主项目 pubspec.yaml 添加依赖 `⬜`

```yaml
flash_im_search:
  path: modules/flash_im_search
```

---

## 任务 2：数据模型 `⬜ 待处理`

文件：`flash_im_search/lib/src/data/search_models.dart`

### 2.1 FriendSearchItem `⬜`

```dart
class FriendSearchItem {
    final String friendId;
    final String nickname;
    final String? avatar;
}
```

### 2.2 GroupSearchItem `⬜`

```dart
class GroupSearchItem {
    final String conversationId;
    final String? name;
    final String? avatar;
    final int memberCount;
}
```

### 2.3 MessageSearchItem `⬜`

```dart
class MessageSearchItem {
    final String messageId;
    final String senderName;
    final String? senderAvatar;
    final String content;
    final DateTime createdAt;
    final int? seq;  // 会话内搜索时有值
}
```

### 2.4 MessageSearchGroup `⬜`

```dart
class MessageSearchGroup {
    final String conversationId;
    final String conversationName;
    final String? conversationAvatar;
    final int convType;
    final int matchCount;
    final List<MessageSearchItem> messages;
}
```

### 2.5 SearchResult `⬜`

```dart
class SearchResult {
    final List<FriendSearchItem> friends;
    final List<GroupSearchItem> groups;
    final List<MessageSearchGroup> messageGroups;
    final String? friendError;
    final String? groupError;
    final String? messageError;
    bool get allSuccess => ...;
    bool get hasAnyResult => ...;
}
```

---

## 任务 3：SearchRepository `⬜ 待处理`

文件：`flash_im_search/lib/src/data/search_repository.dart`

四个方法，每个方法封装一个 HTTP GET 请求：

- `searchFriends({keyword, limit})` → `GET /api/friends/search`
- `searchJoinedGroups({keyword, limit})` → `GET /api/conversations/search-joined-groups`
- `searchMessages({keyword, limit})` → `GET /api/messages/search`
- `searchConversationMessages({conversationId, keyword, limit})` → `GET /conversations/{id}/messages/search`

使用 `http` 包或项目已有的 HTTP 客户端。

---

## 任务 4：SearchCubit + SearchState `⬜ 待处理`

### 4.1 SearchState `⬜`

```dart
sealed class SearchState {}
class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchSuccess extends SearchState { final SearchResult result; }
class SearchPartialSuccess extends SearchState { final SearchResult result; }
```

### 4.2 SearchCubit `⬜`

- 300ms 防抖（Timer）
- `search(keyword)` → 防抖后调 `_doSearch`
- `_doSearch` → Future.wait 并发三个 API，各自 try-catch
- `clear()` → emit SearchInitial
- `close()` → cancel Timer

---

## 任务 5：HighlightText 组件 `⬜ 待处理`

文件：`flash_im_search/lib/src/view/widgets/highlight_text.dart`

```dart
class HighlightText extends StatelessWidget {
    final String text;
    final String keyword;
    final TextStyle? style;
    final TextStyle? highlightStyle;
    final int? maxLines;
}
```

用 RichText + TextSpan，匹配部分用主题蓝（0xFF3B82F6）高亮。

---

## 任务 6：搜索结果子组件 `⬜ 待处理`

### 6.1 FriendSearchItemWidget `⬜`

头像 + 昵称（高亮关键词），点击回调。

### 6.2 GroupSearchItemWidget `⬜`

群头像 + 群名（高亮）+ 成员数，点击回调。

### 6.3 MessageSearchItemWidget `⬜`

会话头像 + 会话名 + 最近一条匹配消息预览（高亮）+ 匹配数，点击回调。

---

## 任务 7：SearchPage `⬜ 待处理`

文件：`flash_im_search/lib/src/view/search_page.dart`

### 7.1 页面结构 `⬜`

- AppBar：搜索输入框 + 取消按钮
- Body：BlocBuilder<SearchCubit, SearchState>
  - SearchInitial → 搜索历史
  - SearchLoading → 加载指示器
  - SearchSuccess / SearchPartialSuccess → 分区结果

### 7.2 搜索历史 `⬜`

- SharedPreferences 存储，key = `im_search_history`
- 最多 20 条，去重置顶
- Wrap 流式布局，灰色圆角 tag
- 清空按钮

### 7.3 分区结果 `⬜`

- 联系人区：标题 + FriendSearchItemWidget 列表 + "查看更多"
- 群聊区：标题 + GroupSearchItemWidget 列表 + "查看更多"
- 聊天记录区：标题 + MessageSearchItemWidget 列表 + "查看更多"
- 每区默认 3 条，展开后全部

### 7.4 回调 `⬜`

```dart
final void Function(String friendId)? onFriendTap;
final void Function(String conversationId)? onGroupTap;
final void Function(String conversationId, String? messageId)? onMessageTap;
```

---

## 任务 8：MessageDetailPage `⬜ 待处理`

文件：`flash_im_search/lib/src/view/message_detail_page.dart`

- AppBar 标题：会话名
- ListView：匹配消息列表（头像 + 昵称 + 内容高亮 + 时间）
- 点击回调：onMessageTap(conversationId, messageId)

---

## 任务 9：ConversationSearchPage `⬜ 待处理`

文件：`flash_im_search/lib/src/view/conversation_search_page.dart`

- AppBar：搜索输入框
- 300ms 防抖调 `SearchRepository.searchConversationMessages`
- ListView：匹配消息列表（头像 + 昵称 + 内容高亮 + 时间 + seq）
- 点击回调：onMessageTap(conversationId, messageId)

---

## 任务 10：详情页集成 `⬜ 待处理`

### 10.1 PrivateChatInfoPage `⬜`

在成员网格下方新增设置项："查找聊天内容"，点击跳转 ConversationSearchPage。

### 10.2 GroupChatInfoPage `⬜`

在群设置项中新增："查找聊天内容"，点击跳转 ConversationSearchPage。

---

## 任务 11：home_page 集成 `⬜ 待处理`

消息 Tab 的 FlashSearchBar（占位模式）点击后跳转 SearchPage。
SearchPage 的回调在 home_page 中实现导航逻辑。

---

## 任务 12：编译验证 `⬜ 待处理`

```bash
flutter analyze
```
