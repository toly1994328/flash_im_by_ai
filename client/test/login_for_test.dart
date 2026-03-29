/// 测试登录脚本（纯 dart:io，无外部依赖）
///
/// 运行方式：
///   cd client
///   dart test/login_for_test.dart
///
/// 前置条件：后端已启动，种子数据已导入

import 'dart:convert';
import 'dart:io';

const baseUrl = 'http://192.168.1.75:9600';
const phone = '13800010001';
const password = '111111';

void main() async {
  print('正在登录 $phone ...');

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 10);

  try {
    final uri = Uri.parse('$baseUrl/auth/login');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'phone': phone,
      'type': 'password',
      'credential': password,
    }));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != 200) {
      print('登录失败: ${response.statusCode} $body');
      exit(1);
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final token = data['token'] as String;
    final userId = data['user_id'];

    print('登录成功，user_id=$userId');

    final envContent = '''
# 自动生成，勿手动编辑
# 由 dart test/login_for_test.dart 生成
# Token 有效期 7 天
BASE_URL=$baseUrl
TOKEN=$token
USER_ID=$userId
PHONE=$phone
''';

    File('test/.env').writeAsStringSync(envContent);
    print('已写入 test/.env');
  } catch (e) {
    print('登录失败: $e');
    exit(1);
  } finally {
    client.close();
  }
}
