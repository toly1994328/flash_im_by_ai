import 'package:dio/dio.dart';

Future<bool> checkLinkWithDio(Dio dio, String url) async {
  try {
    // 尝试发送 HEAD 请求
    final response = await dio.head(
      url,
      options: Options(
        followRedirects: true,
        validateStatus: (status) =>
            status != null && status < 500, // 接受 4xx 状态码
      ),
    );

    if (response.statusCode == 200) {
      return true;
    }

    // 有些服务器可能不支持 HEAD，可以尝试发送 GET 请求获取部分数据
    if (response.statusCode == 405 || response.statusCode == 403) {
      final getResponse = await dio.get(
        url,
        options: Options(
          headers: {'Range': 'bytes=0-1'}, // 只获取前2个字节
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return getResponse.statusCode == 206 || getResponse.statusCode == 200;
    }
    return false;
  } catch (e) {
    return false;
  }
}
