import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';

void main() {
  group('Conversation.fromJson', () {
    test('解析完整 JSON', () {
      final json = {
        'id': 'abc-123',
        'conv_type': 0,
        'name': null,
        'avatar': null,
        'peer_user_id': '42',
        'peer_nickname': '朱红',
        'peer_avatar': 'identicon:zhuhong:FF461F',
        'last_message_at': '2026-03-29T10:00:00.000Z',
        'last_message_preview': '你好',
        'unread_count': 3,
        'is_pinned': true,
        'is_muted': false,
        'created_at': '2026-03-29T09:00:00.000Z',
      };

      final c = Conversation.fromJson(json);

      expect(c.id, 'abc-123');
      expect(c.type, 0);
      expect(c.peerUserId, '42');
      expect(c.peerNickname, '朱红');
      expect(c.lastMessagePreview, '你好');
      expect(c.unreadCount, 3);
      expect(c.isPinned, true);
      expect(c.isMuted, false);
    });

    test('缺省字段使用默认值', () {
      final json = {
        'id': 'def-456',
        'conv_type': 1,
        'created_at': '2026-03-29T09:00:00.000Z',
      };

      final c = Conversation.fromJson(json);

      expect(c.unreadCount, 0);
      expect(c.isPinned, false);
      expect(c.isMuted, false);
      expect(c.lastMessageAt, isNull);
      expect(c.peerUserId, isNull);
    });

    test('displayName: 单聊用对方昵称', () {
      final c = Conversation(
        id: '1', type: 0, peerNickname: '石青', createdAt: DateTime.now(),
      );
      expect(c.displayName, '石青');
    });

    test('displayName: 群聊用群名', () {
      final c = Conversation(
        id: '1', type: 1, name: '技术交流群', createdAt: DateTime.now(),
      );
      expect(c.displayName, '技术交流群');
    });

    test('displayName: 无名称时回退', () {
      final c = Conversation(
        id: '1', type: 0, createdAt: DateTime.now(),
      );
      expect(c.displayName, '未知会话');
    });
  });
}
