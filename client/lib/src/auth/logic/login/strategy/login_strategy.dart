import '../../../data/repository/auth_repository.dart';
import '../../../data/model/login_result.dart';
import '../../../../domain/model/user.dart';

/// 登录结果
typedef LoginResultData = ({LoginResult loginResult, User user});

/// 登录策略抽象
/// 只约束所有登录方式的共性：能登录、能校验、能销毁
abstract class LoginStrategy {
  /// 当前输入是否满足登录条件
  bool get isValid;

  /// 执行登录，返回统一结果
  Future<LoginResultData> login(AuthRepository repo);

  /// 释放资源
  void dispose();
}
