import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flash_auth/flash_auth.dart';
import 'package:flash_starter/flash_starter.dart';
import '../home/view/home_page.dart';
import 'config.dart';

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
        builder: (_, _) => SplashPage(
          tasks: startupTasks,
          onComplete: onStartupComplete,
          baseUrl: AppConfig.baseUrl,
          onViewPolicy: (context, title, url) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PolicyPage(title: title, url: url),
            ));
          },
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => LoginPage(
          authRepository: authRepository,
          onLoginSuccess: onLoginSuccess,
          enableSMS: AppConfig.enableSMS,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomePage(),
      ),
    ],
  );
}
