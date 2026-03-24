import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/user.dart';

/// 会话快照 — 从本地缓存恢复时使用
class SessionSnapshot {
  final String token;
  final User? user;
  final bool hasPassword;

  const SessionSnapshot({
    required this.token,
    this.user,
    this.hasPassword = false,
  });
}

/// 会话仓库 — 负责会话期间的网络请求和本地缓存
class SessionRepository {
  final Dio _dio;

  SessionRepository({required Dio dio}) : _dio = dio;

  /// 获取当前用户资料
  Future<User> fetchProfile() async {
    final res = await _dio.get('/user/profile');
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  /// 设置/修改密码
  Future<void> setPassword(String newPassword) async {
    await _dio.post('/auth/password', data: {'new_password': newPassword});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_password', true);
  }

  /// 缓存会话数据到本地
  Future<void> saveLocal({
    required String token,
    User? user,
    bool hasPassword = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (user != null) {
      await prefs.setString('user_info', jsonEncode(user.toJson()));
    }
    await prefs.setBool('has_password', hasPassword);
  }

  /// 从本地缓存恢复会话数据
  Future<SessionSnapshot?> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final userJson = prefs.getString('user_info');
    final user = userJson != null
        ? User.fromJson(jsonDecode(userJson) as Map<String, dynamic>)
        : null;
    final hasPassword = prefs.getBool('has_password') ?? false;

    return SessionSnapshot(token: token, user: user, hasPassword: hasPassword);
  }

  /// 清除本地缓存
  Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
    await prefs.remove('has_password');
  }
}
