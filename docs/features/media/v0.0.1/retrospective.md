# fx_media v0.0.1 迭代复盘

## 概览

| 项目 | 内容 |
|------|------|
| 版本 | v0.38.0 |
| 分支 | v0.38.0 |
| 周期 | 2026-06-20（单日迭代） |
| 目标 | 新建 fx_media 统一媒体管理包，替代散落在多模块的下载/缓存/播放能力 |
| 结果 | 核心功能完成，额外发现并修复了 Android 后台 WS 断连问题 |

---

## 一、完成的工作

### 1.1 fx_media 包（新建）

| 子模块 | 文件 | 职责 |
|--------|------|------|
| FxMediaDownload | `src/download/` | 统一下载管理：队列 + 并发控制(5) + id 去重 + 进度流 + 磁盘缓存恢复 |
| FxMediaAudio | `src/audio/` | 全局音频播放器：播新停旧单例 + snapshotStream 状态流 |
| FxMediaImage | `src/image/` | 图片缓存 Widget + onCached 路径回调 + 全屏预览入口 |
| FxMediaVideo | `src/video/` | 全屏视频播放页（网络 URL + 本地文件双支持） |
| FxMediaFile | `src/file/` | 系统打开 / 另存为 / 打开文件夹 |

关键设计决策：
- 通过 `FxDownloadFunction` typedef 注入下载实现，不直接依赖 dio
- 缓存 id 使用 `fxMediaIdFromUrl(url)` 提取文件名（`uuid_ext` 格式），聊天和云空间共享同一份缓存
- 磁盘路径确定性：`{cacheDir}/{uuid_ext}.{ext}`，重启后可从 id 推算路径恢复缓存状态

### 1.2 迁移完成

| 模块 | 改动 |
|------|------|
| ChatMediaHandler | 改为调用 FxMedia.image/video/file/download |
| AudioBubble | 去掉内部 AudioPlayer，改用 FxMedia.audio + snapshotStream |
| ChatCubit._autoCacheImages | 改用 FxMedia.download.get |
| chat_file_mixin.downloadFile | 改用 FxMedia.download.stream（保留进度） |
| FileDetailCubit (flash_cloud) | 改用 FxMedia.download，共享聊天侧缓存 |
| main.dart | FxMedia.init() 替代 CloudDownloadManager().init() |

删除的文件：
- `CloudDownloadManager`（flash_cloud）
- `VideoPlayerPage`（flash_im_chat，被 FxVideoPlayerPage 替代）
- `globalFileCacheManager` 全局变量

### 1.3 新增功能

- **视频下载进度**（微信风格）：VideoBubble 气泡内半透明遮罩 + 圆形进度 + 百分比
- **云空间媒体预览**：视频点击播放、图片点击全屏、音频点击播放/暂停
- **WS 断线帧缓存**：pending queue + 重连后自动补发
- **前台恢复即时重连**：WidgetsBindingObserver 监听 AppLifecycleState.resumed
- **上传 broken pipe 重试**：通过秒传检查恢复

---

## 二、遇到的问题与解决

### 问题 1：视频下载没有进度展示

**现象**：点击视频气泡后一片空白等待，无进度反馈。

**根因**：ChatMediaHandler.openVideo 使用 `FxMedia.download.get()`（只返回最终结果），进度事件被丢弃。

**解决**：改为调用 `_cubit.downloadFile()` 触发已有的 `fileDownloads` 进度机制，VideoBubble 新增 `downloadInfo` 参数展示下载状态。

---

### 问题 2：下载后退出重进显示未下载

**现象**：视频下载成功，但退出聊天页重新进入后仍显示未下载状态。

**根因**：迁移时去掉了 `FileCacheManagerImpl`（它内部会调 `store.updateLocalData()` 写数据库）。新的 `updateMessageLocalData` 只更新了内存 State，没有持久化。

**解决**：在 `updateMessageLocalData`、`_updateVideoThumbnailPath`、`_updateLocalDataInState` 中都加上 `localStore?.updateLocalData(messageId, localDataJson)` 调用。

---

### 问题 3：聊天和云空间缓存不共享

**现象**：消息里下载的视频，在云空间文件详情页显示"未缓存"。

**根因**：两边传给 FxMedia.download 的 id 不同（消息侧用 messageId，云空间用 fileId.toString()）。

**解决**：统一用文件 URL 中提取的 `uuid_ext` 格式作为 id（`fxMediaIdFromUrl` 工具函数）。两边对同一个物理文件提取出相同的 id。

---

### 问题 4：视频只下载了 jpg（封面）

**现象**：下载视频实际得到的是封面图片文件。

**根因**：视频和封面共用同一个 UUID（仅扩展名不同）。最初 `fxMediaIdFromUrl` 去掉了扩展名，导致两者 id 相同，封面先缓存后视频被当作"已缓存"跳过。

**解决**：`fxMediaIdFromUrl` 返回 `uuid_ext` 格式（如 `abc-def_mp4`），下划线替代点号，保留扩展名区分不同文件类型。

---

### 问题 5：云空间重启后显示未缓存

**现象**：App 重启后云空间文件详情页显示"未缓存"，但文件实际在磁盘上。

**根因**：`FxMediaDownloadImpl._cacheMap` 是纯内存的，重启后清空。`localPath()` 和 `isCached()` 只查内存映射。

**解决**：内存 miss 时通过 `_buildSavePathFromId(id)` 推算磁盘路径，检查文件是否存在。`_buildSavePath` 和 `_buildSavePathFromId` 对同一 id 必须生成相同路径（修复了 id 含扩展名时重复追加 ext 的 bug）。

---

### 问题 6：云空间删除缓存后界面未更新

**现象**：点击"清除本地缓存"后，界面仍显示"已缓存"。

**根因**：`FileDetailState.copyWith(localPath: null)` 中 `localPath: localPath ?? this.localPath` 把 null 当作"未传参"处理，旧值被保留。

**解决**：使用 sentinel 模式区分"未传参"和"显式传 null"。

---

### 问题 7：Android 文件选择器/拍照导致 WS 断连 → 消息发送失败

**现象**：选择文件或拍照后发送消息失败，提示超时。

**根因**：Android 13/14 系统行为——App 进入后台（系统文件选择器/相机 Activity 在前台）时，底层 TCP 连接被系统回收。WebSocketChannel.stream 触发 onDone，channel 被 null 掉。回到前台后消息发送时 channel 已不存在。

**日志证据**：
```
FilePickerDelegate: File path:[...]
[D/WS] stream onDone
[D/WS] _onDisconnected called
[D/WS] _cleanup: channel=alive
[D/WS] scheduling reconnect in 1000ms
...
[D/WS] sendMessage: state=disconnected, channel=false
[W/WS] sendFrame DROPPED: channel=null
```

**解决**（方案 3：接受断连 + 快速重连 + 消息队列）：
1. **Pending Queue**：sendFrame 时如果 channel 为 null，帧入队而非丢弃（PING 除外）
2. **重连后 flush**：认证成功后自动补发所有 pending 帧
3. **前台恢复即时重连**：`WidgetsBindingObserver.didChangeAppLifecycleState(resumed)` 立即触发 connect，不等心跳超时

---

### 问题 8：拍照后图片上传 Broken pipe

**现象**：拍照后图片上传进度到 100% 但最终报错 `HttpException: Broken pipe`。

**根因**：不仅 WebSocket 被断，HTTP 连接也被系统回收了。上传数据已经到达后端（100%），但 HTTP response 回不来。

**解决**：catch 中检测 broken pipe 错误，通过 `checkHash`（秒传检查）验证后端是否已成功接收。如果命中（说明文件已在后端），走秒传分支恢复发送流程。

---

## 三、架构收益

| 改进 | 之前 | 之后 |
|------|------|------|
| 下载管理 | 两套重复实现（FileCacheManagerImpl + CloudDownloadManager） | 一套 FxMedia.download，两端共享 |
| 音频播放 | 每个 AudioBubble 独立 AudioPlayer | 全局单例，播新停旧 |
| 视频播放 | 只支持网络 URL | 支持网络 + 本地文件 |
| 缓存共享 | 聊天和云空间各自独立缓存，同文件可能缓存两份 | 统一 id，下载一次两端可见 |
| 预览复用 | 绑死在 flash_im_chat | fx_media 提供通用入口，云空间也能用 |
| WS 可靠性 | 断线时消息静默丢失 | pending queue + 自动重连 + 自动补发 |
| 上传容错 | broken pipe 直接失败 | 自动通过秒传恢复 |

---

## 四、遗留事项

| 项目 | 优先级 | 说明 |
|------|--------|------|
| 视频/文件上传 broken pipe 重试 | P1 | 当前只对图片实现了，视频和文件需要同样处理 |
| 清理调试日志 | P2 | ws_client.dart 中的 print 语句需要替换为 fx_logger 或删除 |
| Web 平台适配 | P3 | fx_media 当前只面向原生平台 |
| 图片预览保存到相册 | P3 | 后续版本迭代 |
| FileCacheManager 清理 | P3 | 接口和实现保留未删，后续确认无其他依赖后可移除 |

---

## 五、关键代码路径

```
packages/fx_media/lib/
├── fx_media.dart                         # barrel export
└── src/
    ├── fx_media_init.dart                # FxMedia.init + fxMediaIdFromUrl
    ├── download/fx_media_download_impl.dart  # 核心：队列+并发+磁盘恢复
    ├── audio/fx_media_audio_impl.dart    # 播新停旧单例
    ├── image/fx_cached_image.dart        # CachedNetworkImage + onCached
    ├── video/fx_video_player_page.dart   # 全屏播放（网络+本地）
    └── file/fx_media_file_impl.dart      # 平台原生文件操作

modules/flash_im_core/lib/src/logic/ws_client.dart
  → _pendingFrames / _flushPendingFrames / didChangeAppLifecycleState

modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart
  → _isBrokenPipe / broken pipe retry via checkHash
```
