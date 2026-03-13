import 'package:dio/dio.dart';
import '../../config.dart';
import '../model/conversation.dart';

/// 会话接口请求层
class ConversationApi {
  final Dio _dio;

  ConversationApi({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: PlaygroundConfig.baseUrl));

  /// 获取会话列表
  Future<List<Conversation>> getList() async {
    final response = await _dio.get('/conversation');
    final List data = response.data as List;
    return data.map((e) => Conversation.fromJson(e)).toList();
  }
}
