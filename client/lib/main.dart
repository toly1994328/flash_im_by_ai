import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'src/application/app.dart';
import 'src/auth/logic/auth/auth_cubit.dart';
import 'src/auth/data/repository/auth_repository.dart';
import 'src/application/http_client.dart';
import 'src/application/router.dart';
import 'src/starter/data/repository/startup_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final startupRepository = StartupRepository();
  final authCubit = AuthCubit();
  final httpClient = HttpClient(
    tokenProvider: () => authCubit.state.token,
  );
  final authRepository = AuthRepository(dio: httpClient.dio);

  final router = createRouter(
    startupRepository: startupRepository,
    authRepository: authRepository,
    onStartupComplete: (result) => authCubit.applyStartupSnapshot(
      token: result.token,
      user: result.user,
      hasPassword: result.hasPassword,
    ),
  );

  runApp(
    BlocProvider.value(
      value: authCubit,
      child: FlashApp(router: router),
    ),
  );
}
