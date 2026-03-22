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
        ),
        routerConfig: router,
      ),
    );
  }
}
