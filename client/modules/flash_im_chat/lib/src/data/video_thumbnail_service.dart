import 'dart:io';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoInfo {
  final String thumbnailPath;
  final int durationMs;
  final int width;
  final int height;

  const VideoInfo({
    required this.thumbnailPath,
    required this.durationMs,
    required this.width,
    required this.height,
  });
}

class VideoThumbnailService {
  Future<VideoInfo> extractVideoInfo(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg';

    // 提取首帧缩略图
    final plugin = FcNativeVideoThumbnail();
    await plugin.saveThumbnailToFile(
      srcFile: videoPath,
      destFile: thumbPath,
      width: 384,
      height: 384,
      format: 'jpeg',
      quality: 90,
    );

    // 提取时长和宽高
    int? durationMs;
    int width = 0, height = 0;
    try {
      final ctrl = VideoPlayerController.file(File(videoPath));
      await ctrl.initialize();
      durationMs = ctrl.value.duration.inMilliseconds;
      width = ctrl.value.size.width.toInt();
      height = ctrl.value.size.height.toInt();
      await ctrl.dispose();
    } catch (e) {
      debugPrint('视频信息提取失败: $e');
    }

    return VideoInfo(
      thumbnailPath: thumbPath,
      durationMs: durationMs != null && durationMs > 0 ? durationMs : 1000,
      width: width,
      height: height,
    );
  }
}
