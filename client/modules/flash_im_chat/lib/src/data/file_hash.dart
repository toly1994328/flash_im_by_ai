import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

/// 在 Isolate 中计算文件 SHA-1 hex（避免大文件卡 UI）
Future<String> computeFileSha1(String filePath) async {
  return await Isolate.run(() {
    final List<int> bytes = File(filePath).readAsBytesSync();
    return sha1.convert(bytes).toString();
  });
}
