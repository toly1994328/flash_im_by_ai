import 'package:dio/dio.dart';
import 'message.dart';

class MessageRepository {
  final Dio _dio;

  MessageRepository({required Dio dio}) : _dio = dio;

  Future<List<Message>> getMessages(
    String conversationId, {
    int? beforeSeq,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (beforeSeq != null) params['before_seq'] = beforeSeq;

    final res = await _dio.get(
      '/conversations/$conversationId/messages',
      queryParameters: params,
    );
    final List data = res.data as List;
    return data
        .map((e) => Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
