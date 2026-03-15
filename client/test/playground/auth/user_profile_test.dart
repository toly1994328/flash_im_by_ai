import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/playground/auth/model/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    test('fromJson 解析正确', () {
      final json = {
        'user_id': 42,
        'phone': '13800138000',
        'nickname': '13800138000',
        'avatar': 'https://picsum.photos/seed/42/100/100',
      };
      final profile = UserProfile.fromJson(json);
      expect(profile.userId, 42);
      expect(profile.phone, '13800138000');
      expect(profile.nickname, '13800138000');
      expect(profile.avatar, contains('picsum'));
    });

    test('fromJson 字段类型错误应抛异常', () {
      final badJson = {
        'user_id': '不是数字',
        'phone': '13800138000',
        'nickname': 'test',
        'avatar': 'url',
      };
      expect(() => UserProfile.fromJson(badJson), throwsA(isA<TypeError>()));
    });

    test('fromJson 缺少字段应抛异常', () {
      final incomplete = {'user_id': 1, 'phone': '13800138000'};
      expect(() => UserProfile.fromJson(incomplete), throwsA(isA<TypeError>()));
    });
  });
}
