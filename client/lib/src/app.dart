import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oktoast/oktoast.dart';
import 'auth/cubit/auth_cubit.dart';
import 'auth/cubit/auth_state.dart';
import 'auth/service/auth_service.dart';
import 'auth/view/login_page.dart';
import 'home/home_page.dart';

class FlashApp extends StatelessWidget {
  final AuthService authService;

  const FlashApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authService)..checkAuth(),
      child: OKToast(
        child: MaterialApp(
          title: 'Flash IM',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) return const HomePage();
              if (state is AuthUnauthenticated) return const LoginPage();
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }
}
