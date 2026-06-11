import 'dart:async';

/// 轻量全局事件总线
///
/// 任意模块 emit 事件，顶层监听处理。解耦模块间依赖。
/// 用法：
///   定义事件：class MyEvent extends FxEvent { ... }
///   发送：MyEvent(...).emit();
///   监听：FxEmitter().on<MyEvent>((e) { ... });
class FxEmitter {
  FxEmitter._();
  static final FxEmitter _instance = FxEmitter._();
  factory FxEmitter() => _instance;

  final StreamController<FxEvent> _controller = StreamController.broadcast();

  Stream<FxEvent> get stream => _controller.stream;

  StreamSubscription<E> on<E extends FxEvent>(void Function(E event) handler) {
    return stream.where((FxEvent e) => e is E).cast<E>().listen(handler);
  }

  void emit(FxEvent event) {
    _controller.add(event);
  }
}

/// 事件基类
class FxEvent {
  const FxEvent();

  void emit() => FxEmitter().emit(this);
}

// ─── 合规相关事件 ───

/// 举报用户事件（从资料页发出）
class ReportUserEvent extends FxEvent {
  final String userId;
  final String nickname;

  const ReportUserEvent({required this.userId, required this.nickname});
}

/// 拉黑用户事件（从资料页发出）
class BlockUserEvent extends FxEvent {
  final String userId;
  final String nickname;

  const BlockUserEvent({required this.userId, required this.nickname});
}
