# IM 图片展示优化 — 前端设计

版本：v0.35.0　日期：2026-06-15

---

## 一、目标

用 `tolyui_mediax` 替换当前的图片气泡展示和预览页，实现：

1. **气泡显示缩略图** — 加载快、省流量
2. **Hero 动画过渡** — 气泡 → 全屏预览平滑过渡
3. **多图滑动预览** — 左右滑动查看同会话所有图片
4. **下拉关闭** — DragDismiss 手势退出预览
5. **缓存加载** — 通过 CachedNetworkImage 缓存

---

## 二、依赖引入

```yaml
# flash_im_chat/pubspec.yaml
dependencies:
  tolyui_mediax_core: ^0.1.0
  tolyui_mediax_ui: ^0.1.0
  tolyui_mediax_image: ^0.1.0
  cached_network_image: ^3.3.0
```

---

## 三、架构设计

### 3.1 Resolver 注入（App 顶层）

参考：`docs/ref/tolyui_mediax_ui-0.1.0/example/lib/resolvers/cached_media_source_resolver.dart`

```dart
/// lib/src/application/media_resolver.dart

/// 持久化缓存管理器（Application Support 目录，不被系统清理）
class PersistentCacheManager extends CacheManager with ImageCacheManager {
  static const _key = 'mediaxPersistentCache';
  static PersistentCacheManager? _instance;
  factory PersistentCacheManager() => _instance ??= PersistentCacheManager._();
  PersistentCacheManager._() : super(Config(
    _key,
    stalePeriod: const Duration(days: 365),
    maxNrOfCacheObjects: 1000,
    fileSystem: _AppSupportFileSystem(_key),
  ));
}

/// Resolver 实现
class AppMediaSourceResolver extends DefaultMediaSourceResolver {
  const AppMediaSourceResolver();

  @override
  Widget resolveNetwork(BuildContext context, Uri uri, {...}) {
    return CachedNetworkImage(
      imageUrl: uri.toString(),
      httpHeaders: headers,
      cacheManager: PersistentCacheManager(),
      fit: fit, width: width, height: height,
      placeholder: (_, __) => _buildPlaceholder(context, placeholder, fit),
      errorWidget: (_, __, ___) => _buildError(),
      fadeInDuration: Duration.zero,   // 关闭渐入，Hero 更丝滑
      fadeOutDuration: Duration.zero,
    );
  }
}
```

关键点：
- 自定义缓存路径（Application Support），长期持久化
- `fadeInDuration: Duration.zero` — 不干扰 Hero 动画
- placeholder 支持先渲染缩略图再加载原图

### 3.2 Message → ImageMeta 转换

```dart
/// flash_im_chat/lib/src/data/message_media_ext.dart
extension MessageMediaExt on Message {
  /// 将图片消息转为 ImageMeta（用于 mediax 展示和预览）
  ImageMeta toImageMeta({required String baseUrl}) {
    final String thumbnailUrl = extra?['thumbnail_url'] as String? ?? content;
    final String sourceUrl = content;

    String fullUrl(String url) =>
        url.startsWith('/') ? '$baseUrl$url' : url;

    return ImageMeta(
      source: NetworkSource(Uri.parse(fullUrl(sourceUrl))),
      thumbnail: NetworkSource(Uri.parse(fullUrl(thumbnailUrl))),
      heroTag: 'img_$id',
      originalSize: (
        width: (extra?['width'] as num?)?.toInt() ?? 0,
        height: (extra?['height'] as num?)?.toInt() ?? 0,
      ),
    );
  }
}
```

### 3.3 ImageBubble 改造

参考：`docs/ref/tolyui_mediax_ui-0.1.0/example/lib/pages/im_chat_test_page.dart` 中的 `_ChatBubble`

```dart
class ImageBubble extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    // 发送中：本地文件预览 + 上传遮罩（不加 Hero）
    if (message.status == MessageStatus.sending) {
      return _buildLocalPreview();
    }

    final ImageMeta meta = message.toImageMeta(baseUrl: baseUrl ?? '');
    // 计算缩略图显示尺寸（限制最大 250×300，保持比例）
    final (double imgW, double imgH) = _calcSize(meta.originalSize);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: meta.heroTag ?? meta.hashCode,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: imgW,
            height: imgH,
            child: MediaImageView(
              meta: meta,
              level: MediaSourceLevel.thumbnail,  // 气泡用缩略图
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
```

尺寸计算逻辑（与案例一致）：
- 最大宽度 250，最大高度 300
- 按原图比例等比缩放，不放大
- 最小 60px（避免极小图看不清）

### 3.4 预览页改造

参考：`im_chat_test_page.dart` 的 `_openPreview` 方法

```dart
/// ChatMediaHandler.openImage 改造
void openImage(BuildContext context, Message msg, {List<Message>? imageMessages, int? index}) {
  final String baseUrl = this.baseUrl ?? '';
  final List<ImageMeta> items = (imageMessages ?? [msg])
      .map((m) => m.toImageMeta(baseUrl: baseUrl))
      .toList();
  final int initialIndex = index ?? 0;

  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => MediaPreviewPage(
        items: items,
        initialIndex: initialIndex,
        onDismiss: () => Navigator.of(context).pop(),
        itemBuilder: (ctx, i, item) {
          final ImageMeta imageMeta = item as ImageMeta;
          return ImageViewer(
            heroTag: imageMeta.heroTag ?? imageMeta.hashCode,
            mediaBuilder: (_, meta) => MediaImageView(
              meta: meta as ImageMeta,
              level: MediaSourceLevel.source,  // 预览用原图
              fit: BoxFit.contain,
            ),
            meta: imageMeta,
            imageSize: imageMeta.originalSize != null
                ? Size(
                    imageMeta.originalSize!.width.toDouble(),
                    imageMeta.originalSize!.height.toDouble(),
                  )
                : null,
          );
        },
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    ),
  );
}
```

关键点：
- `opaque: false` — 背景透明，配合 Hero 动画
- `ImageViewer` 需要 `imageSize` 参数用于缩放计算
- `mediaBuilder` 中用 `MediaImageView(level: source)` 加载原图
- `heroTag` 与气泡端一致，实现平滑过渡

---

## 四、数据流

```
气泡展示：Message.extra.thumbnail_url → NetworkSource → CachedNetworkImage（缩略图）
点击预览：收集会话中所有图片消息 → List<ImageMeta> → MediaPreviewPage
         Hero tag 匹配 → 平滑过渡
预览浏览：ZoomPageView 左右滑动 → 加载原图（source level）
退出预览：下拉手势 DragDismiss → Hero 动画回到气泡位置
```

---

## 五、变更范围

### 新增文件

| 文件 | 职责 |
|------|------|
| `client/lib/src/application/media_resolver.dart` | Resolver 实现 + Provider 包裹 |
| `flash_im_chat/lib/src/data/message_media_ext.dart` | Message → ImageMeta 转换 |

### 修改文件

| 文件 | 改动 |
|------|------|
| `client/lib/src/application/app.dart`（或 main） | 包裹 MediaSourceProvider |
| `flash_im_chat/lib/src/view/bubble/image_bubble.dart` | 改用 MediaImageView + Hero |
| `flash_im_chat/lib/src/logic/handler/chat_media_handler.dart` | openImage 改用 MediaPreviewPage |
| `flash_im_chat/pubspec.yaml` | 新增 mediax 依赖 |

### 可删除文件

| 文件 | 原因 |
|------|------|
| `flash_im_chat/lib/src/view/media/image_preview_page.dart` | 被 MediaPreviewPage 替代 |

---

## 六、发送中图片处理

发送中的图片（本地文件，未上传完）使用 `FileSource` 展示，不走网络：

```dart
// ImageBubble 中判断
if (message.status == MessageStatus.sending) {
  // 使用 FileSource 展示本地文件，不加 Hero（避免预览未完成的图）
  return Image.file(File(message.content), fit: BoxFit.cover);
}
```

---

## 七、多图列表来源

预览时需要"同会话所有图片消息"列表。两种方案：

**方案 A（简单）**：从当前 ChatLoaded.messages 中过滤 `type == image`
- 优点：实现简单，不需要额外查询
- 缺点：只能滑动已加载到内存的图片

**方案 B（完整）**：从本地数据库查询全量图片消息
- 优点：可以滑动所有历史图片
- 缺点：需要新增查询接口

**选择方案 A**——先用内存中已加载的消息，后续有需要再扩展为方案 B。

---

## 八、技术决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 图片缓存方案 | cached_network_image | 成熟、自带磁盘+内存缓存 |
| 气泡加载级别 | thumbnail | 快速展示，省流量 |
| 预览加载级别 | source（原图） | 全屏清晰 |
| Hero 动画 | heroTag = 'img_$messageId' | 唯一且稳定 |
| 多图范围 | 当前已加载消息 | 简单，够用 |
| 下拉关闭 | DragDismissWrapper | mediax 内置支持 |
