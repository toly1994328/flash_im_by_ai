# 图片预览体验升级 — 任务清单

前置：`analysis.md` + `client/design.md`

---

## 任务 1：添加依赖 `✅`

tolyui_mediax_core/ui/image + cached_network_image + flutter_cache_manager + file

---

## 任务 2：实现 Resolver + PersistentCacheManager + 注入 `✅`

- `client/lib/src/application/media_resolver.dart`
- App 顶层 MediaSourceProvider 注入

---

## 任务 3：Message → ImageMeta 转换 `✅`

- `flash_im_chat/lib/src/data/message_media_ext.dart`
- 支持本地文件优先（FileSource）

---

## 任务 4：改造 ImageBubble `✅`

- MediaImageView + Hero + BubbleSize 尺寸策略
- 淡边框（0x1A000000, 0.5px）
- 发送中用 Image.file + 上传遮罩

---

## 任务 5：改造 ChatMediaHandler.openImage `✅`

- MediaPreviewPage + ImageViewer + FadeTransition
- 多图滑动（从已加载消息中过滤）
- Hero tag 一致

---

## 任务 6：传入图片消息列表 `✅`

---

## 任务 7：删除旧 ImagePreviewPage `✅`

---

## 任务 8：编译验证 `✅`

---

## 额外完成项

| 项目 | 说明 |
|------|------|
| BubbleSize 独立文件 | 尺寸策略内聚（250×300/min80/极端裁剪） |
| 发送前读取图片宽高 | 发送中气泡尺寸立即正确 |
| 上传完后更新 content | 图片/视频 content 从本地路径更新为服务器 URL |
| 本地文件优先 | 有 localData.path 时用 FileSource 跳过网络 |
| 后端缩略图 200→400px | 2x 屏清晰 |
| 视频气泡优化 | BubbleSize + 淡边框 + 封面图缓存 + 播放/下载图标区分 |
| 视频 localData 两字段 | path(视频) + thumbnail_path(封面) 分离 |
| pendingLocalPaths 修正 | 视频存视频路径而非缩略图 |
| sqlite3 缓存修复脚本 | fix_sqlite3_cache.py |
