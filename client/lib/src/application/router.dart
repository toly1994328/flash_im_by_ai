import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../auth/data/repository/auth_repository.dart';
import '../auth/view/login_page.dart';
import '../home/view/home_page.dart';
import '../starter/data/model/startup_result.dart';
import '../starter/view/splash_page.dart';
import '../starter/data/repository/startup_repository.dart';

GoRouter createRouter({
  required StartupRepository startupRepository,
  required AuthRepository authRepository,
  required ValueChanged<StartupResult> onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => SplashPage(
          startupRepository: startupRepository,
          onStartupComplete: onStartupComplete,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => LoginPage(authRepository: authRepository),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => HomePage(authRepository: authRepository),
      ),
    ],
  );
}
