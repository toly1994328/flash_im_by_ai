/// 会话模块集成测试（真实网络请求）
///
/// 前置条件：
///   1. 后端已启动
///   2. 已执行种子数据脚本
///   3. 已运行 login_for_test.ps1 生成 test/.env
///
/// 运行方式：
///   cd client/modules/flash_im_conversation
///   flutter test test/conversation_api_test.dart
library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';

/// 从 client/test/.env 加载测试环境
({String baseUrl, String token}) _loadEnv() {
  final envFile = File('../../test/.env');
  if (!envFile.existsSync()) {
    throw StateError(
      '未找到 test/.env，请先运行:\n'
      'powershell -ExecutionPolicy Bypass -File scripts/test/login_for_test.ps1',
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

  return (
    baseUrl: map['BASE_URL'] ?? 'http://192.168.1.75:9600',
    token: map['TOKEN'] ?? '',
  );
}

void main() {
  late ConversationRepository repo;

  setUpAll(() {
    final env = _loadEnv();
    final dio = Dio(BaseOptions(
      baseUrl: env.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Authorization': 'Bearer ${env.token}'},
    ));
    repo = ConversationRepository(dio: dio);
  });

  group('会话列表 API', () {
    test('获取第一页（20条）', () async {
      final list = await repo.getList(limit: 20, offset: 0);
      expect(list.length, 20);
      for (final c in list) {
        expect(c.id, isNotEmpty);
        expect(c.type, 0);
        expect(c.peerNickname, isNotNull);
        expect(c.peerNickname, isNotEmpty);
      }
    });

    test('分页加载全部（51条）', () async {
      final page1 = await repo.getList(limit: 20, offset: 0);
      final page2 = await repo.getList(limit: 20, offset: 20);
      final page3 = await repo.getList(limit: 20, offset: 40);

      expect(page1.length, 20);
      expect(page2.length, 20);
      expect(page3.length, 11);

      // ID 不重复
      final allIds = [...page1, ...page2, ...page3].map((c) => c.id).toSet();
      expect(allIds.length, 51);
    });

    test('超出范围返回空列表', () async {
      final list = await repo.getList(limit: 20, offset: 100);
      expect(list, isEmpty);
    });
  });

  group('创建会话（幂等）', () {
    test('重复创建同一私聊返回相同会话', () async {
      final list = await repo.getList(limit: 1, offset: 0);
      final peerId = int.parse(list.first.peerUserId!);

      final c1 = await repo.createPrivate(peerId);
      final c2 = await repo.createPrivate(peerId);
      expect(c1.id, c2.id);
    });
  });

  group('删除会话', () {
    test('删除后列表减少', () async {
      final before = await repo.getList(limit: 100, offset: 0);
      final target = before.last;

      await repo.delete(target.id);

      final after = await repo.getList(limit: 100, offset: 0);
      expect(after.length, before.length - 1);
      expect(after.any((c) => c.id == target.id), false);
    });
  });
}
