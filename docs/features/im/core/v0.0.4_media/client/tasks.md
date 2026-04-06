# IM Core v0.0.4_media — 客户端任务清单

基于 [design.md](./design.md) 设计，列出需要创建/修改的具体细节。

全局约束：
- 状态管理使用 Cubit，不使用 Event 模式
- Message 模型不直接 import flash_im_core 的 proto 类型，用自定义 MessageType 枚举
- UI 风格延续 v0.0.3：蓝色主色 #3B82F6，灰色背景 #EDEDED
- 不实现语音消息、本地缓存、消息撤回、上传取消
- 自己发的图片/视频 content 始终保持本地路径，不替换为服务端 URL（避免闪烁）
- 上传蒙层在 uploadProgress >= 1.0 后消失，不等 ACK
- sending 状态始终显示左侧 loading 转圈
- 图片/视频占位尺寸从 extra 的 width/height 等比计算（限制在 250×300 内）
- 文件占位消息创建时读取本地文件大小
- 文件气泡未下载灰色调仅对接收方生效，自己发的始终白底
- 文件上传/下载进度用背景色填充（淡蓝色从左到右渐进）
- Android manifest 需要 `usesCleartextTraffic=true`（video_player 需要 HTTP 明文）

---

## 执行顺序

1. ✅ 任务 1 — pubspec.yaml 新增依赖（无依赖）
2. ✅ 任务 2 — Message 模型扩展（无依赖）
   - ✅ 2.1 MessageType 枚举
   - ✅ 2.2 VideoExtra / FileExtra 数据类
   - ✅ 2.3 Message 类扩展
3. ✅ 任务 3 — ChatState 扩展（依赖任务 2）
4. ✅ 任务 4 — WsClient.sendMessage 扩展（无依赖）
5. ✅ 任务 5 — MessageRepository 新增上传方法（依赖任务 2）
   - ✅ 5.1 上传结果类型
   - ✅ 5.2 uploadImage / uploadVideo / uploadFile
6. ✅ 任务 6 — ChatCubit 扩展（依赖任务 2~5）
   - ✅ 6.1 sendImageFromFile
   - ✅ 6.2 sendVideoFromFile
   - ✅ 6.3 sendFileFromPicker
   - ✅ 6.4 _handleIncomingMessage 解析 type/extra
7. ✅ 任务 7 — ChatInput 改造（依赖任务 6）
   - ✅ 7.1 回调签名扩展
   - ✅ 7.2 + 按钮 + 功能面板
8. ✅ 任务 8 — MessageBubble 扩展（依赖任务 2）
   - ✅ 8.1 按 type 分发
   - ✅ 8.2 图片气泡
   - ✅ 8.3 视频气泡
   - ✅ 8.4 文件卡片
   - ✅ 8.5 上传进度指示器
9. ✅ 任务 9 — 图片全屏预览页（依赖任务 8）
10. ✅ 任务 10 — 视频播放页（依赖任务 8）
11. ✅ 任务 11 — ChatPage 集成（依赖任务 6~10）
12. ✅ 任务 12 — barrel 文件更新（依赖任务 9、10）
13. ✅ 任务 13 — Dart proto 重新生成（依赖后端 proto 变更）
14. ✅ 任务 14 — 文件预览页（依赖任务 5）
   - ✅ 14.1 FilePreviewPage 页面
   - ✅ 14.2 ChatPage 接入 onFileTap
   - ✅ 14.3 barrel 文件补充 export
15. ✅ 任务 15 — 编译验证 + 测试路径

---

## 任务 1：pubspec.yaml — 新增依赖 `⬜ 待处理`

文件：`client/modules/flash_im_chat/pubspec.yaml`（修改）

### 1.1 新增 dependencies `⬜`

在 dependencies 中新增：

```yaml
image_picker: ^1.1.2
file_picker: ^8.1.7
video_player: ^2.9.2
fc_native_video_thumbnail: ^0.6.0
```

之后在 client/ 目录执行 `flutter pub get`。

---

## 任务 2：message.dart — Message 模型扩展 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/message.dart`（修改）

### 2.1 MessageType 枚举 `⬜`

在文件顶部（MessageStatus 之后）新增：

```dart
enum MessageType { text, image, video, file }
```

### 2.2 VideoExtra / FileExtra 数据类 `⬜`

在 MessageType 之后新增两个数据类：

```dart
class VideoExtra {
  final String thumbnailUrl;
  final int durationMs;
  final int width;
  final int height;
  final int fileSize;

  const VideoExtra({
    required this.thumbnailUrl,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.fileSize,
  });

  factory VideoExtra.fromJson(Map<String, dynamic> json) → ...
  Map<String, dynamic> toJson() → ...

  /// 格式化时长 "1:23"
  String get formattedDuration → ...
}

class FileExtra {
  final String fileName;
  final int fileSize;
  final String fileUrl;
  final String fileType;

  const FileExtra({...});

  factory FileExtra.fromJson(Map<String, dynamic> json) → ...
  Map<String, dynamic> toJson() → ...

  /// 格式化大小 "1.5 MB"
  String get formattedSize → ...
}
```

### 2.3 Message 类扩展 `⬜`

Message 类新增字段和方法：

```dart
class Message {
  // ... 已有字段 ...
  final MessageType type;                    // 新增，默认 text
  final Map<String, dynamic>? extra;         // 新增

  // 便捷 getter
  bool get isText => type == MessageType.text;
  bool get isImage => type == MessageType.image;
  bool get isVideo => type == MessageType.video;
  bool get isFile => type == MessageType.file;

  VideoExtra? get videoExtra → 从 extra 解析，isVideo 时有效
  FileExtra? get fileExtra → 从 extra 解析，isFile 时有效
}
```

需要同步修改：
- 构造函数：新增 `this.type = MessageType.text` 和 `this.extra` 参数
- `fromJson`：解析 `msg_type`（int → MessageType）和 `extra`（dynamic → Map?）
- `Message.sending`：新增 `type` 和 `extra` 参数
- `copyWith`：新增 `type`、`extra` 参数

msg_type 映射：0=text, 1=image, 2=video, 3=file

---

## 任务 3：chat_state.dart — ChatLoaded 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_state.dart`（修改）

### 3.1 新增 uploadProgress 字段 `⬜`

ChatLoaded 新增：

```dart
class ChatLoaded extends ChatState {
  // ... 已有 ...
  final double? uploadProgress;  // 新增：0.0~1.0，null=不在上传中

  ChatLoaded copyWith({
    // ... 已有 ...
    double? uploadProgress,
    bool clearUploadProgress = false,  // 用于清除进度（设为 null）
  }) → ...
}
```

props 中加入 uploadProgress。

---

## 任务 4：ws_client.dart — sendMessage 扩展 `⬜ 待处理`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（修改）

### 4.1 sendMessage 新增 type 和 extra 参数 `⬜`

当前签名：

```dart
void sendMessage({
  required String conversationId,
  required String content,
  String? clientId,
})
```

改为：

```dart
void sendMessage({
  required String conversationId,
  required String content,
  msg.MessageType type = msg.MessageType.TEXT,
  List<int>? extra,
  String? clientId,
})
```

方法体中：
- `req.type = type`（替换硬编码的 `msg.MessageType.TEXT`）
- 如果 `extra != null`，设置 `req.extra = extra`

---

## 任务 5：message_repository.dart — 新增上传方法 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/data/message_repository.dart`（修改）

### 5.1 上传结果类型 `⬜`

在文件中新增三个结果类：

```dart
class ImageUploadResult {
  final String originalUrl;
  final String thumbnailUrl;
  final int width;
  final int height;
  final int size;
  final String format;

  factory ImageUploadResult.fromJson(Map<String, dynamic> json) → ...
}

class VideoUploadResult {
  final String videoUrl;
  final String thumbnailUrl;
  final int durationMs;
  final int width;
  final int height;
  final int fileSize;

  factory VideoUploadResult.fromJson(Map<String, dynamic> json) → ...
}

class FileUploadResult {
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final String fileType;

  factory FileUploadResult.fromJson(Map<String, dynamic> json) → ...
}
```

### 5.2 上传方法 `⬜`

MessageRepository 新增三个方法：

```dart
/// 上传图片
Future<ImageUploadResult> uploadImage(
  String filePath, {
  void Function(double progress)? onProgress,
}) async
```
1. 从 filePath 提取 fileName
2. 构造 FormData：`file: MultipartFile.fromFile(filePath, filename: fileName)`
3. POST `/api/upload/image`，传入 onSendProgress 回调
4. 解析响应为 ImageUploadResult

```dart
/// 上传视频（视频 + 缩略图 + 元数据）
Future<VideoUploadResult> uploadVideo(
  String videoPath,
  String thumbnailPath,
  int durationMs, {
  void Function(double progress)? onProgress,
}) async
```
1. 构造 FormData：`video: MultipartFile`、`thumbnail: MultipartFile`、`duration_ms: String`
2. POST `/api/upload/video`，传入 onSendProgress 回调
3. 解析响应为 VideoUploadResult

```dart
/// 上传文件
Future<FileUploadResult> uploadFile(
  String filePath, {
  void Function(double progress)? onProgress,
}) async
```
1. 构造 FormData：`file: MultipartFile`
2. POST `/api/upload/file`，传入 onSendProgress 回调
3. 解析响应为 FileUploadResult

需要新增 import：`import 'package:dio/dio.dart' show FormData, MultipartFile;`

---

## 任务 6：chat_cubit.dart — 富媒体发送方法 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_cubit.dart`（修改）

需要新增 import：`import 'dart:convert';`

### 6.1 sendImageFromFile `✅`

```dart
Future<void> sendImageFromFile(String filePath) async
```

逻辑步骤：
1. 创建占位消息：`Message.sending(type: MessageType.image, content: filePath)`
2. emit 追加到列表
3. try: `_repository.uploadImage(filePath, onProgress: ...)` → emit uploadProgress
4. 清除 uploadProgress
5. 不替换 content（保持本地路径，UI 始终显示本地图片，避免闪烁）
6. 只更新 extra（宽高等信息供后续使用）
7. 记录 pendingMessages[clientId] = localId
8. `_wsClient.sendMessage(type: IMAGE, content: result.originalUrl, extra: json_bytes)`（WS 发送用服务端 URL）
9. 设置 10s 超时
10. catch: 标记占位消息为 failed + 清除 uploadProgress

### 6.2 sendVideoFromFile `⬜`

```dart
Future<void> sendVideoFromFile(String filePath, String thumbnailPath, int durationMs) async
```

逻辑步骤：
1. 创建占位消息：`Message.sending(type: video, content: thumbnailPath)`
2. emit 追加到列表
3. try: `_repository.uploadVideo(videoPath, thumbPath, durationMs, onProgress: ...)` → emit uploadProgress
4. 清除 uploadProgress
5. 构建 VideoExtra，更新占位消息的 content 和 extra
6. 记录 pendingMessages，WS 发送（type: VIDEO, extra: VideoExtra json bytes）
7. 设置 30s 超时（视频上传耗时更长）
8. catch: 标记 failed + 清除 uploadProgress

### 6.3 sendFileFromPicker `⬜`

```dart
Future<void> sendFileFromPicker(String filePath) async
```

逻辑步骤：
1. 从 filePath 提取 fileName
2. 创建占位消息：`Message.sending(type: file, content: fileName, extra: {file_name, file_type})`
3. emit 追加到列表
4. try: `_repository.uploadFile(filePath, onProgress: ...)` → emit uploadProgress
5. 清除 uploadProgress
6. 构建 FileExtra，更新占位消息的 content 和 extra
7. 记录 pendingMessages，WS 发送（type: FILE, extra: FileExtra json bytes）
8. 设置 30s 超时
9. catch: 标记 failed + 清除 uploadProgress

### 6.4 _handleIncomingMessage 解析 type/extra `⬜`

当前代码直接构造 Message 时没有 type 和 extra。修改为：

1. 从 `chatMsg.type` 转换为本地 MessageType：

```dart
final msgType = switch (chatMsg.type.value) {
  1 => MessageType.image,
  2 => MessageType.video,
  3 => MessageType.file,
  _ => MessageType.text,
};
```

2. 从 `chatMsg.extra` 解析 extra：

```dart
Map<String, dynamic>? extra;
if (chatMsg.extra.isNotEmpty) {
  try { extra = jsonDecode(utf8.decode(chatMsg.extra)); } catch (_) {}
}
```

3. 构造 Message 时传入 `type: msgType, extra: extra`

---

## 任务 7：chat_input.dart — + 按钮 + 功能面板 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（修改）

### 7.1 回调签名扩展 `⬜`

ChatInput 新增回调参数：

```dart
class ChatInput extends StatefulWidget {
  final ValueChanged<String> onSend;           // 已有：发送文本
  final ValueChanged<String>? onSendImage;     // 新增：图片路径
  final ValueChanged<String>? onSendVideo;     // 新增：视频路径
  final ValueChanged<String>? onSendFile;      // 新增：文件路径
}
```

### 7.2 + 按钮 + 功能面板 `⬜`

UI 改造：

1. 在输入框左侧（或发送按钮右侧）新增"+"图标按钮
2. 点击"+"切换功能面板的显示/隐藏（AnimatedContainer）
3. 功能面板：Container 高度 200，背景 #F6F6F6，GridView 2×2 布局

面板项：

| 图标 | 标签 | 点击行为 |
|------|------|---------|
| Icons.photo_library | 照片 | `ImagePicker().pickImage(source: ImageSource.gallery)` → `onSendImage(path)` |
| Icons.camera_alt | 拍照 | `ImagePicker().pickImage(source: ImageSource.camera)` → `onSendImage(path)` |
| Icons.videocam | 视频 | `ImagePicker().pickVideo(source: ImageSource.gallery)` → `onSendVideo(path)` |
| Icons.file_present_rounded | 文件 | `FilePicker.platform.pickFiles()` → `onSendFile(path)` |

选择完成后自动关闭面板（`setState(() => _showMorePanel = false)`）。

需要新增 import：
```dart
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
```

---

## 任务 8：message_bubble.dart — 按类型分发渲染 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/message_bubble.dart`（修改）

### 8.1 新增回调参数 + 按 type 分发 `⬜`

MessageBubble 新增参数：

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onImageTap;    // 新增
  final VoidCallback? onVideoTap;    // 新增
  final VoidCallback? onFileTap;     // 新增
  final String? baseUrl;             // 新增：拼接相对路径 URL
  final double? uploadProgress;      // 新增：上传进度
}
```

`_buildBubble()` 方法改为按 type 分发：

```dart
Widget _buildBubble() {
  if (message.isImage) return _buildImageContent();
  if (message.isVideo) return _buildVideoContent();
  if (message.isFile) return _buildFileContent();
  return _buildTextBubble();  // 已有
}
```

### 8.2 图片气泡 `⬜`

```dart
Widget _buildImageContent()
```

- Container：maxWidth 250, maxHeight 300, padding 2, 圆角 8, 薄边框 #DEE0E2
- ClipRRect 圆角 6
- Image.network(imageUrl, fit: BoxFit.cover)
  - imageUrl = baseUrl != null && content.startsWith('/') ? '$baseUrl$content' : content
  - loadingBuilder：灰色占位 200×150 + 小 CircularProgressIndicator
  - errorBuilder：灰色占位 + broken_image 图标
- GestureDetector onTap → onImageTap

### 8.3 视频气泡 `⬜`

```dart
Widget _buildVideoContent()
```

- Container：同图片的边框样式
- Stack：
  - 底层：缩略图 Image.network(videoExtra.thumbnailUrl)，宽 200
  - 中层：半透明圆形播放按钮（黑色 40% 透明 + 白色 play_arrow 图标）
  - 底层：渐变遮罩 + 右下角时长文字（videoExtra.formattedDuration）
- GestureDetector onTap → onVideoTap

### 8.4 文件卡片 `⬜`

```dart
Widget _buildFileContent()
```

- Container：宽 237, padding 12, 白底, 圆角 6, 薄边框 #DEE0E2
- Row：
  - Expanded Column：文件名（14px, 单行省略）+ 文件大小（12px, #999）
  - SizedBox(width: 8)
  - 文件图标（40×40 圆角方块，按扩展名着色）
    - pdf → red, doc/docx → blue, xls/xlsx → green, zip/rar → amber, 其他 → grey
- GestureDetector onTap → onFileTap

### 8.5 上传进度指示器 + 状态图标 `✅`

上传蒙层策略：
- 条件：`uploadProgress != null && uploadProgress < 1.0 && message.status == MessageStatus.sending`
- 进度到 100% 后蒙层立刻消失，不等 ACK
- 图片/视频气泡：在缩略图上叠加半透明黑色遮罩 + CircularProgressIndicator(value: uploadProgress)
- 文件卡片：在卡片底部显示 LinearProgressIndicator(value: uploadProgress)

左侧状态图标策略：
- sending 状态始终显示 loading 转圈（不受 uploadProgress 影响）
- failed 状态显示红色感叹号
- sent 状态不显示

图片本地预览策略：
- 自己发的图片：content 始终保持本地路径，用 Image.file() 显示
- 接收的图片：content 是服务端 URL，用 Image.network() + Stack 占位（避免加载前尺寸为 0）
- 占位尺寸从 extra 的 width/height 等比计算（限制在 250×300 内）

---

## 任务 9：image_preview_page.dart — 图片全屏预览 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/image_preview_page.dart`（新建）

### 9.1 页面结构 `⬜`

```dart
class ImagePreviewPage extends StatelessWidget {
  final String imageUrl;
  const ImagePreviewPage({super.key, required this.imageUrl});
}
```

- Scaffold：黑色背景，AppBar 透明
- body：InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain))
- 点击空白区域或返回按钮关闭

---

## 任务 10：video_player_page.dart — 视频播放页 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/video_player_page.dart`（新建）

### 10.1 页面结构 `⬜`

```dart
class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerPage({super.key, required this.videoUrl});
}
```

- initState：创建 VideoPlayerController.networkUrl(Uri.parse(videoUrl))，initialize 后 setState
- build：Scaffold 黑色背景
  - Center：AspectRatio + VideoPlayer
  - 底部：播放/暂停按钮 + VideoProgressIndicator
- dispose：controller.dispose()

---

## 任务 11：chat_page.dart — 集成 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

### 11.1 ChatInput 回调接入 `⬜`

ChatInput 新增回调连接到 ChatCubit：

```dart
ChatInput(
  onSend: (content) => context.read<ChatCubit>().sendMessage(content),
  onSendImage: (path) => context.read<ChatCubit>().sendImageFromFile(path),
  onSendVideo: (path) async {
    // 提取视频信息后调用 sendVideoFromFile
    final info = await VideoThumbnailService().extractVideoInfo(path);
    context.read<ChatCubit>().sendVideoFromFile(path, info.thumbnailPath, info.durationMs);
  },
  onSendFile: (path) => context.read<ChatCubit>().sendFileFromPicker(path),
)
```

### 11.2 MessageBubble 传参 `⬜`

在 _buildMessageList 中，MessageBubble 传入新参数：

```dart
MessageBubble(
  message: msg,
  isMe: isMe,
  baseUrl: 'http://${config.host}:${config.port}',  // 从 ImConfig 获取
  uploadProgress: (state is ChatLoaded) ? state.uploadProgress : null,
  onImageTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ImagePreviewPage(imageUrl: fullUrl),
  )),
  onVideoTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => VideoPlayerPage(videoUrl: fullUrl),
  )),
  onFileTap: () { /* 后续实现下载 */ },
)
```

### 11.3 VideoThumbnailService `⬜`

在 chat_page.dart 或单独文件中引入视频信息提取：

```dart
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
```

VideoThumbnailService 类（可放在 data/ 目录）：

```dart
class VideoThumbnailService {
  Future<VideoInfo> extractVideoInfo(String videoPath) async
}

class VideoInfo {
  final String thumbnailPath;
  final int durationMs;
}
```

逻辑：
1. `FcNativeVideoThumbnail().getVideoThumbnail(srcFile, destFile, format: 'jpeg', width: 384, height: 384)`
2. `VideoPlayerController.file(File(videoPath))` → initialize → `value.duration.inMilliseconds` → dispose

---

## 任务 12：barrel 文件更新 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`（修改）

### 12.1 新增 export `⬜`

```dart
export 'src/view/image_preview_page.dart';
export 'src/view/video_player_page.dart';
```

---

## 任务 13：Dart proto 重新生成 `⬜ 待处理`

### 13.1 重新生成 message.pb.dart `⬜`

后端已扩展 proto/message.proto 的 MessageType 枚举（IMAGE=1, VIDEO=2, FILE=3）。需要重新生成 Dart protobuf 代码：

```bash
protoc --dart_out=client/modules/flash_im_core/lib/src/data/proto --proto_path=proto message.proto ws.proto
```

生成后确认 `message.pbenum.dart` 中包含 IMAGE、VIDEO、FILE 枚举值。

---

## 任务 14：文件预览页 + 下载 `⬜ 待处理`

### 14.1 FilePreviewPage `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/file_preview_page.dart`（新建）

```dart
class FilePreviewPage extends StatefulWidget {
  final FileExtra fileExtra;
  final String baseUrl;
}
```

页面结构：
- AppBar：标题 "文件详情"
- body 居中卡片：
  - 文件图标（同 MessageBubble 的 _buildFileIcon，按扩展名着色，大号 64px）
  - 文件名（16px，最多 2 行）
  - 文件大小（14px，灰色）
  - 文件类型（14px，灰色）
- 底部按钮区：
  - idle 状态：蓝色"下载"按钮
  - downloading 状态：进度条 + 百分比文字
  - done 状态：绿色"已下载"+ 本地路径文字
  - error 状态：红色错误提示 + "重试"按钮

下载逻辑（页面内自管理，不经过 ChatCubit）：
1. 拼接完整 URL：`baseUrl + fileExtra.fileUrl`
2. 获取下载目录：`getTemporaryDirectory()`（或 `getApplicationDocumentsDirectory()`）
3. savePath = `${dir.path}/${fileExtra.fileName}`
4. `Dio().download(fullUrl, savePath, onReceiveProgress: ...)` 更新进度
5. 完成后 setState 显示本地路径

需要 import：`dio`、`path_provider`、`../data/message.dart`

### 14.2 ChatPage 接入 onFileTap `⬜`

文件：`client/modules/flash_im_chat/lib/src/view/chat_page.dart`（修改）

当前 onFileTap 为空。改为：

```dart
onFileTap: () {
  final fileExtra = msg.fileExtra;
  if (fileExtra != null) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FilePreviewPage(
        fileExtra: fileExtra,
        baseUrl: widget.baseUrl ?? '',
      ),
    ));
  }
},
```

需要新增 import：`import 'file_preview_page.dart';`

### 14.3 barrel 文件补充 `⬜`

文件：`client/modules/flash_im_chat/lib/flash_im_chat.dart`（修改）

新增：
```dart
export 'src/view/file_preview_page.dart';
```

---

## 任务 15：编译验证 + 测试路径 `⬜ 待处理`

### 15.1 编译验证 `✅`

```bash
cd client
flutter analyze
```

预期：零 error。

### 15.2 手动测试路径 `⬜`

1. 启动服务端 + 客户端
2. 进入聊天页，点击"+"按钮，确认功能面板弹出（照片/拍照/视频/文件）
3. 选择图片 → 消息出现（带进度）→ 发送成功 → 点击图片进入全屏预览
4. 选择视频 → 消息出现（缩略图+进度）→ 发送成功 → 点击播放
5. 选择文件 → 消息出现（文件名+图标+进度）→ 发送成功
6. 点击文件卡片 → 进入文件预览页 → 显示文件名/大小/类型
7. 点击下载按钮 → 显示下载进度 → 下载完成显示本地路径
8. 用 Python 脚本从另一个用户发送图片/视频/文件消息 → 当前用户实时收到并正确渲染
9. 退出聊天页重新进入 → 历史消息正确渲染各类型
10. 断网发送 → 消息标记为 failed
