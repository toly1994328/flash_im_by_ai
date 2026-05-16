import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'package:flash_im_chat/src/data/i_message_repository.dart';
import 'package:flash_im_chat/src/data/message.dart';
import 'package:flash_im_chat/src/logic/chat_cubit.dart';
import 'package:flash_im_chat/src/logic/chat_state.dart';
import 'package:flash_im_core/flash_im_core.dart' hide MessageStatus, MessageType;
import 'package:flash_im_core/flash_im_core.dart' as proto show MessageType;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fixtures/test_fixtures.dart';
import '../mocks/fake_ws_client.dart';
import '../mocks/mock_local_store.dart';
import '../mocks/mock_message_repository.dart';

void main() {
  late MockMessageRepository mockRepo;
  late FakeWsClient fakeWs;
  late MockLocalStore mockStore;

  setUp(() {
    mockRepo = MockMessageRepository();
    fakeWs = FakeWsClient();
    mockStore = MockLocalStore();

    // 默认 stub：getReadSeq 和 getPinnedMessages
    when(() => mockRepo.getReadSeq(any())).thenAnswer((_) async => {});
    when(() => mockRepo.getPinnedMessages(any())).thenAnswer((_) async => []);
    when(() => mockRepo.store).thenReturn(mockStore);
  });

  tearDown(() {
    fakeWs.dispose();
  });

  ChatCubit buildCubit({
    String conversationId = TestFixtures.defaultConvId,
    String currentUserId = TestFixtures.defaultUserId,
  }) =>
      ChatCubit(
        repository: mockRepo,
        wsClient: fakeWs,
        conversationId: conversationId,
        currentUserId: currentUserId,
        currentUserName: TestFixtures.defaultUserName,
        store: mockStore,
      );

  group('场景 1：加载消息', () {
    blocTest<ChatCubit, ChatState>(
      '加载成功，emit ChatLoading → ChatLoaded',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => TestFixtures.messageList(count: 5));
        return buildCubit();
      },
      act: (cubit) => cubit.loadMessages(),
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.length, 5);
        expect(state.hasMore, false);
      },
    );

    blocTest<ChatCubit, ChatState>(
      '加载 50 条时 hasMore 为 true',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => TestFixtures.messageList(count: 50));
        return buildCubit();
      },
      act: (cubit) => cubit.loadMessages(),
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.hasMore, true);
      },
    );

    blocTest<ChatCubit, ChatState>(
      '加载失败，emit ChatError',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenThrow(Exception('网络错误'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadMessages(),
      expect: () => [
        isA<ChatLoading>(),
        isA<ChatError>(),
      ],
    );
  });

  group('场景 2：发送文本消息', () {
    blocTest<ChatCubit, ChatState>(
      '发送后本地消息立即出现，status=sending',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();
        cubit.sendMessage('你好');
      },
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.length, 1);
        expect(state.messages.first.content, '你好');
        expect(state.messages.first.status, MessageStatus.sending);
        // 验证 WsClient 被调用
        expect(fakeWs.sentMessages.length, 1);
        expect(fakeWs.sentMessages.first.content, '你好');
      },
    );
  });

  group('场景 3：收到 ACK', () {
    blocTest<ChatCubit, ChatState>(
      'ACK 后消息 status 变为 sent，ID 替换为服务端 ID',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => []);
        when(() => mockStore.cacheMessages(any(), conversationId: any(named: 'conversationId')))
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();
        cubit.sendMessage('测试ACK');

        // 模拟服务端返回 ACK
        await Future.delayed(Duration.zero);
        final ack = MessageAck()
          ..messageId = 'server_msg_1'
          ..seq = Int64(100);
        final frame = WsFrame()
          ..type = WsFrameType.MESSAGE_ACK
          ..payload = ack.writeToBuffer();
        fakeWs.messageAckController.add(frame);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        final msg = state.messages.first;
        expect(msg.id, 'server_msg_1');
        expect(msg.seq, 100);
        expect(msg.status, MessageStatus.sent);
      },
    );
  });

  group('场景 4：发送超时', () {
    test('10 秒后未收到 ACK，消息标记为 failed', () async {
      when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
          .thenAnswer((_) async => []);
      final cubit = buildCubit();
      await cubit.loadMessages();

      cubit.sendMessage('超时测试');
      var state = cubit.state as ChatLoaded;
      expect(state.messages.first.status, MessageStatus.sending);

      // 等待超时（10 秒）
      await Future.delayed(const Duration(seconds: 11));

      state = cubit.state as ChatLoaded;
      expect(state.messages.first.status, MessageStatus.failed);

      await cubit.close();
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('场景 5：接收对方消息', () {
    blocTest<ChatCubit, ChatState>(
      '收到对方消息后列表更新',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();

        // 模拟收到对方消息
        final chatMsg = ChatMessage()
          ..id = 'peer_msg_1'
          ..conversationId = TestFixtures.defaultConvId
          ..senderId = TestFixtures.defaultPeerId
          ..senderName = TestFixtures.defaultPeerName
          ..senderAvatar = ''
          ..seq = Int64(1)
          ..type = proto.MessageType.TEXT
          ..content = '你好啊'
          ..createdAt = Int64(DateTime.now().millisecondsSinceEpoch);
        final frame = WsFrame()
          ..type = WsFrameType.CHAT_MESSAGE
          ..payload = chatMsg.writeToBuffer();
        fakeWs.chatMessageController.add(frame);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.length, 1);
        expect(state.messages.first.content, '你好啊');
        expect(state.messages.first.senderId, TestFixtures.defaultPeerId);
      },
    );
  });

  group('场景 6：消息撤回', () {
    blocTest<ChatCubit, ChatState>(
      '撤回自己的消息，内容变为"你撤回了一条消息"',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => [
                  TestFixtures.message(
                    id: 'msg_to_recall',
                    senderId: TestFixtures.defaultUserId,
                    content: '要撤回的消息',
                  ),
                ]);
        when(() => mockRepo.recallMessage(TestFixtures.defaultConvId, 'msg_to_recall'))
            .thenAnswer((_) async {});
        when(() => mockStore.cacheMessages(any(), conversationId: any(named: 'conversationId')))
            .thenAnswer((_) async {});
        when(() => mockStore.updateConversation(any(),
                lastMessagePreview: any(named: 'lastMessagePreview'),
                lastMessageAt: any(named: 'lastMessageAt')))
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();
        await cubit.recallMessage('msg_to_recall');
      },
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.first.content, '你撤回了一条消息');
      },
    );
  });

  group('场景 7：置顶消息', () {
    blocTest<ChatCubit, ChatState>(
      'pinMessage 后 pinnedMessages 列表更新',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => [TestFixtures.message()]);
        when(() => mockRepo.pinMessage(TestFixtures.defaultConvId, 'msg_1'))
            .thenAnswer((_) async => {'pin_id': 'pin_1'});
        when(() => mockRepo.getPinnedMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => [
                  {'pin_id': 'pin_1', 'message_id': 'msg_1', 'content': 'hello', 'msg_type': 0, 'sender_name': '测试', 'pinned_by': 1, 'pinned_at': '2026-01-01T00:00:00Z'}
                ]);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();
        await cubit.pinMessage('msg_1');
      },
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.pinnedMessages.length, 1);
      },
    );
  });

  group('场景 10：收到对方撤回', () {
    blocTest<ChatCubit, ChatState>(
      '收到撤回帧后消息内容变更',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => [
                  TestFixtures.message(
                    id: 'peer_msg_1',
                    senderId: TestFixtures.defaultPeerId,
                    senderName: TestFixtures.defaultPeerName,
                    content: '对方的消息',
                  ),
                ]);
        when(() => mockStore.cacheMessages(any(), conversationId: any(named: 'conversationId')))
            .thenAnswer((_) async {});
        when(() => mockStore.updateConversation(any(),
                lastMessagePreview: any(named: 'lastMessagePreview'),
                lastMessageAt: any(named: 'lastMessageAt')))
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();

        // 模拟收到对方撤回帧
        final recalled = MessageRecalled()
          ..messageId = 'peer_msg_1'
          ..conversationId = TestFixtures.defaultConvId
          ..senderId = TestFixtures.defaultPeerId
          ..senderName = TestFixtures.defaultPeerName;
        final frame = WsFrame()
          ..type = WsFrameType.MESSAGE_RECALLED
          ..payload = recalled.writeToBuffer();
        fakeWs.messageRecalledController.add(frame);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.first.content, '${TestFixtures.defaultPeerName}撤回了一条消息');
      },
    );
  });

  group('场景 8：多选删除', () {
    blocTest<ChatCubit, ChatState>(
      '多选后删除，消息从列表移除',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => TestFixtures.messageList(count: 3));
        when(() => mockStore.moveToTrash(any(), any()))
            .thenAnswer((_) async {});
        when(() => mockStore.updateConversation(any(),
                lastMessagePreview: any(named: 'lastMessagePreview'),
                lastMessageAt: any(named: 'lastMessageAt')))
            .thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();
        cubit.enterMultiSelect('msg_0');
        cubit.toggleSelect('msg_1');
        await cubit.deleteSelected();
      },
      verify: (cubit) {
        final state = cubit.state as ChatLoaded;
        expect(state.messages.length, 1);
        expect(state.messages.first.id, 'msg_2');
        expect(state.isMultiSelect, false);
      },
    );
  });

  group('场景 9：引用回复', () {
    test('setReplyTo 后 state 包含 replyTo', () async {
      when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
          .thenAnswer((_) async => [TestFixtures.message()]);
      final cubit = buildCubit();
      await cubit.loadMessages();

      cubit.setReplyTo(TestFixtures.message());
      final state = cubit.state as ChatLoaded;
      expect(state.replyTo, isNotNull);
      expect(state.replyTo!.id, 'msg_1');

      cubit.clearReplyTo();
      final state2 = cubit.state as ChatLoaded;
      expect(state2.replyTo, isNull);

      await cubit.close();
    });
  });

  group('场景 11：已读回执', () {
    blocTest<ChatCubit, ChatState>(
      '收到已读回执后 peerReadSeq 更新',
      build: () {
        when(() => mockRepo.getMessages(TestFixtures.defaultConvId))
            .thenAnswer((_) async => TestFixtures.messageList(count: 3));
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadMessages();

        final notif = ReadReceiptNotification()
          ..conversationId = TestFixtures.defaultConvId
          ..userId = TestFixtures.defaultPeerId
          ..readSeq = Int64(3);
        final frame = WsFrame()
          ..type = WsFrameType.READ_RECEIPT
          ..payload = notif.writeToBuffer();
        fakeWs.readReceiptController.add(frame);
      },
      wait: const Duration(milliseconds: 50),
      verify: (cubit) {
        expect(cubit.peerReadSeq, 3);
      },
    );
  });

  group('场景 13：加载更多', () {
    test('上拉加载更多消息', () async {
      // 首次加载返回 seq 51-100 的 50 条
      final initialMessages = List.generate(50, (i) => TestFixtures.message(
        id: 'msg_${i + 51}', seq: i + 51, content: '消息 ${i + 51}',
      ));
      when(() => mockRepo.getMessages(
            TestFixtures.defaultConvId,
            beforeSeq: any(named: 'beforeSeq'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => initialMessages);

      final cubit = buildCubit();
      await cubit.loadMessages();

      var state = cubit.state as ChatLoaded;
      expect(state.messages.length, 50);
      expect(state.hasMore, true);

      // loadMore 返回 seq 46-50 的 5 条（不重复）
      final olderMessages = List.generate(5, (i) => TestFixtures.message(
        id: 'msg_${i + 46}', seq: i + 46, content: '旧消息 ${i + 46}',
      ));
      when(() => mockRepo.getMessages(
            TestFixtures.defaultConvId,
            beforeSeq: any(named: 'beforeSeq'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => olderMessages);

      await cubit.loadMore();

      state = cubit.state as ChatLoaded;
      // 去重后：46-100 = 55 条
      expect(state.messages.length, 55);

      await cubit.close();
    });
  });
}
