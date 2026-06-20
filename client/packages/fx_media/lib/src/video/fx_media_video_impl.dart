import 'package:flutter/material.dart';

import 'fx_media_video.dart';
import 'fx_video_player_page.dart';

/// FxMediaVideo 实现：路由跳转到全屏播放页
class FxMediaVideoImpl implements FxMediaVideo {
  @override
  void open(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FxVideoPlayerPage(source: url, isLocal: false),
    ));
  }

  @override
  void openFile(BuildContext context, String localPath) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => FxVideoPlayerPage(source: localPath, isLocal: true),
    ));
  }
}
