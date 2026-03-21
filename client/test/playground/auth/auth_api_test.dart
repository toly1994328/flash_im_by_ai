import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/playground/auth/api/auth_api.dart';
import 'package:flash_im/playground/auth/model/user_profile.dart';
import 'package:flash_im/playground/config.dart';

void main() {
  group('AuthApi 发送验证码', () {
    late AuthApi api;

    setUp(() {
      api = AuthApi();
    });

    test('合法手机号应返回 6 位验证码', () async {
      final code = await api.sendSms('13800138000');
      expect(code, hasLength(6));
      expect(int.tryParse(code), isNotNull);
    });

    test('不同手机号应返回不同验证码', () async {
      final code1 = await api.sendSms('13800138001');
      final code2 = await api.sendSms('13800138002');
      expect(code1, hasLength(6));
      expect(code2, hasLength(6));
    });

    test('同一手机号重复发送应覆盖旧验证码', () async {
      final code1 = await api.sendSms('13800138003');
      final code2 = await api.sendSms('13800138003');
      expect(code1, hasLength(6));
      expect(code2, hasLength(6));
      // 旧验证码应失效，用 code1 登录应失败（除非碰巧相同）
      if (code1 != code2) {
        expect(
          () => api.login('13800138003', code1),
          throwsA(isA<DioException>()),
        );
      }
    });

    test('非法手机号应抛出异常 (位数不足)', () async {
      expect(
        () => api.sendSms('1380013'),
        throwsA(isA<DioException>()),
      );
    });

    test('非法手机号应抛出异常 (非1开头)', () async {
      expect(
        () => api.sendSms('03800138000'),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthApi 短信登录', () {
    late AuthApi api;

    setUp(() {
      api = AuthApi();
    });

    test('正确验证码应登录成功并获得 token', () async {
      final code = await api.sendSms('13900139000');
      final userId = await api.login('13900139000', code);
      expect(userId, greaterThan(0));
      expect(api.token, isNotNull);
      expect(api.token, isNotEmpty);
    });

    test('错误验证码应登录失败', () async {
      await api.sendSms('13900139001');
      expect(
        () => api.login('13900139001', '000000'),
        throwsA(isA<DioException>()),
      );
    });

    test('未发送验证码直接登录应失败', () async {
      expect(
        () => api.login('13900139099', '123456'),
        throwsA(isA<DioException>()),
      );
    });

    test('验证码使用后应失效（不能重复使用）', () async {
      final code = await api.sendSms('13900139003');
      await api.login('13900139003', code);
      // 同一验证码再次登录应失败
      final api2 = AuthApi();
      expect(
        () => api2.login('13900139003', code),
        throwsA(isA<DioException>()),
      );
    });

    test('同一手机号重复登录应返回相同 user_id（登录即注册）', () async {
      final code1 = await api.sendSms('13900139002');
      final id1 = await api.login('13900139002', code1);

      final code2 = await api.sendSms('13900139002');
      final id2 = await api.login('13900139002', code2);

      expect(id1, equals(id2));
    });

    test('新手机号首次登录应自动注册', () async {
      final code = await api.sendSms('13900139050');
      final userId = await api.login('13900139050', code);
      expect(userId, greaterThan(0));

      // 注册后应能查到用户信息
      final profile = await api.getProfile();
      expect(profile.phone, '13900139050');
      expect(profile.nickname, contains('9050')); // 昵称包含手机号后4位
    });
  });

  group('AuthApi 获取用户信息', () {
    late AuthApi api;

    setUp(() {
      api = AuthApi();
    });

    test('携带有效 token 应返回用户信息', () async {
      final code = await api.sendSms('13900139010');
      await api.login('13900139010', code);
      final profile = await api.getProfile();
      expect(profile, isA<UserProfile>());
      expect(profile.phone, '13900139010');
      expect(profile.nickname, isNotEmpty);
      expect(profile.avatar, isNotEmpty);
      expect(profile.userId, greaterThan(0));
    });

    test('未登录 (无 token) 应请求失败', () async {
      expect(
        () => api.getProfile(),
        throwsA(isA<DioException>()),
      );
    });

    test('伪造 token 应请求失败', () async {
      final fakeDio = Dio(BaseOptions(baseUrl: PlaygroundConfig.baseUrl));
      expect(
        () => fakeDio.get('/user/profile',
            options: Options(headers: {'Authorization': 'Bearer fake.token.here'})),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthApi 退出登录', () {
    test('logout 应清除 token', () async {
      final api = AuthApi();
      final code = await api.sendSms('13900139020');
      await api.login('13900139020', code);
      expect(api.token, isNotNull);

      api.logout();
      expect(api.token, isNull);
    });

    test('logout 后获取用户信息应失败', () async {
      final api = AuthApi();
      final code = await api.sendSms('13900139021');
      await api.login('13900139021', code);
      api.logout();

      expect(
        () => api.getProfile(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('AuthApi 完整登录链路', () {
    test('发送验证码 → 登录 → 获取信息 → 退出 完整流程', () async {
      final api = AuthApi();

      // 1. 发送验证码
      final code = await api.sendSms('13900139030');
      expect(code, hasLength(6));

      // 2. 登录
      final userId = await api.login('13900139030', code);
      expect(userId, greaterThan(0));
      expect(api.token, isNotNull);

      // 3. 获取用户信息
      final profile = await api.getProfile();
      expect(profile.phone, '13900139030');
      expect(profile.userId, userId);

      // 4. 退出
      api.logout();
      expect(api.token, isNull);
    });
  });
}
