import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';

class FlashApp extends StatelessWidget {
  final GoRouter router;

  const FlashApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return OKToast(
      child: MaterialApp.router(
        title: 'Flash IM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFEDEDED),
            foregroundColor: Colors.black,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFFEDEDED),
        ),
        routerConfig: router,
      ),
    );
  }
}
