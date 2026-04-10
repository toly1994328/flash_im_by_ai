import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_session/flash_session.dart';
import 'package:flash_im_core/flash_im_core.dart';
import 'package:flash_im_conversation/flash_im_conversation.dart';
import 'package:flash_im_chat/flash_im_chat.dart';
import 'package:flash_im_friend/flash_im_friend.dart';
import 'package:go_router/go_router.dart';
import 'src/application/app.dart';
import 'src/application/config.dart';
import 'src/application/http_client.dart';
import 'src/application/router.dart';
import 'src/application/tasks/restore_session_task.dart';

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

  final wsClient = WsClient(
    config: ImConfig(wsUrl: 'ws://${AppConfig.host}:${AppConfig.port}/ws/im'),
    tokenProvider: () => sessionCubit.token,
  );

  late final GoRouter router;
  router = createRouter(
    authRepository: authRepository,
    startupTasks: [
      RestoreSessionTask(sessionCubit),
    ],
    onStartupComplete: (results) {
      final authenticated = results[RestoreSessionTask] as bool;
      if (authenticated) wsClient.connect();
      router.go(authenticated ? '/home' : '/login');
    },
    onLoginSuccess: (loginResult) async {
      await sessionCubit.activate(
        token: loginResult.token,
        hasPassword: loginResult.hasPassword,
      );
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
