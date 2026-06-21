import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:fx_logger/fx_logger.dart';

/// OSS 上传 Token（后端返回）
class OssUploadToken {
  final String accessKeyId;
  final String accessKeySecret;
  final String securityToken;
  final String expiration;
  final String bucket;
  final String endpoint;
  final String objectKey;
  final String? thumbObjectKey;
  final String url;
  final String? thumbUrl;

  const OssUploadToken({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.securityToken,
    required this.expiration,
    required this.bucket,
    required this.endpoint,
    required this.objectKey,
    this.thumbObjectKey,
    required this.url,
    this.thumbUrl,
  });

  factory OssUploadToken.fromJson(Map<String, dynamic> json) {
    return OssUploadToken(
      accessKeyId: json['access_key_id'] as String,
      accessKeySecret: json['access_key_secret'] as String,
      securityToken: json['security_token'] as String,
      expiration: json['expiration'] as String,
      bucket: json['bucket'] as String,
      endpoint: json['endpoint'] as String,
      objectKey: json['object_key'] as String,
      thumbObjectKey: json['thumb_object_key'] as String?,
      url: json['url'] as String,
      thumbUrl: json['thumb_url'] as String?,
    );
  }

  /// Token 是否快过期（距离过期不足 60 秒）
  bool get isExpiringSoon {
    try {
      final DateTime expiry = DateTime.parse(expiration);
      return expiry.difference(DateTime.now()).inSeconds < 60;
    } catch (_) {
      return true;
    }
  }
}

/// OSS 上传结果
class OssUploadResult {
  final int fileId;
  final String url;
  final String? thumbUrl;

  const OssUploadResult({required this.fileId, required this.url, this.thumbUrl});
}

/// OSS 直传上传器
///
/// 流程：获取 STS Token → putObject 直传 → confirm-upload
class OssUploader {
  static final FxLog _log = FxLog('OssUp');
  final Dio _dio;

  /// 缓存的 Token（复用 15 分钟内未过期的）
  OssUploadToken? _cachedToken;

  OssUploader({required Dio dio}) : _dio = dio;

  /// 完整上传流程
  Future<OssUploadResult> upload({
    required String filePath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    required String hash,
    String? mimeCategory,
    int? width,
    int? height,
    int? durationMs,
    void Function(double)? onProgress,
  }) async {
    // 1. 获取 Token（缓存或重新请求）
    final OssUploadToken token = await _getToken(fileName, fileSize, mimeType, hash);
    _log.d('upload: objectKey=${token.objectKey}');

    // 2. 用 flutter_oss_aliyun 直传文件到 OSS
    final Client ossClient = Client.init(
      ossEndpoint: token.endpoint.replaceFirst('https://', ''),
      bucketName: token.bucket,
      authGetter: () => Auth(
        accessKey: token.accessKeyId,
        accessSecret: token.accessKeySecret,
        expire: token.expiration,
        secureToken: token.securityToken,
      ),
    );

    final Uint8List fileBytes = await File(filePath).readAsBytes();
    final Response<dynamic> putResp = await ossClient.putObject(
      fileBytes,
      token.objectKey,
      option: PutRequestOption(
        onSendProgress: onProgress != null
            ? (int count, int total) {
                if (total > 0) onProgress(count / total);
              }
            : null,
      ),
    );

    if (putResp.statusCode != 200) {
      throw DioException(
        requestOptions: RequestOptions(path: token.objectKey),
        message: 'OSS PUT failed: ${putResp.statusCode}',
      );
    }
    _log.d('upload: PUT OSS success');

    // 3. confirm-upload
    final String category = mimeCategory ?? _inferCategory(mimeType);
    final Response<dynamic> confirmResp = await _dio.post(
      '/api/storage/confirm-upload',
      data: {
        'object_key': token.objectKey,
        'file_size': fileSize,
        'mime_type': mimeType,
        'mime_category': category,
        'hash': hash,
        'original_name': fileName,
        'width': ?width,
        'height': ?height,
        'duration_ms': ?durationMs,
        'thumb_object_key': ?token.thumbObjectKey,
      },
    );

    final Map<String, dynamic> data = confirmResp.data as Map<String, dynamic>;
    _log.d('upload: confirm success, file_id=${data['file_id']}');

    return OssUploadResult(
      fileId: data['file_id'] as int,
      url: data['url'] as String,
      thumbUrl: data['thumb_url'] as String?,
    );
  }

  /// 获取 Token（有缓存且未过期则复用）
  Future<OssUploadToken> _getToken(String fileName, int fileSize, String mimeType, String hash) async {
    if (_cachedToken != null && !_cachedToken!.isExpiringSoon) {
      return _cachedToken!;
    }

    final Response<dynamic> resp = await _dio.post(
      '/api/storage/upload-token',
      data: {
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
        'hash': hash,
      },
    );

    _cachedToken = OssUploadToken.fromJson(resp.data as Map<String, dynamic>);
    return _cachedToken!;
  }

  /// 从 mimeType 推断 category
  String _inferCategory(String mimeType) {
    final String type = mimeType.split('/').first;
    return switch (type) {
      'image' => 'image',
      'video' => 'video',
      'audio' => 'audio',
      _ => 'file',
    };
  }
}
