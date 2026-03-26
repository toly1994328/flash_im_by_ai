/// Flash IM 用户会话模块
///
/// 管理用户在会话周期内的完整表现形态：
/// Token、用户资料、密码状态、本地缓存
library;

// data
export 'src/data/session_repository.dart' show SessionRepository;
export 'src/data/user.dart' show User;

// logic
export 'src/logic/session_cubit.dart' show SessionCubit;
export 'src/logic/session_state.dart' show SessionState, SessionStatus;

// view
export 'src/view/edit_profile_page.dart' show EditProfilePage;
export 'src/view/set_password_page.dart' show SetPasswordPage;
export 'src/view/change_password_page.dart' show ChangePasswordPage;
export 'src/view/widget/identicon_avatar.dart' show IdenticonAvatar;
export 'src/view/widget/user_card.dart' show UserCard, UserAvatar;
