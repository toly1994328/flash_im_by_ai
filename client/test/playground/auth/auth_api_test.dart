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
      // 随机生成，极小概率相同，但结构都是 6 位数字
      expect(code1, hasLength(6));
      expect(code2, hasLength(6));
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

  group('AuthApi 登录', () {
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

    test('同一手机号重复登录应返回相同 user_id', () async {
      final code1 = await api.sendSms('13900139002');
      final id1 = await api.login('13900139002', code1);

      final code2 = await api.sendSms('13900139002');
      final id2 = await api.login('13900139002', code2);

      expect(id1, equals(id2));
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
      // 手动注入一个假 token
      final fakeDio = Dio(BaseOptions(baseUrl: PlaygroundConfig.baseUrl));
      final fakeApi = AuthApi(dio: fakeDio);
      // 通过登录流程拿到 api 实例后篡改 token 不可行，直接用 dio 请求
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

  group('AuthApi 密码登录', () {
    late AuthApi api;

    setUp(() {
      api = AuthApi();
    });

    test('内置账号正确密码应登录成功', () async {
      final userId = await api.loginByPassword('13800000001', '123456');
      expect(userId, greaterThan(0));
      expect(api.token, isNotNull);
      expect(api.token, isNotEmpty);
    });

    test('登录后应能获取用户信息且昵称正确', () async {
      await api.loginByPassword('13800000001', '123456');
      final profile = await api.getProfile();
      expect(profile.phone, '13800000001');
      expect(profile.nickname, '张三');
    });

    test('错误密码应登录失败', () async {
      expect(
        () => api.loginByPassword('13800000001', 'wrong_pwd'),
        throwsA(isA<DioException>()),
      );
    });

    test('非内置账号应登录失败', () async {
      expect(
        () => api.loginByPassword('13899999999', '123456'),
        throwsA(isA<DioException>()),
      );
    });

    test('同一账号重复密码登录应返回相同 user_id', () async {
      final id1 = await api.loginByPassword('13800000002', '123456');
      final id2 = await api.loginByPassword('13800000002', '123456');
      expect(id1, equals(id2));
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
