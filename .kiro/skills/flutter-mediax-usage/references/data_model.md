```dart
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

// === 数据源 ===

// 网络图片
const MediaSource networkImg = NetworkSource(
  Uri.parse('https://example.com/photo.jpg'),
  headers: {'Authorization': 'Bearer token'},
);

// 本地文件
const MediaSource localImg = FileSource('/data/photos/img_001.jpg');

// Asset 资源
const MediaSource assetImg = AssetSource('assets/images/logo.png');

// === 图片元信息 ===

const ImageMeta imageMeta = ImageMeta(
  source: NetworkSource(Uri.parse('https://example.com/photo.jpg')),
  thumbnail: NetworkSource(Uri.parse('https://example.com/photo_thumb.jpg')),
  raw: NetworkSource(Uri.parse('https://example.com/photo_raw.jpg')),
  heroTag: 'photo_1',
  originalSize: (width: 1920, height: 1080),
);

// === 视频元信息 ===

const VideoMeta videoMeta = VideoMeta(
  source: NetworkSource(Uri.parse('https://example.com/video.mp4')),
  thumbnail: NetworkSource(Uri.parse('https://example.com/video_cover.jpg')),
  duration: Duration(seconds: 120),
  heroTag: 'video_1',
);

// === 带业务附加数据 ===

class ChatExtra {
  final String messageId;
  final String senderId;
  const ChatExtra({required this.messageId, required this.senderId});
}

final ImageMeta<ChatExtra> chatImage = ImageMeta<ChatExtra>(
  source: const NetworkSource(Uri.parse('https://example.com/chat_img.jpg')),
  extra: const ChatExtra(messageId: 'msg_1', senderId: 'user_1'),
);

// === switch 穷举 ===

String describeSource(MediaSource source) {
  return switch (source) {
    NetworkSource(:final uri) => '网络: $uri',
    FileSource(:final path) => '本地: $path',
    AssetSource(:final assetPath) => 'Asset: $assetPath',
    MemorySource(:final bytes) => '内存: ${bytes.length} bytes',
  };
}
```
