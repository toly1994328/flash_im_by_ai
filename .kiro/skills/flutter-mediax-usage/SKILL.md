---
name: "flutter-mediax-usage"
description: "使用 tolyui_mediax 实现媒体预览。适用于图片九宫格展示、全屏预览、手势缩放、视频播放、Hero 动画等场景。"
metadata:
  author: toly
  version: "0.1.0"
  tags: [mediax, image, video, preview, zoom, hero, gallery, flutter]
---

# tolyui_mediax 使用指南

## 适用版本

tolyui_mediax_core: 0.1.0 | tolyui_mediax_ui: 0.1.0 | tolyui_zoompager: 0.1.0

## 环境检查

检查项目是否包含 tolyui_mediax_ui 依赖：
- 没有 → 添加依赖
- 有但版本不同 → 提示用户升级

---

## 核心概念

| 概念 | 说明 |
|------|------|
| MediaSource | sealed class，数据源（Network/File/Asset/Memory） |
| MediaMeta | sealed class，元信息（ImageMeta/VideoMeta） |
| MediaSourceResolver | 图片渲染解析器（注入网络图片加载方案） |
| VideoPlayerResolver | 视频播放器工厂（注入具体播放器实现） |
| MediaPreviewPage | 全屏预览页面 |
| ImageViewer | 可缩放图片查看器 |
| ZoomPageView | 手势感知的 PageView（缩放与翻页联动） |
| PreviewConfig | 预览配置（纯 Dart 数据类） |

---

## 使用流程

```
1. 实现 Resolver    → 继承 DefaultMediaSourceResolver，覆写 resolveNetwork
2. 注入 Provider    → MaterialApp 顶层包裹 MediaSourceProvider
3. 构建 MediaMeta   → ImageMeta / VideoMeta 描述媒体数据
4. 展示图片         → MediaImageView / MediaImageTile
5. 全屏预览         → push MediaPreviewPage
```

---

## 1. 注入 Resolver

实现网络图片加载方案，注入到 Widget tree。

#[[file:references/resolver.md]]

---

## 2. 构建数据

用 MediaSource 和 MediaMeta 描述媒体资源。

#[[file:references/data_model.md]]

---

## 3. 图片展示

使用 MediaImageView 展示单张图片（自动通过 Resolver 加载）。

#[[file:references/image_view.md]]

---

## 4. 全屏预览

使用 MediaPreviewPage 实现全屏图片/视频预览。

#[[file:references/preview.md]]

---

## 5. 视频播放

注入 VideoPlayerResolver 实现视频播放。

#[[file:references/video.md]]

---

## API 速查

| API | 作用 |
|-----|------|
| `MediaSourceProvider(resolver:, child:)` | 注入图片解析器 |
| `VideoPlayerProvider(resolver:, child:)` | 注入视频播放器 |
| `MediaImageView(source:, fit:)` | 渲染单张图片 |
| `MediaImageTile(meta:, heroTag:)` | 带 Hero 的图片 tile |
| `MediaPreviewPage(items:, itemBuilder:)` | 全屏预览页 |
| `ImageViewer(mediaBuilder:, meta:)` | 可缩放图片 |
| `VideoViewer(meta:, autoPlay:)` | 视频查看器 |
| `DragDismissWrapper(child:, onDismiss:)` | 下拉关闭手势 |
| `ZoomPageView(controller:, itemBuilder:)` | 手势 PageView |
| `PreviewConfig(...)` | 预览配置 |

---

## 生成指导

1. MediaSource 使用 sealed class switch 穷尽匹配
2. 网络图片必须通过 Resolver 注入，库内不含任何网络库
3. VideoPlayerResolver 注入具体播放器（video_player/chewie 等）
4. Hero 动画的 tag 必须与 ImageMeta.heroTag 在 Grid 端一致
5. PreviewConfig 是纯 Dart 类，不含 Flutter Color/Duration
6. 显式声明所有类型
