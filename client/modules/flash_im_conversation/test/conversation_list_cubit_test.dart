import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';

class MockConversationRepository extends Mock
    implements ConversationRepository {}

/// 生成测试用会话数据
List<Conversation> _fakeConversations(int count, {int startIndex = 0}) {
  return List.generate(count, (i) {
    final idx = startIndex + i;
    return Conversation(
      id: 'conv-$idx',
      type: 0,
      peerUserId: '$idx',
      peerNickname: '用户$idx',
      createdAt: DateTime(2026, 3, 29),
    );
  });
}

void main() {
  late MockConversationRepository repo;

  setUp(() {
    repo = MockConversationRepository();
  });

  group('loadConversations', () {
    blocTest<ConversationListCubit, ConversationListState>(
      '加载成功，数据不足一页 → hasMore=false',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(10));
        return ConversationListCubit(repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 10)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ConversationListCubit, ConversationListState>(
      '加载成功，数据刚好一页 → hasMore=true',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(20));
        return ConversationListCubit(repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 20)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
    );

    blocTest<ConversationListCubit, ConversationListState>(
      '加载失败 → 发出 Error 状态',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenThrow(Exception('网络错误'));
        return ConversationListCubit(repo);
      },
      act: (cubit) => cubit.loadConversations(),
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListError>()
            .having((s) => s.message, 'message', contains('网络错误')),
      ],
    );
  });

  group('loadMore', () {
    blocTest<ConversationListCubit, ConversationListState>(
      '加载更多：追加数据，hasMore 正确更新',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(20));
        when(() => repo.getList(limit: 20, offset: 20))
            .thenAnswer((_) async => _fakeConversations(5, startIndex: 20));
        return ConversationListCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadConversations();
        await cubit.loadMore();
      },
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 20)
            .having((s) => s.hasMore, 'hasMore', true),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 25)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ConversationListCubit, ConversationListState>(
      'hasMore=false 时不再请求',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(5));
        return ConversationListCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadConversations();
        await cubit.loadMore(); // 不应触发请求
      },
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 5)
            .having((s) => s.hasMore, 'hasMore', false),
        // 没有额外状态发出
      ],
      verify: (_) {
        // getList 只被调用一次（首次加载）
        verify(() => repo.getList(limit: 20, offset: 0)).called(1);
        verifyNever(() => repo.getList(limit: 20, offset: 5));
      },
    );

    blocTest<ConversationListCubit, ConversationListState>(
      'loadMore 失败不影响已有数据',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(20));
        when(() => repo.getList(limit: 20, offset: 20))
            .thenThrow(Exception('超时'));
        return ConversationListCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadConversations();
        await cubit.loadMore();
      },
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 20),
        // loadMore 失败，不发出新状态，保持原有 20 条
      ],
    );
  });

  group('deleteConversation', () {
    blocTest<ConversationListCubit, ConversationListState>(
      '删除后列表减少一条',
      build: () {
        when(() => repo.getList(limit: 20, offset: 0))
            .thenAnswer((_) async => _fakeConversations(3));
        when(() => repo.delete('conv-1')).thenAnswer((_) async {});
        return ConversationListCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadConversations();
        await cubit.deleteConversation('conv-1');
      },
      expect: () => [
        const ConversationListLoading(),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 3),
        isA<ConversationListLoaded>()
            .having((s) => s.conversations.length, 'count', 2)
            .having(
              (s) => s.conversations.any((c) => c.id == 'conv-1'),
              'contains deleted',
              false,
            ),
      ],
    );
  });
}
