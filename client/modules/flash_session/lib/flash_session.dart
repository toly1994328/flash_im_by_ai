/// Flash IM 用户会话模块
///
/// 管理用户在会话周期内的完整表现形态：
/// Token、用户资料、密码状态、本地缓存
library;

export 'src/session_cubit.dart' show SessionCubit;
export 'src/session_repository.dart' show SessionRepository;
export 'src/session_state.dart' show SessionState, SessionStatus;
export 'src/model/user.dart' show User;
