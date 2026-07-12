import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_logger/fx_logger.dart';
import '../data/session_repository.dart';
import 'session_state.dart';

/// 全局用户会话管理
/// 生命周期与 App 一致，维护当前用户在会话期间的完整表现形态
class SessionCubit extends Cubit<SessionState> {
  final SessionRepository _repo;
  static final _log = FxLog('Session');

  SessionCubit({required SessionRepository repo})
      : _repo = repo,
        super(const SessionState.unknown());

  /// 便捷访问当前 token
  String? get token => state.token;

  /// 应用启动时，从本地缓存恢复会话
  /// 返回 true 表示恢复成功（已认证），false 表示无缓存
  Future<bool> restore() async {
    _log.d('restore: 开始从本地缓存恢复会话');
    final snapshot = await _repo.loadLocal();
    if (snapshot == null) {
      _log.d('restore: 本地无缓存，会话结束');
      emit(const SessionState.ended());
      return false;
    }

    _log.i('restore: 发现本地缓存 token=${snapshot.token.substring(0, 8)}... hasPassword=${snapshot.hasPassword}');
    var user = snapshot.user;
    emit(SessionState.active(
      token: snapshot.token,
      user: user,
      hasPassword: snapshot.hasPassword,
    ));

    if (user == null) {
      _log.d('restore: 本地无用户信息，尝试从服务端获取');
      try {
        user = await _repo.fetchProfile();
        _log.i('restore: 获取用户资料成功 userId=${user.userId} nickname=${user.nickname}');
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
      } catch (e) {
        _log.e('restore: 获取用户资料失败', error: e);
      }
    } else {
      _log.d('restore: 使用本地缓存的用户信息 userId=${user.userId}');
    }

    return true;
  }

  /// 登录成功后激活会话，自动拉取用户资料并缓存
  Future<void> activate({
    required String token,
    bool hasPassword = false,
  }) async {
    _log.i('activate: 激活会话 token=${token.substring(0, 8)}... hasPassword=$hasPassword');
    emit(SessionState.active(
      token: token,
      hasPassword: hasPassword,
    ));
    try {
      _log.d('activate: 获取用户资料');
      final user = await _repo.fetchProfile();
      _log.i('activate: 获取用户资料成功 userId=${user.userId} nickname=${user.nickname}');
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
    } catch (e) {
      _log.e('activate: 获取用户资料失败', error: e);
      await _repo.saveLocal(token: token, hasPassword: hasPassword);
    }
  }

  /// 设置密码
  Future<void> setPassword(String newPassword) async {
    _log.d('setPassword: 设置密码');
    await _repo.setPassword(newPassword);
    if (state.status == SessionStatus.active) {
      _log.i('setPassword: 密码设置成功');
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
    _log.d('updateProfile: nickname=$nickname');
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
    _log.d('changePassword: 修改密码');
    await _repo.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    _log.i('changePassword: 密码修改成功');
  }

  /// 结束会话，清状态 + 清缓存
  Future<void> deactivate() async {
    _log.i('deactivate: 结束会话，清除本地缓存');
    await _repo.clearLocal();
    emit(const SessionState.ended());
  }
}
