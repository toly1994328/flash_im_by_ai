import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/model/user.dart';
import 'auth_state.dart';

/// 全局认证状态管理
/// 生命周期与 App 一致，维护认证状态
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState.unknown());

  /// 应用启动快照，由组装层在启动完成后调用
  void applyStartupSnapshot({
    required String? token,
    User? user,
    bool hasPassword = false,
  }) {
    if (token != null) {
      login(token: token, user: user, hasPassword: hasPassword);
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  /// 登录成功后调用
  void login({
    required String token,
    required User? user,
    required bool hasPassword,
  }) {
    emit(AuthState.authenticated(
      token: token,
      user: user,
      hasPassword: hasPassword,
    ));
  }

  /// 退出登录
  void logout() {
    emit(const AuthState.unauthenticated());
  }

  /// 密码设置成功后更新状态
  void onPasswordSet() {
    if (state.status == AuthStatus.authenticated) {
      emit(AuthState.authenticated(
        token: state.token!,
        user: state.user,
        hasPassword: true,
      ));
    }
  }
}
