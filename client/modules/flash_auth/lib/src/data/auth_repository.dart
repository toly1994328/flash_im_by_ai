import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_info.dart';
import 'login_result.dart';
import 'scan_models.dart';

/// 认证仓库 — 只负责认证行为（登录、发送验证码）
/// 用户资料管理（profile、密码、退出）不在此处
class AuthRepository {
  final Dio _dio;

  AuthRepository({required Dio dio}) : _dio = dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// 发送短信验证码
  Future<String> sendSms(String phone) async {
    final res = await _dio.post('/auth/sms', data: {'phone': phone});
    return res.data['code'] as String;
  }

  /// 发送邮箱验证码
  Future<String?> sendEmailCode(String email) async {
    final res = await _dio.post('/auth/email/code', data: {'email': email});
    return res.data['code'] as String?;
  }

  /// 登录（验证码或密码）
  Future<LoginResult> login(
    String phone,
    String credential,
    String type, {
    DeviceInfo? deviceInfo,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'type': type,
      'credential': credential,
      if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
    });
    final loginResult = LoginResult.fromJson(res.data as Map<String, dynamic>);
    await _saveToken(loginResult.token);
    return loginResult;
  }

  /// GitHub OAuth 登录
  Future<LoginResult> loginWithGithub(String code, {DeviceInfo? deviceInfo}) async {
    final res = await _dio.post('/auth/github', data: {
      'code': code,
      if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
    });
    final loginResult = LoginResult.fromJson(res.data as Map<String, dynamic>);
    await _saveToken(loginResult.token);
    return loginResult;
  }

  /// Apple OAuth 登录
  Future<LoginResult> loginWithApple(String identityToken, {DeviceInfo? deviceInfo}) async {
    final res = await _dio.post('/auth/apple', data: {
      'identity_token': identityToken,
      if (deviceInfo != null) 'device_info': deviceInfo.toJson(),
    });
    final loginResult = LoginResult.fromJson(res.data as Map<String, dynamic>);
    await _saveToken(loginResult.token);
    return loginResult;
  }

  /// 创建扫码会话（桌面端调用，无需认证）
  Future<ScanCreateResult> createScanSession() async {
    final res = await _dio.post('/auth/scan/create');
    return ScanCreateResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// 查询扫码状态（桌面端轮询，无需认证）
  Future<ScanStatusResult> getScanStatus(String token) async {
    final res = await _dio.get('/auth/scan/status', queryParameters: {'token': token});
    return ScanStatusResult.fromJson(res.data as Map<String, dynamic>);
  }

  /// 手机端扫码/确认（需认证）
  Future<void> confirmScan(String scanToken, String action) async {
    await _dio.post('/auth/scan/confirm', data: {'scan_token': scanToken, 'action': action});
  }

  /// 手机端取消（需认证）
  Future<void> cancelScan(String scanToken) async {
    await _dio.post('/auth/scan/cancel', data: {'scan_token': scanToken});
  }
}
