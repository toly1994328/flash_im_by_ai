import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:flash_im_group/flash_im_group.dart';
import 'package:flash_im_search/flash_im_search.dart';
import 'package:flash_im_cache/flash_im_cache.dart';
import 'package:go_router/go_router.dart';
import 'src/application/app.dart';
import 'src/application/config.dart';
import 'src/application/http_client.dart';
import 'src/application/router.dart';
import 'src/application/tasks/restore_session_task.dart';

/// 全局 SyncEngine 引用，供页面级 Cubit 注册回调
SyncEngine? globalSyncEngine;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  late final SessionCubit sessionCubit;
  final httpClient = HttpClient(
    tokenProvider: () => sessionCubit.token,
  );

  final sessionRepo = SessionRepository(dio: httpClient.dio);
  sessionCubit = SessionCubit(repo: sessionRepo);

  final authRepository = AuthRepository(dio: httpClient.dio);

  final conversationRepo = ConversationRepository(dio: httpClient.dio);
  final messageRepo = MessageRepository(dio: httpClient.dio);
  final friendRepo = FriendRepository(dio: httpClient.dio);
  final groupRepo = GroupRepository(dio: httpClient.dio);
  final searchRepo = SearchRepository(dio: httpClient.dio);

  final wsClient = WsClient(
    config: ImConfig(wsUrl: 'ws://${AppConfig.host}:${AppConfig.port}/ws/im'),
    tokenProvider: () => sessionCubit.token,
  );

  LocalStore? localStore;
  SyncEngine? syncEngine;

  Future<void> initCache() async {
    final user = sessionCubit.state.user;
    print('🗄️ [Cache] initCache called, user=${user?.userId}, status=${sessionCubit.state.status}');
    if (user == null) {
      print('🗄️ [Cache] user is null, skipping cache init');
      return;
    }
    localStore?.dispose();
    syncEngine?.dispose();
    print('🗄️ [Cache] opening database for userId=${user.userId}');
    localStore = await DriftLocalStore.open(user.userId);
    conversationRepo.setStore(localStore!);
    messageRepo.setStore(localStore!);
    friendRepo.setStore(localStore!);
    print('🗄️ [Cache] store injected into repositories');
    syncEngine = SyncEngine(
      store: localStore!,
      wsClient: wsClient,
      dio: httpClient.dio,
    );
    syncEngine!.start();
    globalSyncEngine = syncEngine;
    print('🗄️ [Cache] SyncEngine started');
  }

  late final GoRouter router;
  router = createRouter(
    authRepository: authRepository,
    startupTasks: [
      RestoreSessionTask(sessionCubit),
    ],
    onStartupComplete: (results) {
      final authenticated = results[RestoreSessionTask] as bool;
      if (authenticated) {
        initCache().then((_) => wsClient.connect());
      }
      router.go(authenticated ? '/home' : '/login');
    },
    onLoginSuccess: (loginResult) async {
      await sessionCubit.activate(
        token: loginResult.token,
        hasPassword: loginResult.hasPassword,
      );
      await initCache();
      wsClient.connect();
      router.go('/home');
    },
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: wsClient),
        RepositoryProvider.value(value: conversationRepo),
        RepositoryProvider.value(value: messageRepo),
        RepositoryProvider.value(value: friendRepo),
        RepositoryProvider.value(value: groupRepo),
        RepositoryProvider.value(value: searchRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sessionCubit),
          BlocProvider(
            create: (_) => FriendCubit(
              repository: friendRepo,
              wsClient: wsClient,
            ),
          ),
        ],
        child: FlashApp(router: router),
      ),
    ),
  );
}
