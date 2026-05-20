# 聊天输入框优化 — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。

全局约束：
- UI 风格参考 `.kiro/skills/flash-im-ui-style`
- 日志使用 fx_logger
- 已有 14 个 ChatCubit 测试不能破坏

---

## 执行顺序

1. ✅ 任务 1 — 添加依赖（record, just_audio, permission_handler, path, flutter_svg）
2. ✅ 任务 2 — 输入栏样式改造（纯 UI）
3. ✅ 任务 3 — Emoji 面板
4. ✅ 任务 4 — 面板互斥切换逻辑 + TapRegion 点击外部收起
5. ✅ 任务 5 — RecordManager 录音管理器
6. ✅ 任务 6 — VoiceInputWidget 语音输入 UI
7. ✅ 任务 7 — ChatFileMixin 新增 sendAudioFromFile
8. ✅ 任务 8 — AudioBubble 语音气泡
9. ✅ 任务 9 — Proto 新增 AUDIO 类型 + 后端 generate_preview（已在第 5 步完成）
10. ✅ 任务 10 — 权限声明（Android/iOS）
11. ⬜ 任务 11 — 编译验证 + 测试 + 手动验收

---

## 任务 1：pubspec.yaml — 添加依赖 `⬜ 待处理`

文件：`client/modules/flash_im_chat/pubspec.yaml`

### 1.1 添加 dependencies `⬜`

```yaml
dependencies:
  # ... 现有依赖
  record: ^5.1.0
  just_audio: ^0.9.0
```

---

## 任务 2：chat_input.dart — 样式改造 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/chat_input.dart`（重写）

### 2.1 容器样式 `⬜`

- 外层容器背景 `Color(0xFFF6F6F6)`
- 顶部分割线 `Divider(height: 0.5, color: Color(0xFFDDDDDD))`
- padding: `horizontal: 4, vertical: 8`

### 2.2 输入框样式 `⬜`

- 白色背景，圆角 8
- 无边框（borderSide: none）
- contentPadding: `horizontal: 16, vertical: 8`
- minLines: 1, maxLines: 8（自适应高度）

### 2.3 按钮布局 `⬜`

左到右：麦克风 → 输入框 → 表情 → + → 发送（有文字时）

- 麦克风图标：`Icons.mic`，点击切换语音模式
- 表情图标：`Icons.emoji_emotions_outlined`，点击展开 emoji 面板
- `+` 图标：`Icons.add_circle_outline_rounded`，点击展开更多面板
- 发送按钮：蓝色圆角容器 + 白色"发送"文字，AnimatedSwitcher 滑入

### 2.4 保留现有功能 `⬜`

- onSend / onSendImage / onSendVideo / onSendFile 回调不变
- @提及逻辑不变
- 更多面板（照片/拍照/视频/文件）不变

---

## 任务 3：emoji_panel.dart — Emoji 面板 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/emoji_panel.dart`（新建）

### 3.1 常用表情数据 `⬜`

硬编码一组常用 emoji（约 40-60 个）：

```dart
const _commonEmojis = [
  '😀', '😂', '🥹', '😊', '😍', '🥰', '😘', '😜',
  '🤔', '😅', '😢', '😭', '😤', '🤗', '👍', '👎',
  '👏', '🙏', '💪', '❤️', '💔', '🔥', '🎉', '✨',
  '😱', '🙄', '😴', '🤮', '💩', '👻', '🐶', '🐱',
  // ...
];
```

### 3.2 EmojiPanel Widget `⬜`

```dart
class EmojiPanel extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  // GridView.builder，crossAxisCount: 8
  // 每个 emoji 是 GestureDetector + Text(fontSize: 28)
  // 容器背景 Color(0xFFF6F6F6)，高度 200
}
```

---

## 任务 4：chat_input.dart — 面板互斥切换 `⬜ 待处理`

### 4.1 状态管理 `⬜`

```dart
bool _showEmojiPanel = false;
bool _showMorePanel = false;
bool _isVoiceMode = false;
```

切换规则：
- 点击表情：`_showEmojiPanel = true, _showMorePanel = false, _isVoiceMode = false, unfocus`
- 点击 +：`_showMorePanel = true, _showEmojiPanel = false, _isVoiceMode = false, unfocus`
- 点击麦克风：`_isVoiceMode = true, _showEmojiPanel = false, _showMorePanel = false, unfocus`
- 点击输入框：`_showEmojiPanel = false, _showMorePanel = false`

### 4.2 面板容器 `⬜`

两个 AnimatedContainer（emoji + more），高度 200，同一时刻只有一个展开。

---

## 任务 5：record_manager.dart — 录音管理器 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/voice_input/record_manager.dart`（新建）

### 5.1 核心 API `⬜`

使用 `record` 包的 `AudioRecorder`，录制 WAV 格式，核心 API：

```dart
class RecordManager {
  Future<bool> startRecording({String? path});
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<String?> stopRecording();
  Future<void> cancelRecording();
}
```

使用 `record` 包的 `AudioRecorder`，录制 WAV 格式。

---

## 任务 6：voice_input_widget.dart — 语音输入 UI `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/voice_input/voice_input_widget.dart`（新建）

### 6.1 按住说话按钮 `⬜`

- GestureDetector 监听 onLongPressStart / onLongPressMoveUpdate / onLongPressEnd
- 按住时：背景变深，显示"松开 发送"
- 上滑时：显示"松开 取消"，背景变红
- 松手：根据位置决定发送或取消

### 6.2 波形动画（可选） `⬜`

简单的随机高度条形动画，录音中显示。

### 6.3 ImVoiceInput 封装 `⬜`

```dart
class ImVoiceInput extends StatefulWidget {
  final void Function(String path, int durationSeconds) onSendAudio;
}
```

内部管理 RecordManager + Stopwatch，松手时回调。

---

## 任务 7：chat_file_mixin.dart — 新增 sendAudioFromFile `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/logic/chat_file_mixin.dart`（修改）

### 7.1 新增方法 `⬜`

```dart
Future<void> sendAudioFromFile(String filePath, int durationMs) async {
  // 1. 创建本地消息（type=audio, content=filePath, extra={duration_ms}）
  // 2. emit 到列表
  // 3. 上传文件（复用 repository.uploadFile）
  // 4. WS 发送 type=AUDIO 消息
  // 5. setupTimeout
}
```

### 7.2 proto MessageType `⬜`

确认 `message.proto` 中 MessageType 有 AUDIO=4。如果没有需要在任务 9 中添加。

---

## 任务 8：audio_bubble.dart — 语音气泡 `⬜ 待处理`

文件：`client/modules/flash_im_chat/lib/src/view/bubble/audio_bubble.dart`（新建）

### 8.1 气泡 UI `⬜`

- 显示时长（如 "0:05"）
- 播放/暂停图标
- 点击播放音频（使用 just_audio）
- 气泡宽度按时长比例变化（最短 80，最长 200）

### 8.2 集成到 MessageBubble `⬜`

在 `message_bubble.dart` 的 switch 中新增 `MessageType.audio => AudioBubble(...)`。

---

## 任务 9：Proto + 后端 — AUDIO 类型 `✅ 已完成`

> 已在第 5 步（后端实现）中完成：
> - `proto/message.proto` 新增 `AUDIO = 4`
> - `server/modules/im-message/src/models.rs` generate_preview 新增 `4 => "[语音]"`
> - cargo build + clippy 通过

### 9.3 前端 proto 同步 `⬜`

重新生成前端的 protobuf dart 文件，确保 MessageType.AUDIO 可用。

---

## 任务 10：权限声明 `⬜ 待处理`

### 10.1 Android `⬜`

文件：`client/android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### 10.2 iOS `⬜`

文件：`client/ios/Runner/Info.plist`

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限来录制语音消息</string>
```

---

## 任务 11：最终验证 `⬜ 待处理`

### 11.1 flutter analyze `⬜`

期望：No issues found。

### 11.2 flutter test `⬜`

期望：14 个已有测试全部通过。

### 11.3 手动验收 `⬜`

按 design.md 验收标准逐项验证。

### 11.4 提交 `⬜`

```bash
git add -A && git commit -m "feat: redesign chat input with emoji panel and voice message"
```
