import '../../../domain/model/user.dart';

/// 启动事件类型（Stream 事件）
sealed class StartupEvent {}

class StartupLoading extends StartupEvent {}

class StartupReady extends StartupEvent {
  final StartupResult result;
  StartupReady(this.result);
}

class StartupFailed extends StartupEvent {
  final String message;
  StartupFailed(this.message);
}

/// 启动结果，集中承载启动阶段从本地缓存读取的数据
class StartupResult {
  final String? token;
  final User? user;
  final bool hasPassword;

  const StartupResult({this.token, this.user, this.hasPassword = false});

  bool get authenticated => token != null;
}
