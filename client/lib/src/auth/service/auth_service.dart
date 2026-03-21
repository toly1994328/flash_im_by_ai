import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../../config.dart';

/// 认证服务 — Token 管理 + API 调用
class AuthService {
  late final Dio _dio;
  String? _token;
  bool _hasPassword = false;

  String? get token => _token;
  bool get hasPassword => _hasPassword;

  AuthService() {
    _dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
  }

  /// 从 SharedPreferences 恢复 Token
  Future<void> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    _hasPassword = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  /// 发送验证码
  Future<String> sendSms(String phone) async {
    final res = await _dio.post('/auth/sms', data: {'phone': phone});
    return res.data['code'] as String;
  }

  /// 登录（短信/密码）
  Future<LoginResult> login(String phone, String credential, String type) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'type': type,
      'credential': credential,
    });
    final result = LoginResult.fromJson(res.data);
    _hasPassword = result.hasPassword;
    await _saveToken(result.token);
    return result;
  }

  /// 获取用户信息
  Future<User> getProfile() async {
    final res = await _dio.get(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return User.fromJson(res.data);
  }

  /// 设置密码
  Future<void> setPassword(String newPassword) async {
    await _dio.post(
      '/auth/password',
      data: {'new_password': newPassword},
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    _hasPassword = true;
  }

  /// 退出登录
  Future<void> logout() async {
    await clearToken();
  }
}
