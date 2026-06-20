import 'audio/fx_media_audio.dart';
import 'audio/fx_media_audio_impl.dart';
import 'download/fx_media_download.dart';
import 'download/fx_media_download_impl.dart';
import 'file/fx_media_file.dart';
import 'file/fx_media_file_impl.dart';
import 'image/fx_media_image.dart';
import 'image/fx_media_image_impl.dart';
import 'video/fx_media_video.dart';
import 'video/fx_media_video_impl.dart';

/// 下载函数签名（外部注入，解耦 dio）
typedef FxDownloadFunction = Future<void> Function(
  String url,
  String savePath, {
  void Function(double progress)? onProgress,
});

/// 从文件 URL 中提取缓存 id
///
/// URL 格式：`/uploads/{category}/{year}/{month}/{uuid}.{ext}`
/// 返回 `{uuid}_{ext}` 格式（如 `abc-def_mp4`），避免 id 含点号导致路径歧义。
String fxMediaIdFromUrl(String url) {
  // 去掉查询参数
  final String path = url.split('?').first;
  // 取最后一段文件名（含扩展名）
  final String fileName = path.split('/').last;
  if (fileName.isEmpty) return url;
  // uuid.ext → uuid_ext
  final int dotIndex = fileName.lastIndexOf('.');
  if (dotIndex > 0) {
    return '${fileName.substring(0, dotIndex)}_${fileName.substring(dotIndex + 1)}';
  }
  return fileName;
}

/// fx_media 统一入口
class FxMedia {
  static late final FxMediaDownload download;
  static late final FxMediaAudio audio;
  static late final FxMediaImage image;
  static late final FxMediaVideo video;
  static late final FxMediaFile file;

  static bool _initialized = false;

  /// 初始化所有子模块（app 启动时调用一次）
  static void init({
    required String cacheDir,
    required FxDownloadFunction downloadFn,
    int maxConcurrent = 5,
  }) {
    assert(!_initialized, 'FxMedia.init() 不能重复调用');

    download = FxMediaDownloadImpl(
      downloadFn: downloadFn,
      cacheDir: cacheDir,
      maxConcurrent: maxConcurrent,
    );
    audio = FxMediaAudioImpl();
    image = FxMediaImageImpl();
    video = FxMediaVideoImpl();
    file = FxMediaFileImpl();

    _initialized = true;
  }
}
