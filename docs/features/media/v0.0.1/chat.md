# fx_media — 统一媒体管理包设计讨论

## 背景

闪讯项目中媒体播放/预览/下载/缓存能力散落在多个模块，存在重复实现和碎片化问题：
- 两套下载缓存（FileCacheManager + CloudDownloadManager），核心逻辑重复
- 三层图片缓存（PersistentCacheManager + FileCacheManager + CloudDownloadManager），同一文件可能缓存多份
- 音频无全局管理（每个 AudioBubble 各自创建 AudioPlayer，无"播新停旧"）
- 预览能力绑死 flash_im_chat，云空间等场景无法复用

## 目标

构建一个**项目无关**的通用媒体管理包 `fx_media`，放在 `packages/fx_media/` 下，任何 Flutter 项目都可以使用。统一接口风格，一套 API 覆盖下载/缓存/播放/预览/打开。

## 已确认决策

| 决策 | 结论 |
|------|------|
| 包名 | `fx_media` |
| 位置 | `packages/fx_media/`（和 fx_logger 同级） |
| 业务无关 | 不依赖任何闪讯业务模型 |
| 图片缓存 | 底层用 `flutter_cache_manager`（CachedNetworkImage 共享缓存池） |
| 图片预览 | 复用 `tolyui_mediax` 接口 |
| 音频播放 | 简单内部播放/暂停（播新停旧），不做通知栏控制 |
| 下载进度 | Stream 方式暴露给外界 |
| 资源标识 | 下载必须携带 `id`（String），不传时默认取 url |
| 缓存路径回调 | 图片展示后回调本地路径，用于更新消息 localData |

## 统一 API 设计

### 入口

```dart
class FxMedia {
  static late final FxMediaDownload download;
  static late final FxMediaAudio audio;
  static late final FxMediaVideo video;
  static late final FxMediaImage image;
  static late final FxMediaFile file;

  static void init({
    required String cacheDir,
    int maxConcurrent = 3,
  });
}
```

### 下载管理（FxMediaDownload）

```dart
// 流式下载（带进度）
Stream<FxDownloadEvent> stream = FxMedia.download.stream(url: '...', id: 'msg_123');

// 便捷获取（只等结果）
Future<String> path = FxMedia.download.get(url: '...', id: 'msg_123');

// 状态查询
bool cached = FxMedia.download.isCached('msg_123');
String? path = FxMedia.download.localPath('msg_123');

// 缓存管理
FxMedia.download.remove('msg_123');
FxMedia.download.cancel('msg_123');
```

事件模型：
```dart
sealed class FxDownloadEvent {
  final String id;
  final String url;
}
class FxDownloadProgress extends FxDownloadEvent { final double progress; }
class FxDownloadComplete extends FxDownloadEvent { final String localPath; }
class FxDownloadError extends FxDownloadEvent { final Object error; }
```

id 可选，不传时默认取 url。

### 音频播放（FxMediaAudio）

```dart
// 播放（自动停止当前正在播的）
FxMedia.audio.play(url);
FxMedia.audio.playFile(localPath);

// 控制
FxMedia.audio.pause();
FxMedia.audio.stop();

// 状态
FxMedia.audio.currentUrl     → String?
FxMedia.audio.stateStream    → Stream<FxAudioState>

enum FxAudioState { idle, playing, paused, completed, error }
```

### 视频播放（FxMediaVideo）

```dart
// 跳转全屏播放页
FxMedia.video.open(context, url);
FxMedia.video.openFile(context, localPath);
```

### 图片预览（FxMediaImage）

```dart
// 全屏预览（多图滑动）
FxMedia.image.preview(context, urls, initialIndex: 0);

// 缓存图片 Widget（渲染同时回调本地路径）
FxMedia.image.widget(
  url: '...',
  id: 'msg_123',
  fit: BoxFit.cover,
  onCached: (String localPath) { /* 更新 localData */ },
);
```

### 文件打开（FxMediaFile）

```dart
// 系统打开
FxMedia.file.open(localPath);

// 另存为
FxMedia.file.saveAs(localPath);

// 打开所在文件夹（桌面端）
FxMedia.file.openFolder(localPath);
```

## 包结构

```
packages/fx_media/
├── pubspec.yaml
└── lib/
    ├── fx_media.dart                    # barrel export + FxMedia 入口
    └── src/
        ├── download/
        │   ├── fx_media_download.dart   # 下载管理核心
        │   ├── fx_download_event.dart   # 事件模型
        │   └── download_task.dart       # 下载任务内部模型
        ├── audio/
        │   ├── fx_media_audio.dart      # 全局音频播放器
        │   └── fx_audio_state.dart      # 状态枚举
        ├── video/
        │   └── fx_video_player_page.dart # 全屏视频播放页
        ├── image/
        │   ├── fx_media_image.dart      # 图片预览 + Widget
        │   └── fx_cached_image.dart     # FxCachedImage Widget
        └── file/
            └── fx_media_file.dart       # 文件打开/另存为

```

## 外部依赖

| 依赖 | 用途 | 说明 |
|------|------|------|
| flutter_cache_manager | 下载+缓存存储后端 | 成熟稳定，CachedNetworkImage 共享 |
| cached_network_image | 图片 Widget | 市场检验，不重复造轮子 |
| just_audio | 音频播放 | 轻量，跨平台 |
| video_player | 视频播放 | Flutter 官方 |
| tolyui_mediax_core | 图片预览接口 | 已有，复用 |
| tolyui_mediax_ui | 预览页面组件 | 已有，复用 |
| open_file | 系统打开文件 | 移动端 |

## 闪讯集成后的改动

| 模块 | 改动 |
|------|------|
| flash_im_chat | ChatMediaHandler 改为调用 FxMedia.video/image/file/audio |
| flash_im_chat | AudioBubble 改为调用 FxMedia.audio（去掉内部 AudioPlayer） |
| flash_im_chat | ImageBubble 改为 FxMedia.image.widget（回调 localPath） |
| flash_cloud | CloudDownloadManager 删除，改用 FxMedia.download |
| flash_im_cache | FileCacheManager 内部下载逻辑委托给 FxMedia.download |
| 主应用 | main.dart 初始化 FxMedia.init() |
| 主应用 | media_resolver.dart 可能简化或删除（PersistentCacheManager 由 fx_media 管理） |

## 需要注意的点

1. **缓存目录统一**：当前 FileCacheManager 存在 `Application Support/UserData/{uid}/`，PersistentCacheManager 存在 `Application Support/mediaxPersistentCache/`，CloudDownloadManager 存在 `Application Cache/cloud_cache/`。统一后需要确定是一个目录还是分类子目录。建议：统一在 `flutter_cache_manager` 管理的目录下，按 id hash 自动组织，不自己管路径。

2. **迁移兼容**：现有消息的 `localData` 存的是旧路径，迁移后路径可能变化。需要策略：
   - 方案 A：新下载走新路径，旧缓存不迁移（旧路径还在就直接用）
   - 方案 B：首次启动扫描迁移（复杂，不建议）
   - 建议选 A。

3. **并发与去重**：`flutter_cache_manager` 内部已有 URL 去重和并发控制。`fx_media` 如果再加一层 id 级别的去重（同一 id 不重复触发），两层配合不冲突。

4. **视频播放器**：当前 `VideoPlayerPage` 只支持网络 URL，不支持本地文件路径（用的 `VideoPlayerController.networkUrl`）。迁移到 `fx_media` 时需要支持本地文件（`VideoPlayerController.file`）。

5. **图片预览的 Hero 动画**：当前通过 `ImageMeta.heroTag` 实现。`fx_media` 的 `image.preview` 需要支持传入 heroTag 列表，保持动画衔接。

6. **这个迭代的范围**：
   - ✅ 新建 `packages/fx_media/` 实现全部 5 个子模块
   - ✅ 迁移 flash_im_chat 的媒体操作到 FxMedia
   - ✅ 迁移 flash_cloud 的下载管理到 FxMedia
   - ✅ 全链路验证（聊天收发图片/视频/音频/文件 + 云空间下载）
   - ❌ 不迁移旧缓存数据（兼容策略：旧路径有效就用）

7. **本次不是纯前端改动**：后端无需改动，纯客户端重构。不需要 server/design.md 和 server/tasks.md。
