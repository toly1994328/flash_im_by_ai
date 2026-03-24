import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_session/flash_session.dart';
import 'package:go_router/go_router.dart';
import 'src/application/app.dart';
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

  late final GoRouter router;
  router = createRouter(
    authRepository: authRepository,
    startupTasks: [
      RestoreSessionTask(sessionCubit),
    ],
    onStartupComplete: (results) {
      final authenticated = results[RestoreSessionTask] as bool;
      router.go(authenticated ? '/home' : '/login');
    },
    onLoginSuccess: (loginResult) async {
      await sessionCubit.activate(
        token: loginResult.token,
        hasPassword: loginResult.hasPassword,
      );
      router.go('/home');
    },
  );

  runApp(
    BlocProvider.value(
      value: sessionCubit,
      child: FlashApp(router: router),
    ),
  );
}
