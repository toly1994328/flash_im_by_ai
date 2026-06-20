import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fx_env/fx_env.dart';
import 'package:fx_media/fx_media.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

import '../../data/message.dart';
import '../../data/message_media_ext.dart';
import '../../view/media/file_preview_page.dart';
import '../chat_cubit.dart';

/// 媒体文件操作处理器（logic 层）
/// 负责：缓存判断 + 下载 + 系统打开 + 另存为
class ChatMediaHandler {
  final ChatCubit _cubit;
  final String? baseUrl;

  ChatMediaHandler({required ChatCubit cubit, this.baseUrl}) : _cubit = cubit;

  /// 点击图片：全屏预览（支持多图滑动 + Hero 动画）
  void openImage(BuildContext context, Message msg, {List<Message>? imageMessages, int? index}) {
    final List<ImageMeta> items = (imageMessages ?? [msg])
        .map((Message m) => m.toImageMeta(baseUrl: baseUrl ?? ''))
        .toList();
    final int initialIndex = index ?? 0;

    FxMedia.image.preview(
      context,
      items: items,
      initialIndex: initialIndex,
    );
  }

  /// 点击视频：已缓存 → 打开/播放，未缓存 → 触发下载（进度由 VideoBubble 展示）
  Future<void> openVideo(BuildContext context, Message msg) async {
    final String? cachedPath = extractLocalPath(msg);

    if (cachedPath != null && File(cachedPath).existsSync()) {
      // 已缓存：直接打开
      if (kApp.isDesktop) {
        await FxMedia.file.open(cachedPath);
      } else {
        if (!context.mounted) return;
        FxMedia.video.openFile(context, cachedPath);
      }
    } else {
      // 未缓存：触发下载（进度通过 fileDownloads 展示在气泡上）
      final String videoUrl = _fullUrl(msg.content);
      _cubit.downloadFile(msg.id, videoUrl, 'video.mp4');
    }
  }

  /// 视频下载完成后打开（由 ChatPage 在检测到下载完成时调用）
  Future<void> openDownloadedVideo(BuildContext context, String localPath) async {
    if (kApp.isDesktop) {
      await FxMedia.file.open(localPath);
    } else {
      if (!context.mounted) return;
      FxMedia.video.openFile(context, localPath);
    }
  }

  /// 点击文件：桌面端已缓存直接打开，未缓存下载；移动端进详情页
  void openFile(BuildContext context, Message msg) {
    final FileExtra? fileExtra = msg.fileExtra;
    if (fileExtra == null) return;

    if (kApp.isDesktop) {
      final String? cachedPath = extractLocalPath(msg);
      if (cachedPath != null && File(cachedPath).existsSync()) {
        FxMedia.file.open(cachedPath);
      } else {
        final String fileUrl = fileExtra.fileUrl;
        final String fullUrl = _fullUrl(fileUrl);
        _cubit.downloadFile(msg.id, fullUrl, fileExtra.fileName);
      }
      return;
    }

    // 移动端：进入文件详情页
    Navigator.of(context).push(MaterialPageRoute<void>(
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
    FxMedia.file.openFolder(localPath);
  }

  /// 另存为：让用户选择保存路径，复制文件
  Future<void> saveFileAs(Message msg) async {
    final String? localPath = extractLocalPath(msg);
    if (localPath == null) return;
    final File sourceFile = File(localPath);
    if (!sourceFile.existsSync()) return;

    final String fileName = localPath.split('/').last.split('\\').last;
    await FxMedia.file.saveAs(localPath, suggestedName: fileName);
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
