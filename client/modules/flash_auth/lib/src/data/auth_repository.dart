import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_result.dart';

/// 认证仓库 — 只负责认证行为（登录、发送验证码）
/// 用户资料管理（profile、密码、退出）不在此处
class AuthRepository {
  final Dio _dio;

  AuthRepository({required Dio dio}) : _dio = dio;

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// 发送验证码
  Future<String> sendSms(String phone) async {
    final res = await _dio.post('/auth/sms', data: {'phone': phone});
    return res.data['code'] as String;
  }

  /// 登录（验证码或密码）
  /// 只返回 LoginResult（token + userId + hasPassword）
  /// 获取用户资料由组装层调用 UserRepository 完成
  Future<LoginResult> login(
    String phone,
    String credential,
    String type,
  ) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'type': type,
      'credential': credential,
    });
    final loginResult = LoginResult.fromJson(res.data as Map<String, dynamic>);
    await _saveToken(loginResult.token);
    return loginResult;
  }
}
