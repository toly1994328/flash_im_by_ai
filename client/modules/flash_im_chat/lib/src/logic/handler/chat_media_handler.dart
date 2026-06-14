import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_im_cache/flash_im_cache.dart' show FileCacheManager, FileCategory;
import 'package:fx_env/fx_env.dart';
import 'package:fx_logger/fx_logger.dart';

import '../../data/message.dart';
import '../../view/media/file_preview_page.dart';
import '../../view/media/image_preview_page.dart';
import '../../view/media/video_player_page.dart';
import '../chat_cubit.dart';

/// 媒体文件操作处理器（logic 层）
/// 负责：缓存判断 + 下载 + 系统打开 + 另存为
class ChatMediaHandler {
  final ChatCubit _cubit;
  final String? baseUrl;

  final FxLog _log = FxLog('ChatMedia');

  ChatMediaHandler({required ChatCubit cubit, this.baseUrl}) : _cubit = cubit;

  /// 点击图片：全屏预览
  void openImage(BuildContext context, Message msg) {
    final String imageUrl = _fullUrl(msg.content);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ImagePreviewPage(imageUrl: imageUrl),
    ));
  }

  /// 点击视频：已缓存 → 系统打开/播放，未缓存 → 下载后打开
  Future<void> openVideo(BuildContext context, Message msg) async {
    final String videoUrl = _fullUrl(msg.content);
    final String? cachedPath = extractLocalPath(msg);

    if (kApp.isDesktop) {
      if (cachedPath != null && File(cachedPath).existsSync()) {
        Process.start('cmd', ['/c', 'start', '', cachedPath]);
      } else {
        final FileCacheManager? fcm = _cubit.fileCacheManager;
        if (fcm != null) {
          final String path = await fcm.getFile(
            url: videoUrl,
            messageId: msg.id,
            category: FileCategory.video,
          );
          _cubit.updateMessageLocalData(msg.id, path);
          Process.start('cmd', ['/c', 'start', '', path]);
        }
      }
    } else {
      if (cachedPath != null && File(cachedPath).existsSync()) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => VideoPlayerPage(videoUrl: cachedPath),
        ));
      } else {
        final FileCacheManager? fcm = _cubit.fileCacheManager;
        if (fcm != null) {
          final String path = await fcm.getFile(
            url: videoUrl,
            messageId: msg.id,
            category: FileCategory.video,
          );
          _cubit.updateMessageLocalData(msg.id, path);
          if (!context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VideoPlayerPage(videoUrl: path),
          ));
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => VideoPlayerPage(videoUrl: videoUrl),
          ));
        }
      }
    }
  }

  /// 点击文件：桌面端已缓存直接打开，未缓存下载；移动端进详情页
  void openFile(BuildContext context, Message msg) {
    final FileExtra? fileExtra = msg.fileExtra;
    if (fileExtra == null) return;

    if (kApp.isDesktop) {
      final String? cachedPath = extractLocalPath(msg);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        Process.start('cmd', ['/c', 'start', '', cachedPath]);
      } else {
        final String fileUrl = fileExtra.fileUrl;
        final String fullUrl = _fullUrl(fileUrl);
        _cubit.downloadFile(msg.id, fullUrl, fileExtra.fileName);
      }
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: FilePreviewPage(
          messageId: msg.id,
          fileExtra: fileExtra,
          baseUrl: baseUrl ?? '',
        ),
      ),
    ));
  }

  /// 打开文件所在文件夹（选中文件）
  void openFileFolder(Message msg) {
    final String? localPath = extractLocalPath(msg);
    if (localPath == null) return;
    final File file = File(localPath);
    if (!file.existsSync()) return;
    final String normalized = file.absolute.path.replaceAll('/', Platform.pathSeparator);
    _log.d('openFolder: $normalized');
    if (Platform.isWindows) {
      Process.start('explorer.exe', ['/select,$normalized']);
    } else if (Platform.isMacOS) {
      Process.run('open', ['-R', normalized]);
    } else {
      Process.run('xdg-open', [file.parent.path]);
    }
  }

  /// 另存为：让用户选择保存路径，复制文件
  Future<void> saveFileAs(Message msg) async {
    final String? localPath = extractLocalPath(msg);
    if (localPath == null) return;
    final File sourceFile = File(localPath);
    if (!sourceFile.existsSync()) return;

    final String fileName = localPath.split('/').last.split('\\').last;
    final String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: '另存为',
      fileName: fileName,
    );
    if (outputPath == null) return;
    await sourceFile.copy(outputPath);
  }

  /// 从 Message.localData 中提取本地文件路径
  String? extractLocalPath(Message msg) {
    if (msg.localData == null) return null;
    try {
      final Map<String, dynamic> parsed =
          jsonDecode(msg.localData!) as Map<String, dynamic>;
      return parsed['path'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _fullUrl(String url) =>
      (baseUrl != null && url.startsWith('/')) ? '$baseUrl$url' : url;
}
