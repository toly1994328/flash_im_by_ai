import 'package:dio/dio.dart';

import 'cloud_file.dart';

/// 云空间数据仓库
class CloudRepository {
  final Dio _dio;

  CloudRepository({required Dio dio}) : _dio = dio;

  /// 查询文件列表（分页 + 分类筛选）
  Future<(List<CloudFile>, int)> getFiles({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> params = {'page': page, 'limit': limit};
    if (category != null) params['category'] = category;

    final Response<dynamic> res = await _dio.get('/api/storage/files', queryParameters: params);
    final Map<String, dynamic> data = res.data as Map<String, dynamic>;
    final List<dynamic> items = data['data'] as List<dynamic>;
    final int total = data['total'] as int? ?? 0;

    final List<CloudFile> files = items
        .map((e) => CloudFile.fromJson(e as Map<String, dynamic>))
        .toList();
    return (files, total);
  }

  /// 查询文件详情（含引用会话）
  Future<CloudFileDetail> getFileDetail(int fileId) async {
    final Response<dynamic> res = await _dio.get('/api/storage/files/$fileId');
    return CloudFileDetail.fromJson(res.data as Map<String, dynamic>);
  }

  /// 删除文件
  Future<Map<String, dynamic>> deleteFile(int fileId) async {
    final Response<dynamic> res = await _dio.delete('/api/storage/files/$fileId');
    return res.data as Map<String, dynamic>;
  }

  /// 下载文件到本地路径
  Future<void> downloadFile(String url, String savePath, {void Function(double)? onProgress}) async {
    await _dio.download(url, savePath, onReceiveProgress: (count, total) {
      if (total > 0 && onProgress != null) {
        onProgress(count / total);
      }
    });
  }

  /// 查询配额信息
  Future<Map<String, dynamic>> getQuota() async {
    final Response<dynamic> res = await _dio.get('/api/storage/quota');
    return res.data as Map<String, dynamic>;
  }
}
