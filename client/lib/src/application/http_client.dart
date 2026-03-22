import 'dart:ui';

import 'package:dio/dio.dart';
import 'config.dart';

class HttpClient {
  late final Dio dio;
  String? Function() tokenProvider;
  final VoidCallback? onUnauthorized;

  HttpClient({
    required this.tokenProvider,
    this.onUnauthorized,
  }) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }
}
