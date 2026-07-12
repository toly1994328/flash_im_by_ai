import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fx_env/fx_env.dart';
import 'package:go_router/go_router.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

import 'media_resolver.dart';

class FlashApp extends StatelessWidget {
  final GoRouter router;

  const FlashApp({super.key, required this.router});

  String? get _fontFamily {
    if (kApp.isWindows) return '宋体';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MediaSourceProvider(
      resolver: const AppMediaSourceResolver(),
      child: OKToast(
      position: ToastPosition.bottom,
      textPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: MaterialApp.router(
        title: 'Flash IM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: _fontFamily,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
          dividerTheme: DividerThemeData(
            thickness: 1/window.devicePixelRatio,
            space: 1/window.devicePixelRatio,
            color:Color(0xffececec)
          ),
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
          extensions: const [FlashImTheme.light],
        ),
        routerConfig: router,
      ),
    ),
    );
  }
}
