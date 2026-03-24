import '../../../data/auth_repository.dart';
import '../../../data/login_result.dart';

/// 登录策略抽象
/// 只约束所有登录方式的共性：能登录、能校验、能销毁
abstract class LoginStrategy {
  /// 当前输入是否满足登录条件
  bool get isValid;

  /// 执行登录，返回 LoginResult
  Future<LoginResult> login(AuthRepository repo);

  /// 释放资源
  void dispose();
}
