# IM Core — 客户端任务清单

基于 design.md 设计，列出需要创建/修改的具体细节。
三层架构：data / logic / view，与 flash_auth、flash_session 保持一致。
WsClient 通过 tokenProvider 闭包获取 Token，不依赖 SessionCubit。

---

## 执行顺序

1. ✅ 任务 1 — 添加 web_socket_channel 依赖（无依赖）
2. ✅ 任务 2 — ImConfig 配置类（无依赖）
3. ✅ 任务 3 — WsClient WebSocket 管理器（依赖任务 1、2）
   - ✅ 3.1 连接状态枚举
   - ✅ 3.2 WsClient 类骨架
   - ✅ 3.3 连接与认证
   - ✅ 3.4 心跳保活（含 PING/PONG 日志）
   - ✅ 3.5 断线重连（指数退避）
   - ✅ 3.6 帧收发与事件分发
4. ✅ 任务 4 — WsStatusIndicator 连接状态指示器（依赖任务 3）
5. ✅ 任务 5 — barrel 导出更新（依赖任务 2、3、4）
6. ✅ 任务 6 — main.dart 集成（依赖任务 5）
7. ✅ 任务 7 — HomePage 集成（依赖任务 4、6）
   - ✅ 7.1 消息 Tab 顶部栏（用户头像 + 昵称 + 连接状态圆点）
   - ✅ 7.2 自定义底部导航栏（白色背景 + 顶部细线）
   - ✅ 7.3 状态栏样式（透明 + 深色图标）
8. ✅ 任务 8 — 退出登录断开连接（依赖任务 6）
9. ✅ 任务 9 — 编译验证

---

## 任务 1：pubspec.yaml — 添加依赖 `⬜`

文件：`client/modules/flash_im_core/pubspec.yaml`（修改）

### 1.1 新增 web_socket_channel `⬜`

在 dependencies 中添加：

```yaml
  web_socket_channel: ^3.0.3
```

---

## 任务 2：im_config.dart — IM 配置 `⬜`

文件：`client/modules/flash_im_core/lib/src/data/im_config.dart`（新建）

### 2.1 ImConfig 类 `⬜`

```dart
class ImConfig {
  final String wsUrl;
  final Duration heartbeatInterval;
  final int heartbeatTimeout;
  final Duration reconnectBaseDelay;
  final Duration reconnectMaxDelay;

  const ImConfig({
    required this.wsUrl,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.heartbeatTimeout = 3,
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.reconnectMaxDelay = const Duration(seconds: 30),
  });
}
```

---

## 任务 3：ws_client.dart — WebSocket 管理器 `⬜`

文件：`client/modules/flash_im_core/lib/src/logic/ws_client.dart`（新建）

### 3.1 连接状态枚举 `⬜`

```dart
enum WsConnectionState {
  disconnected,
  connecting,
  authenticating,
  authenticated,
}
```

### 3.2 WsClient 类骨架 `⬜`

```dart
typedef TokenProvider = String? Function();

class WsClient {
  final ImConfig _config;
  final TokenProvider _tokenProvider;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  int _missedPongs = 0;
  bool _intentionalDisconnect = false;
  WsConnectionState _state = WsConnectionState.disconnected;

  // 连接状态流
  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get stateStream => _stateController.stream;
  WsConnectionState get state => _state;

  // 帧流
  final _frameController = StreamController<WsFrame>.broadcast();
  Stream<WsFrame> get frameStream => _frameController.stream;

  WsClient({required ImConfig config, required TokenProvider tokenProvider})
      : _config = config, _tokenProvider = tokenProvider;

  // 方法签名见下方子任务
  Future<void> connect() async { ... }
  void disconnect() { ... }
  void sendFrame(WsFrame frame) { ... }
  void dispose() { ... }
}
```

### 3.3 连接与认证 `⬜`

`connect()` 方法逻辑步骤：

1. 如果已连接，直接返回
2. 设置 `_intentionalDisconnect = false`
3. 更新状态为 `connecting`
4. 创建 WebSocketChannel.connect(config.wsUrl)
5. 更新状态为 `authenticating`
6. 构建 AUTH 帧：WsFrame(type=AUTH, payload=AuthRequest(token).writeToBuffer())
7. 通过 channel.sink.add 发送 AUTH 帧的二进制数据
8. 监听 channel.stream，等待第一条消息
9. 解码为 WsFrame，检查 type == AUTH_RESULT
10. 解码 payload 为 AuthResult
11. 如果 success == true：更新状态为 `authenticated`，启动心跳，开始监听后续帧
12. 如果 success == false：更新状态为 `disconnected`

### 3.4 心跳保活 `⬜`

`_startHeartbeat()` 方法：

1. 取消已有的心跳定时器
2. 重置 `_missedPongs = 0`
3. 启动 Timer.periodic(config.heartbeatInterval)
4. 每次触发：发送 PING 帧，`_missedPongs++`
5. 如果 `_missedPongs >= config.heartbeatTimeout`：判定断线，调用 `_onDisconnected()`

收到 PONG 帧时：`_missedPongs = 0`

### 3.5 断线重连 `⬜`

`_onDisconnected()` 方法：

1. 停止心跳定时器
2. 关闭 channel
3. 更新状态为 `disconnected`
4. 如果 `_intentionalDisconnect == true`，不重连，直接返回
5. 计算延迟：`min(baseDelay * 2^attempts, maxDelay)`
6. 启动 `_reconnectTimer = Timer(delay, () => connect())`
7. `_reconnectAttempts++`

`connect()` 成功后：`_reconnectAttempts = 0`

`disconnect()` 方法：

1. `_intentionalDisconnect = true`
2. 取消重连定时器
3. 停止心跳
4. 关闭 channel
5. 更新状态为 `disconnected`

### 3.6 帧收发与事件分发 `⬜`

消息监听逻辑（认证成功后启动）：

1. 监听 channel.stream
2. 收到 Binary 数据 → 解码为 WsFrame
3. 如果 type == PONG：重置 `_missedPongs`
4. 其他类型：通过 `_frameController.add(frame)` 广播给业务层
5. stream done（连接断开）：调用 `_onDisconnected()`

`sendFrame(WsFrame frame)` 方法：

1. 将 frame 编码为二进制：`frame.writeToBuffer()`
2. 通过 `_channel?.sink.add(bytes)` 发送

---

## 任务 4：ws_status_indicator.dart — 连接状态指示器 `⬜`

文件：`client/modules/flash_im_core/lib/src/view/ws_status_indicator.dart`（新建）

### 4.1 WsStatusIndicator 组件 `⬜`

```dart
class WsStatusIndicator extends StatelessWidget {
  final Stream<WsConnectionState> stateStream;
  final WsConnectionState initialState;
  final VoidCallback? onTapReconnect;

  // StreamBuilder 监听 stateStream
  // authenticated 状态：返回 SizedBox.shrink()（隐藏）
  // disconnected 状态：红色背景条，文字"连接已断开"，点击触发 onTapReconnect
  // connecting 状态：橙色背景条，文字"正在连接..."
  // authenticating 状态：橙色背景条，文字"正在认证..."
}
```

组件特点：
- 使用 StreamBuilder 监听状态变化
- authenticated 时完全隐藏（SizedBox.shrink），不占空间
- 非 authenticated 时显示为全宽横条，高度约 32px
- disconnected 状态可点击手动重连

---

## 任务 5：flash_im_core.dart — barrel 导出更新 `⬜`

文件：`client/modules/flash_im_core/lib/flash_im_core.dart`（修改）

### 5.1 新增导出 `⬜`

```dart
// data
export 'src/data/proto/ws.pb.dart';
export 'src/data/proto/ws.pbenum.dart';
export 'src/data/im_config.dart';

// logic
export 'src/logic/ws_client.dart';

// view
export 'src/view/ws_status_indicator.dart';
```

---

## 任务 6：main.dart — 集成 WsClient `⬜`

文件：`client/lib/main.dart`（修改）

### 6.1 创建 WsClient `⬜`

在 main() 中，sessionCubit 创建之后，创建 WsClient：

```dart
import 'package:flash_im_core/flash_im_core.dart';

// 在 sessionCubit 创建之后
final wsClient = WsClient(
  config: ImConfig(wsUrl: 'ws://${AppConfig.host}:${AppConfig.port}/ws/im'),
  tokenProvider: () => sessionCubit.token,
);
```

### 6.2 登录后连接 `⬜`

在 `onLoginSuccess` 回调中，activate 之后调用 connect：

```dart
onLoginSuccess: (loginResult) async {
  await sessionCubit.activate(
    token: loginResult.token,
    hasPassword: loginResult.hasPassword,
  );
  wsClient.connect();  // 新增
  router.go('/home');
},
```

### 6.3 启动恢复时连接 `⬜`

在 `onStartupComplete` 中，如果已认证也要连接：

```dart
onStartupComplete: (results) {
  final authenticated = results[RestoreSessionTask] as bool;
  if (authenticated) {
    wsClient.connect();  // 新增
  }
  router.go(authenticated ? '/home' : '/login');
},
```

### 6.4 传递 wsClient 给子树 `⬜`

需要让 HomePage 能访问 wsClient。可以通过 Provider 或直接传参。
简单方案：用 RepositoryProvider 包裹：

```dart
runApp(
  MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: sessionCubit),
      RepositoryProvider.value(value: wsClient),  // 新增
    ],
    child: BlocProvider.value(
      value: sessionCubit,
      child: FlashApp(router: router),
    ),
  ),
);
```

注意：退出登录时需要断开连接。当前项目的退出逻辑在 ProfilePage 中，需要在退出时调用 `wsClient.disconnect()`。具体实现取决于退出登录的触发点，可通过 context.read\<WsClient\>().disconnect() 调用。

---

## 任务 7：home_page.dart — 集成指示器 `⬜`

文件：`client/lib/src/home/view/home_page.dart`（修改）

### 7.1 在 Scaffold body 顶部添加 WsStatusIndicator `⬜`

```dart
import 'package:flash_im_core/flash_im_core.dart';

// 在 build 方法中，Scaffold 的 body 改为 Column：
body: Column(
  children: [
    WsStatusIndicator(
      stateStream: context.read<WsClient>().stateStream,
      initialState: context.read<WsClient>().state,
      onTapReconnect: () => context.read<WsClient>().connect(),
    ),
    Expanded(
      child: IndexedStack(index: _currentIndex, children: pages),
    ),
  ],
),
```

---

## 任务 8：编译验证 `⬜`

### 8.1 依赖解析 `⬜`

```powershell
cd client
flutter pub get
```

### 8.2 代码分析 `⬜`

```powershell
flutter analyze
```

预期：零 error。

### 8.3 功能验证路径 `⬜`

1. 启动后端：`powershell -ExecutionPolicy Bypass -File scripts/server/start.ps1`
2. 启动客户端：`powershell -ExecutionPolicy Bypass -File scripts/client/run.ps1`
3. 登录后观察：
   - 主界面顶部指示器短暂显示"正在连接..."/"正在认证..."后消失
   - 后端控制台打印 `✅ [im-ws] user X connected`
4. 关闭后端，观察：
   - 指示器显示"连接已断开，正在重连..."
   - 重启后端后，指示器消失，后端打印重新连接日志
5. 退出登录，观察：
   - 后端打印 `❌ [im-ws] user X disconnected`
   - 不再触发重连
