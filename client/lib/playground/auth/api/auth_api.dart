import 'package:dio/dio.dart';
import '../../config.dart';
import '../model/user_profile.dart';

/// 认证接口层
class AuthApi {
  final Dio _dio;
  String? _token;

  String? get token => _token;

  AuthApi({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: PlaygroundConfig.baseUrl));

  /// 发送验证码
  Future<String> sendSms(String phone) async {
    final res = await _dio.post('/auth/sms', data: {'phone': phone});
    return res.data['code'] as String;
  }

  /// 验证码登录，返回 user_id
  Future<int> login(String phone, String code) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'type': 'sms',
      'credential': code,
    });
    _token = res.data['token'] as String;
    return res.data['user_id'] as int;
  }

  /// 密码登录，返回 user_id
  Future<int> loginByPassword(String phone, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'phone': phone,
      'type': 'password',
      'credential': password,
    });
    _token = res.data['token'] as String;
    return res.data['user_id'] as int;
  }

  /// 获取用户信息
  Future<UserProfile> getProfile() async {
    final res = await _dio.get(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $_token'}),
    );
    return UserProfile.fromJson(res.data);
  }

  /// 退出登录
  void logout() {
    _token = null;
  }
}
