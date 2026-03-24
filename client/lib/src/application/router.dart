import 'package:go_router/go_router.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_starter/flash_starter.dart';
import '../home/view/home_page.dart';

GoRouter createRouter({
  required AuthRepository authRepository,
  required OnLoginSuccess onLoginSuccess,
  required List<StartupTask> startupTasks,
  required OnStartupComplete onStartupComplete,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => SplashPage(
          tasks: startupTasks,
          onComplete: onStartupComplete,
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => LoginPage(
          authRepository: authRepository,
          onLoginSuccess: onLoginSuccess,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomePage(),
      ),
    ],
  );
}
