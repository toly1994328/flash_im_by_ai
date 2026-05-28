/// Flash IM 认证模块
///
/// 公开 API：AuthRepository, LoginResult, LoginPage
/// 内部实现（登录策略、表单组件等）对外不可见
library;

export 'src/data/auth_repository.dart' show AuthRepository;
export 'src/data/login_result.dart' show LoginResult;
export 'src/view/login_page.dart' show LoginPage, OnLoginSuccess;
export 'src/view/policy_page.dart' show PolicyPage;
export 'src/view/scan_confirm_page.dart' show ScanConfirmPage;
