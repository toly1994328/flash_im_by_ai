/// 启动任务抽象，T 为任务产出的结果类型
abstract class StartupTask<T> {
  Future<T> execute();
}

/// 启动完成回调，results 以任务类型为 key
typedef OnStartupComplete = void Function(Map<Type, dynamic> results);
