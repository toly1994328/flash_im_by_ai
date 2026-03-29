import 'dart:io';
import 'package:dio/dio.dart';

/// 测试环境配置
///
/// 从 client/test/.env 读取登录信息，供各模块集成测试使用。
/// 使用前需先运行：
///   powershell -ExecutionPolicy Bypass -File scripts/test/login_for_test.ps1
class TestEnv {
  final String baseUrl;
  final String token;
  final int userId;
  final String phone;

  TestEnv._({
    required this.baseUrl,
    required this.token,
    required this.userId,
    required this.phone,
  });

  /// 从 .env 文件加载
  static TestEnv load() {
    // 从模块目录或 client 目录都能找到 .env
    final candidates = [
      'test/.env',           // 从 client/ 运行
      '../../test/.env',     // 从 client/modules/xxx/ 运行
    ];

    File? envFile;
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) {
        envFile = f;
        break;
      }
    }

    if (envFile == null) {
      throw StateError(
        '未找到 test/.env 文件。\n'
        '请先运行: powershell -ExecutionPolicy Bypass -File scripts/test/login_for_test.ps1',
      );
    }

    final map = <String, String>{};
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        map[trimmed.substring(0, idx)] = trimmed.substring(idx + 1);
      }
    }

    return TestEnv._(
      baseUrl: map['BASE_URL'] ?? 'http://192.168.1.75:9600',
      token: map['TOKEN'] ?? '',
      userId: int.parse(map['USER_ID'] ?? '0'),
      phone: map['PHONE'] ?? '',
    );
  }

  /// 创建带 token 的 Dio 实例
  Dio createDio() {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Authorization': 'Bearer $token'},
    ));
  }
}
