// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:crypto/crypto.dart';
// import 'package:dart_aliyun_oss/dart_aliyun_oss.dart';
// import 'package:dio/dio.dart';
// import 'package:path/path.dart' as p;
//
// import '../../oss.dart';
//
// class OssUploadFileV2 {
//   final Dio _client;
//   final String path;
//
//   OssUploadFileV2(this._client,
//       {this.path = '/crmapi/uploadConfig/requestUploadToken'});
//
//   Future<OssTssToken?> fetchTssToken(
//     String alias, {
//     String? proId,
//   }) async {
//     Map<String, dynamic> parameters = {
//       'alias': alias,
//     };
//     if (proId != null) {
//       parameters['pro_account_id'] = proId;
//     }
//     try {
//       Response rep = await _client.get(
//         path,
//         queryParameters: parameters,
//       );
//       OssTssToken token = OssTssToken.fromMap(rep.data['data']);
//       kOssTokenMap[alias] = token;
//       return token;
//     } catch (e) {
//       print(e);
//     }
//     return null;
//   }
//
//   OSSClient? client;
//   Future<String?> uploadFile(
//     String file, {
//     required String alias,
//     ProgressCallback? onSendProgress,
//     String? prefix,
//     String? proId,
//   }) async {
//     OssTssToken? token = kOssTokenMap[alias];
//     if (token == null) {
//       token = await fetchTssToken(alias, proId: proId);
//     } else {
//       int dt = token.expired - DateTime.now().millisecondsSinceEpoch ~/ 1000;
//
//       /// 即将过期，请求新的 token
//       if (dt < 10) {
//         token = await fetchTssToken(alias, proId: proId);
//       }
//     }
//     if (token == null) return null;
//     try {
//       client = client ??
//           OSSClient.init(
//             OSSConfig(
//                 accessKeyIdProvider: () {
//                   return token!.accessKeyId;
//                 },
//                 accessKeySecretProvider: () {
//                   return token!.accessKeySecret;
//                 },
//                 securityTokenProvider: () {
//                   return token!.securityToken;
//                 },
//                 bucketName: token.bucket,
//                 endpoint: token.endpoint,
//                 region: ""
//                 // region: token.domain
//                 // endpoint:
//                 // 'your-endpoint.aliyuncs.com', // 例如: oss-cn-hangzhou.aliyuncs.com
//                 // region: 'your-region', // 例如: cn-hangzhou
//                 // accessKeyId: 'your-access-key-id',
//                 // accessKeySecret: 'your-access-key-secret',
//                 // bucketName: 'your-bucket-name',
//                 ),
//           );
//
//       return upload(
//           client!, token.domain, token.dir, file, prefix, onSendProgress);
//     } catch (e) {
//       print(e);
//     }
//
//     return null;
//   }
//
//   Future<String?> upload(
//     OSSClient client,
//     String domain,
//     String dir,
//     String path, [
//     String? fix,
//     ProgressCallback? onSendProgress,
//   ]) async {
//     File file = File(path);
//     Uint8List bytes = await file.readAsBytes();
//     String s1 = getSha1(bytes);
//     String key;
//     if (fix != null) {
//       String content = s1.substring(2);
//       key = '$dir$fix/$content${p.extension(path)}';
//     } else {
//       String prefix = s1.substring(0, 2);
//       String content = s1.substring(2);
//       key = '$dir$prefix/$content${p.extension(path)}';
//     }
//
//     String link = 'https://$domain/$key';
//     bool isExisted = await checkLinkWithDio(_client, link);
//     if (isExisted) {
//       return link;
//     }
//
//     try {
//       Response rep = await client.putObject(
//         file,
//         key,
//         // timeout: Duration(minutes: 30),
//         params: OSSRequestParams(
//             isV1Signature: true, onSendProgress: onSendProgress),
//       );
//       if (rep.statusCode == 200) {
//         return 'https://$domain/$key';
//       } else {
//         return null;
//       }
//     } catch (e) {
//       print(e);
//     }
//
//     return null;
//   }
//
//   String getSha1(Uint8List bytes) {
//     String ret = sha1.convert(bytes).toString();
//     return ret;
//   }
// }
