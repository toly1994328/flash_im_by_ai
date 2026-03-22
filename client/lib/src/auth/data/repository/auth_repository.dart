import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/model/user.dart';
import '../model/login_result.dart';

class AuthRepository {
  final Dio _dio;
  String? _token;

  String? get token => _token;

  AuthRepository({required Dio dio}) : _dio = dio;

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _cacheUserInfo(User user, bool hasPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_info', jsonEncode(user.toJson()));
    await prefs.setBool('has_password', hasPassword);
  }

  Future<void> _clearAll() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
    await prefs.remove('has_password');
  }

  /// 发送验证码
  Future<String> sendSms(String phone) async {
    final res = await _dio.post('/auth/sms', data: {'phone': phone});
    return res.data['code'] as String;
  }

  /// 登录（验证码或密码）
  Future<({LoginResult loginResult, User user})> login(
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

    final profileRes = await _dio.get('/user/profile');
    final user = User.fromJson(profileRes.data as Map<String, dynamic>);
    await _cacheUserInfo(user, loginResult.hasPassword);

    return (loginResult: loginResult, user: user);
  }

  /// 设置密码
  Future<void> setPassword(String newPassword) async {
    await _dio.post('/auth/password', data: {'new_password': newPassword});
    // 更新本地缓存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_password', true);
  }

  /// 退出登录
  Future<void> logout() async {
    await _clearAll();
  }
}
