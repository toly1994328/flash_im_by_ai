import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/session_repository.dart';
import 'session_state.dart';

/// 全局用户会话管理
/// 生命周期与 App 一致，维护当前用户在会话期间的完整表现形态
class SessionCubit extends Cubit<SessionState> {
  final SessionRepository _repo;

  SessionCubit({required SessionRepository repo})
      : _repo = repo,
        super(const SessionState.unknown());

  /// 便捷访问当前 token
  String? get token => state.token;

  /// 应用启动时，从本地缓存恢复会话
  /// 返回 true 表示恢复成功（已认证），false 表示无缓存
  Future<bool> restore() async {
    final snapshot = await _repo.loadLocal();
    if (snapshot == null) {
      emit(const SessionState.ended());
      return false;
    }

    var user = snapshot.user;
    emit(SessionState.active(
      token: snapshot.token,
      user: user,
      hasPassword: snapshot.hasPassword,
    ));

    if (user == null) {
      try {
        user = await _repo.fetchProfile();
        await _repo.saveLocal(
          token: snapshot.token,
          user: user,
          hasPassword: snapshot.hasPassword,
        );
        emit(SessionState.active(
          token: snapshot.token,
          user: user,
          hasPassword: snapshot.hasPassword,
        ));
      } catch (_) {
        // 网络失败不阻塞，user 保持 null
      }
    }

    return true;
  }

  /// 登录成功后激活会话，自动拉取用户资料并缓存
  Future<void> activate({
    required String token,
    bool hasPassword = false,
  }) async {
    emit(SessionState.active(
      token: token,
      hasPassword: hasPassword,
    ));
    try {
      final user = await _repo.fetchProfile();
      await _repo.saveLocal(
        token: token,
        user: user,
        hasPassword: hasPassword,
      );
      emit(SessionState.active(
        token: token,
        user: user,
        hasPassword: hasPassword,
      ));
    } catch (_) {
      // fetchProfile 失败不阻塞，user 保持 null
      await _repo.saveLocal(token: token, hasPassword: hasPassword);
    }
  }

  /// 设置密码
  Future<void> setPassword(String newPassword) async {
    await _repo.setPassword(newPassword);
    if (state.status == SessionStatus.active) {
      emit(SessionState.active(
        token: state.token!,
        user: state.user,
        hasPassword: true,
      ));
    }
  }

  /// 更新用户资料，服务端返回完整 User 后更新状态 + 缓存
  Future<void> updateProfile({
    String? nickname,
    String? signature,
    String? avatar,
  }) async {
    final user = await _repo.updateProfile(
      nickname: nickname,
      signature: signature,
      avatar: avatar,
    );
    await _repo.saveLocal(
      token: state.token!,
      user: user,
      hasPassword: state.hasPassword,
    );
    emit(SessionState.active(
      token: state.token!,
      user: user,
      hasPassword: state.hasPassword,
    ));
  }

  /// 修改密码（需旧密码）
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _repo.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// 结束会话，清状态 + 清缓存
  Future<void> deactivate() async {
    await _repo.clearLocal();
    emit(const SessionState.ended());
  }
}
