import 'package:dio/dio.dart';
import '../config.dart';
import '../auth/service/auth_service.dart';

/// Dio 单例 + Token 拦截器
class HttpClient {
  late final Dio dio;
  final AuthService _authService;
  void Function()? onUnauthorized;

  HttpClient(this._authService) {
    dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _authService.token;
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
