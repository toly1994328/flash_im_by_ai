# 图片预览体验升级 — 任务清单

前置：`analysis.md` + `client/design.md`

---

## 任务 1：添加依赖 `⬜`

**文件**：`client/modules/flash_im_chat/pubspec.yaml`

```yaml
dependencies:
  tolyui_mediax_core: ^0.1.0
  tolyui_mediax_ui: ^0.1.0
  tolyui_mediax_image: ^0.1.0
  cached_network_image: ^3.3.0
  flutter_cache_manager: ^3.4.1
  shimmer: ^3.0.0          # 已有则不重复添加
  path_provider: ^2.1.0    # 已有则不重复添加
  path: ^1.9.0
  file: ^7.0.0
```

执行 `flutter pub get`。

---

## 任务 2：实现 Resolver + PersistentCacheManager + 注入 `⬜`

**新建文件**：`client/lib/src/application/media_resolver.dart`

参考：`docs/ref/tolyui_mediax_ui-0.1.0/example/lib/resolvers/cached_media_source_resolver.dart`

包含：
- `PersistentCacheManager`：自定义缓存到 Application Support 目录
- `_AppSupportFileSystem`：自定义 FileSystem 实现
- `AppMediaSourceResolver extends DefaultMediaSourceResolver`：
  - 使用 PersistentCacheManager
  - fadeIn/fadeOut Duration.zero（不干扰 Hero）
  - placeholder 支持 shimmer 骨架屏
  - placeholder 支持先渲染缩略图

**修改文件**：`client/lib/src/application/app.dart`（或 main.dart）

在 Widget tree 顶层包裹 `MediaSourceProvider(resolver: const AppMediaSourceResolver())`。

---

## 任务 3：Message → ImageMeta 转换 `⬜`

**新建文件**：`flash_im_chat/lib/src/data/message_media_ext.dart`

```dart
extension MessageMediaExt on Message {
  ImageMeta toImageMeta({required String baseUrl}) {
    // thumbnail_url → thumbnail source
    // content → source
    // heroTag = 'img_$id'
    // originalSize from extra width/height
  }
}
```

---

## 任务 4：改造 ImageBubble `⬜`

**修改文件**：`flash_im_chat/lib/src/view/bubble/image_bubble.dart`

参考：`im_chat_test_page.dart` 中的 `_ChatBubble`

改动：
- 导入 `message_media_ext.dart` + `tolyui_mediax_core` + `tolyui_mediax_image`
- 已发送的图片：
  - 调用 `message.toImageMeta(baseUrl:)` 构建 ImageMeta
  - 计算显示尺寸（最大 250×300，保持比例，最小 60）
  - 用 `Hero(tag: meta.heroTag ?? meta.hashCode)` 包裹
  - 内部 `MediaImageView(meta:, level: thumbnail, fit: cover)`
- 发送中的图片：保持 `Image.file` 本地预览 + 上传进度遮罩（不加 Hero）
- 删除旧的 `Image.network` / `Image.file` 逻辑

---

## 任务 5：改造 ChatMediaHandler.openImage `⬜`

**修改文件**：`flash_im_chat/lib/src/logic/handler/chat_media_handler.dart`

参考：`im_chat_test_page.dart` 的 `_openPreview` 方法

改动：
- `openImage` 签名新增 `List<Message>? imageMessages` 和 `int? index` 参数
- 将图片消息列表转为 `List<ImageMeta>`（调用 `toImageMeta`）
- push `PageRouteBuilder(opaque: false, transitionDuration: 300ms)`
- pageBuilder 返回 `MediaPreviewPage(items:, initialIndex:, onDismiss:, itemBuilder:)`
- itemBuilder 返回 `ImageViewer(heroTag:, mediaBuilder:, meta:, imageSize:)`
  - `mediaBuilder` 中用 `MediaImageView(meta:, level: source, fit: contain)`
  - `imageSize` 从 `imageMeta.originalSize` 转 `Size`
- transitionsBuilder 用 `FadeTransition`
- heroTag 与 ImageBubble 一致（`meta.heroTag ?? meta.hashCode`）

---

## 任务 6：传入图片消息列表 `⬜`

**修改文件**：`flash_im_chat/lib/src/view/index/chat_page.dart`（`_buildMessageList` 中的 `onImageTap`）

改动：
- 从 `ChatLoaded.messages` 中过滤所有 `type == image` 的消息
- 计算当前点击图片在列表中的 index
- 传给 `_mediaHandler.openImage(context, msg, imageMessages: imageList, index: idx)`

---

## 任务 7：删除旧 ImagePreviewPage `⬜`

**删除文件**：`flash_im_chat/lib/src/view/media/image_preview_page.dart`

**修改文件**：`flash_im_chat/lib/flash_im_chat.dart`（移除 export）

---

## 任务 8：编译验证 `⬜`

- `flutter pub get`（flash_im_chat 模块）
- `dart analyze lib`（flash_im_chat 模块零错误）
- `dart analyze lib`（client 全量零错误）

---

## 执行顺序

```
1 (依赖) → 2 (Resolver) → 3 (转换) → 4 (气泡) → 5 (预览) → 6 (列表传入) → 7 (清理) → 8 (验证)
```

任务 1~3 是基础设施，4~6 是核心改造，7~8 是收尾。
