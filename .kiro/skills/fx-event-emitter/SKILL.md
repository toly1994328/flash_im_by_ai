---
name: fx-event-emitter
description: FxEvent 全局事件总线使用规范。在需要跨模块通信（举报、拉黑、导航、toast 等）且不想通过回调层层传递时激活，确保使用正确的事件定义、发送和监听模式。
metadata:
  model: manual
  last_modified: Wed, 11 Jun 2026 00:00:00 GMT

---

# FxEvent 全局事件总线

## 适用场景

- 模块 A 需要触发模块 B 的行为，但 A 不依赖 B（如 `flash_im_friend` 触发 `flash_im_chat` 的举报 Sheet）
- 底层组件需要通知顶层做 UI 操作（toast、弹窗、导航），不想层层回调
- 跨页面通信（如注销后通知所有页面刷新）

## 不适用场景

- 同模块内部通信 → 用 Cubit/State
- 父子 Widget 通信 → 用回调参数
- 只是数据读取 → 用 Repository / Provider

## 核心组件

### FxEmitter — 全局单例事件总线

位置：`client/modules/flash_shared/lib/src/fx_emitter.dart`

```dart
class FxEmitter {
  factory FxEmitter() => _instance;       // 单例
  Stream<FxEvent> get stream;              // 全部事件流
  StreamSubscription<E> on<E extends FxEvent>(void Function(E) handler);  // 按类型监听
  void emit(FxEvent event);               // 发送事件
}
```

### FxEvent — 事件基类

```dart
class FxEvent {
  const FxEvent();
  void emit() => FxEmitter().emit(this);  // 便捷发送
}
```

## 使用模式

### 1. 定义事件

在 `flash_shared/lib/src/fx_emitter.dart` 底部或独立文件中定义：

```dart
/// 举报用户事件
class ReportUserEvent extends FxEvent {
  final String userId;
  final String nickname;
  const ReportUserEvent({required this.userId, required this.nickname});
}

/// 拉黑用户事件
class BlockUserEvent extends FxEvent {
  final String userId;
  final String nickname;
  const BlockUserEvent({required this.userId, required this.nickname});
}
```

事件定义放在 `flash_shared` 中（底层包），保证所有模块都能访问。

### 2. 发送事件（任何模块）

```dart
// 一行搞定，不需要 context、不需要回调、不需要依赖上层模块
ReportUserEvent(userId: '123', nickname: '张三').emit();
```

### 3. 监听事件（App 顶层装配）

在 `home_page.dart` 或 App shell 的 `initState` 中：

```dart
final List<StreamSubscription<dynamic>> _eventSubs = [];

void _setupEventListeners() {
  _eventSubs.add(FxEmitter().on<ReportUserEvent>((ReportUserEvent e) {
    // 弹举报 Sheet、调 API、toast...
  }));
  _eventSubs.add(FxEmitter().on<BlockUserEvent>((BlockUserEvent e) async {
    await dio.post('/api/blocks', data: {'blocked_id': int.parse(e.userId)});
    // toast
  }));
}

@override
void dispose() {
  for (final sub in _eventSubs) { sub.cancel(); }
  super.dispose();
}
```

### 4. 用 Mixin 简化监听（可选）

参考 fx_trace 的 `FxEmitterMixin`：

```dart
mixin FxEmitterMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<FxEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = FxEmitter().stream.listen(onEvent);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void onEvent(FxEvent event);  // 子类实现
}
```

### 5. AsyncFxEvent — 等待处理结果（高级）

当发送方需要等待处理结果时：

```dart
class PickFileEvent extends AsyncFxEvent<String?> {}

// 发送并等待
final String? path = await PickFileEvent().emitAsync(timeout: Duration(seconds: 30));

// 处理方
FxEmitter().on<PickFileEvent>((e) {
  final result = await showFilePicker();
  e.complete(result);
});
```

## 设计原则

| 原则 | 说明 |
|------|------|
| 事件只携带数据 | 事件类只有 final 字段，不带逻辑 |
| 发送方不关心谁处理 | emit 后就完事，解耦 |
| 监听方集中在顶层 | 避免散落各处，装配逻辑清晰 |
| 订阅必须取消 | dispose 中 cancel，成对出现 |
| 事件定义在底层包 | 放 `flash_shared`，所有模块可见 |

## 与其他机制的对比

| 机制 | 适用 | 方向 |
|------|------|------|
| FxEvent | 跨模块、跨页面 | 任意 → 任意 |
| Cubit emit | 同模块内状态管理 | Logic → View |
| 回调参数 | 父子 Widget | Child → Parent |
| WS Stream | 服务端推送 | Server → Client |

## 当前已定义事件

| 事件 | 发送方 | 处理方 | 用途 |
|------|--------|--------|------|
| `ReportUserEvent` | user_profile_page | home_page | 弹举报 Sheet |
| `BlockUserEvent` | user_profile_page | home_page | 调拉黑 API + toast |
