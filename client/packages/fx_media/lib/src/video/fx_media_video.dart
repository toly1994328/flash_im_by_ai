import 'package:flutter/widgets.dart';

/// 视频播放抽象接口
abstract class FxMediaVideo {
  /// 跳转全屏播放页（网络 URL）
  void open(BuildContext context, String url);

  /// 跳转全屏播放页（本地文件）
  void openFile(BuildContext context, String localPath);
}
