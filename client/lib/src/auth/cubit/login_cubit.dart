import 'package:flutter_bloc/flutter_bloc.dart';
import '../service/auth_service.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthService _authService;
  bool _isSmsMode = true;

  bool get isSmsMode => _isSmsMode;

  LoginCubit(this._authService) : super(const LoginInitial());

  void toggleMode() {
    _isSmsMode = !_isSmsMode;
    emit(LoginInitial(isSmsMode: _isSmsMode));
  }

  Future<void> sendSms(String phone) async {
    emit(SmsSending());
    try {
      final code = await _authService.sendSms(phone);
      emit(SmsSent(code: code));
    } catch (e) {
      emit(LoginInitial(isSmsMode: _isSmsMode));
    }
  }

  Future<void> login(String phone, String credential) async {
    final type = _isSmsMode ? 'sms' : 'password';
    emit(LoginLoading());
    try {
      final result = await _authService.login(phone, credential, type);
      final user = await _authService.getProfile();
      emit(LoginSuccess(result: result, user: user));
    } catch (e) {
      emit(LoginFailure(message: _isSmsMode ? '验证码错误' : '密码错误'));
    }
  }
}
