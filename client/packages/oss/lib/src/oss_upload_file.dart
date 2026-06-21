import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_oss_aliyun/flutter_oss_aliyun.dart';
import 'package:path/path.dart' as p;

import '../oss.dart';

/// 记录 oss 的 token 缓存
/// 避免频繁请求 tss 接口
Map<String, OssTssToken> kOssTokenMap = {};

class OssTssToken {
  final String accessKeyId;
  final String accessKeySecret;
  final String bucket;
  final String dir;
  final String domain;
  final String endpoint;
  final int expired;
  final String expiration;
  final String securityToken;

  OssTssToken({
    required this.accessKeyId,
    required this.accessKeySecret,
    required this.bucket,
    required this.dir,
    required this.domain,
    required this.endpoint,
    required this.expired,
    required this.expiration,
    required this.securityToken,
  });

  factory OssTssToken.fromMap(Map<String, dynamic> map) {
    return OssTssToken(
      accessKeyId: map['access_key_id'] ?? '',
      accessKeySecret: map['access_key_secret'] ?? '',
      bucket: map['bucket'] ?? '',
      dir: map['path'] ?? '',
      domain: map['domain'] ?? '',
      endpoint: map['endpoint'] ?? '',
      expired: map['expired'] ?? '',
      expiration: map['expiration'] ?? '',
      securityToken: map['security_token'] ?? '',
    );
  }
}

typedef DataConverter = String Function(String value);

// = '/buser/api/UploadConfig/requestUploadTokenV1'
class OssUploadFile {
  final Dio _client;
  final String path;
  final DataConverter? converter;

  OssUploadFile(
    this._client, {
    required this.path,
    this.converter,
  });

  Future<OssTssToken?> fetchTssToken(
    String alias, {
    String? proId,
  }) async {
    Map<String, dynamic> parameters = {
      'alias': alias,
    };
    if (proId != null) {
      parameters['pro_account_id'] = proId;
    }
    try {
      Response rep = await _client.get(
        path,
        queryParameters: parameters,
      );
      // rep.data 为空直接返回
      if (rep.data == null) return null;

      // 优先取 rep.data['data']，如果不存在或为 null 则尝试 rep.data 本身
      dynamic data;
      if (rep.data is Map) {
        final map = rep.data as Map;
        if (map.isEmpty) return null;
        if (map.containsKey('data') && map['data'] != null) {
          data = map['data'];
        } else {
          data = rep.data;
        }
      } else {
        data = rep.data;
      }
      if (kDebugMode) {
        print(data);
      }
      Map<String, dynamic> map = {};

      if (data is Map) {
        // data 已经是 Map（Dio 自动解析了 JSON），直接使用，无需 converter
        map = Map<String, dynamic>.from(data);
      } else if (converter != null) {
        // data 是 String 等非 Map 类型，走 converter 解密/转换后 jsonDecode
        String value = converter!(data.toString());
        map = jsonDecode(value);
      } else if (data is String) {
        // 没有 converter 但 data 是 String，尝试直接 jsonDecode
        map = jsonDecode(data);
      } else {
        return null;
      }
      OssTssToken token = OssTssToken.fromMap(map);
      kOssTokenMap[alias] = token;
      return token;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<String?> uploadFile(
    String file, {
    required String alias,
    ProgressCallback? onSendProgress,
    String? prefix,
    String? proId,
  }) async {
    OssTssToken? token = kOssTokenMap[alias];
    if (token == null) {
      token = await fetchTssToken(alias, proId: proId);
    } else {
      int dt = token.expired - DateTime.now().millisecondsSinceEpoch ~/ 1000;

      /// 即将过期，请求新的 token
      if (dt < 10) {
        token = await fetchTssToken(alias, proId: proId);
      }
    }
    if (token == null) return null;
    try {
      Client client = Client.init(
          ossEndpoint: token.endpoint,
          bucketName: token.bucket,
          authGetter: () => Auth(
                accessKey: token!.accessKeyId,
                accessSecret: token.accessKeySecret,
                expire: token.expiration,
                secureToken: token.securityToken,
              ));
      return upload(
          client, token.domain, token.dir, file, prefix, onSendProgress);
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<bool> exist(
    String alias,
    String path, {
    String? proId,
  }) async {
    OssTssToken? token = kOssTokenMap[alias];
    if (token == null) {
      token = await fetchTssToken(alias, proId: proId);
    } else {
      int dt = token.expired - DateTime.now().millisecondsSinceEpoch ~/ 1000;

      /// 即将过期，请求新的 token
      if (dt < 10) {
        token = await fetchTssToken(alias, proId: proId);
      }
    }
    if (token == null) return false;
    try {
      Client client = Client.init(
          ossEndpoint: token.endpoint,
          bucketName: token.bucket,
          authGetter: () => Auth(
                accessKey: token!.accessKeyId,
                accessSecret: token.accessKeySecret,
                expire: token.expiration,
                secureToken: token.securityToken,
              ));

      File file = File(path);
      Uint8List bytes = await file.readAsBytes();
      String s1 = getSha1(bytes);
      String prefix = s1.substring(0, 2);
      String content = s1.substring(2);
      String key = '${token.dir}$prefix/$content${p.extension(path)}';

      return client.doesObjectExist(key);
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<String?> upload(
    Client client,
    String domain,
    String dir,
    String path, [
    String? fix,
    ProgressCallback? onSendProgress,
  ]) async {
    File file = File(path);
    Uint8List bytes = await file.readAsBytes();
    String s1 = getSha1(bytes);
    String key;
    if (fix != null) {
      String content = s1.substring(2);
      key = '$dir$fix/$content${p.extension(path).toLowerCase()}';
    } else {
      String prefix = s1.substring(0, 2);
      String content = s1.substring(2);
      key = '$dir$prefix/$content${p.extension(path).toLowerCase()}';
    }

    String link = 'https://$domain/$key';
    bool isExisted = await checkLinkWithDio(_client, link);
    if (isExisted) {
      return link;
    }
    try {
      Response rep = await client.putObject(
        bytes,
        key,
        timeout: Duration(minutes: 30),
        option: PutRequestOption(
            aclModel: AclMode.publicRead,
            storageType: StorageType.standard,
            headers: {"cache-control": "no-cache"},
            onSendProgress: onSendProgress),
      );
      if (rep.statusCode == 200) {
        return 'https://$domain/$key';
      } else {
        return null;
      }
    } catch (e) {
      print(e);
    }

    return null;
  }

  String getSha1(Uint8List bytes) {
    String ret = sha1.convert(bytes).toString();
    return ret;
  }
}
