import 'package:flash_session/flash_session.dart';
import 'package:flash_starter/flash_starter.dart';

/// 恢复会话的启动任务，返回是否已认证
class RestoreSessionTask extends StartupTask<bool> {
  final SessionCubit sessionCubit;
  RestoreSessionTask(this.sessionCubit);

  @override
  Future<bool> execute() => sessionCubit.restore();
}
