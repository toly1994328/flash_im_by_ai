import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/playground/conversation/api/conversation_api.dart';
import 'package:flash_im/playground/conversation/model/conversation.dart';

void main() {
  group('ConversationApi', () {
    late ConversationApi api;

    setUp(() {
      api = ConversationApi();
    });

    test('getList 应返回会话列表', () async {
      final list = await api.getList();
      expect(list, isA<List<Conversation>>());
      expect(list, isNotEmpty);
    });

    test('会话数据字段不为空', () async {
      final list = await api.getList();
      for (final c in list) {
        expect(c.title, isNotEmpty);
        expect(c.lastMsg, isNotEmpty);
        expect(c.time, isNotEmpty);
      }
    });
  });

  group('Conversation Model', () {
    test('fromJson 解析正确', () {
      final json = {'title': '张三', 'last_msg': '你好', 'time': '10:30'};
      final c = Conversation.fromJson(json);
      expect(c.title, '张三');
      expect(c.lastMsg, '你好');
      expect(c.time, '10:30');
    });

    test('toJson 序列化正确', () {
      const c = Conversation(title: '李四', lastMsg: '收到', time: '09:00', avatar: '');
      final json = c.toJson();
      expect(json['title'], '李四');
      expect(json['last_msg'], '收到');
      expect(json['time'], '09:00');
    });
  });
}
