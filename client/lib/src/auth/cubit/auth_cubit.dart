import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/user.dart';
import '../service/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;

  AuthCubit(this.authService) : super(AuthInitial());

  /// 启动时检查 Token
  Future<void> checkAuth() async {
    await authService.restoreToken();
    if (authService.token == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final user = await authService.getProfile();
      emit(AuthAuthenticated(user: user, hasPassword: authService.hasPassword));
    } catch (_) {
      await authService.clearToken();
      emit(AuthUnauthenticated());
    }
  }

  /// 登录成功后调用
  void onLoginSuccess(User user, bool hasPassword) {
    emit(AuthAuthenticated(user: user, hasPassword: hasPassword));
  }

  /// 退出登录
  Future<void> logout() async {
    await authService.logout();
    emit(AuthUnauthenticated());
  }

  /// 密码设置成功后更新状态
  void onPasswordSet() {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(AuthAuthenticated(user: current.user, hasPassword: true));
    }
  }
}
