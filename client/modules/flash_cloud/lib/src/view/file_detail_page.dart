import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:fx_env/fx_env.dart';
import 'package:fx_media/fx_media.dart';
import 'package:intl/intl.dart';
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';
import 'package:tolyui_mediax_core/tolyui_mediax_core.dart';

import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';
import '../logic/file_detail_cubit.dart';

/// 文件详情页
class FileDetailPage extends StatelessWidget {
  final int fileId;
  final CloudRepository repository;
  final String? baseUrl;
  final VoidCallback? onDeleted;
  final bool showAppBar;

  const FileDetailPage({
    super.key,
    required this.fileId,
    required this.repository,
    this.baseUrl,
    this.onDeleted,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FileDetailCubit(repository: repository, baseUrl: baseUrl)..loadDetail(fileId),
      child: BlocConsumer<FileDetailCubit, FileDetailState>(
        listener: (context, state) {
          if (state.status == FileDetailStatus.deleted) {
            onDeleted?.call();
            if (showAppBar) Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          final Widget body = _buildBody(context, state);
          if (!showAppBar) return body;
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text('文件详情'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF333333),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FileDetailState state) {
    if (state.status == FileDetailStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == FileDetailStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              (state.error?.contains('connection') == true || state.error?.contains('SocketException') == true)
                  ? '网络连接失败，请检查网络'
                  : '加载失败',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<FileDetailCubit>().loadDetail(fileId),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    final CloudFileDetail detail = state.detail!;
    final CloudFile file = detail.file;

    return ListView(
      padding: showAppBar ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildPreview(context, file, state),
        const SizedBox(height: 10),
        _buildInfoCard(file),
        const SizedBox(height: 10),
        _buildCacheCard(context, state),
        const SizedBox(height: 10),
        if (detail.conversations.isNotEmpty) ...[
          _buildConversationsCard(detail.conversations),
          const SizedBox(height: 10),
        ],
        _buildDeleteButton(context, file),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPreview(BuildContext context, CloudFile file, FileDetailState state) {
    final bool isVideo = file.mimeCategory == 'video';
    final bool isImage = file.mimeCategory == 'image';
    final bool isAudio = file.mimeCategory == 'audio';
    final bool hasImage = file.thumbUrl != null || isImage;
    final double previewHeight = showAppBar ? 240 : 180;

    if (!hasImage) {
      // 音频/文件：图标占位 + 右下角大小
      final Color color = _categoryColor(file.mimeCategory);
      return GestureDetector(
        onTap: isAudio ? () => _onPreviewTap(context, file, state) : null,
        child: Container(
          height: previewHeight,
          color: color.withValues(alpha: 0.08),
          child: Stack(
            children: [
              Center(
                child: isAudio
                    ? _buildAudioPreviewCenter(file, state)
                    : Icon(_categoryIcon(file.mimeCategory), color: color, size: 64),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                  child: Text(file.sizeFormatted, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
              if (isAudio && file.durationMs != null)
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                    child: Text(file.durationFormatted, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final String url = _resolveUrl(file.thumbUrl ?? file.url);
    return GestureDetector(
      onTap: () => _onPreviewTap(context, file, state),
      child: Container(
        height: previewHeight,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 底层：铺满的背景图
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (BuildContext _, String __, Object ___) => const SizedBox.shrink(),
              ),
            ),
            // 高斯模糊 + 暗色遮罩
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(color: Colors.black.withValues(alpha: 0.25)),
                ),
              ),
            ),
            // 前景原图（contain 居中）
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: previewHeight,
              placeholder: (BuildContext _, String __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              errorWidget: (BuildContext _, String __, Object ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
            ),
            // 视频播放按钮覆盖
            if (isVideo)
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            // 图片放大提示
            if (isImage)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onPreviewTap(BuildContext context, CloudFile file, FileDetailState state) {
    if (file.mimeCategory == 'video') {
      if (state.isCached && state.localPath != null) {
        if (kApp.isDesktop) {
          FxMedia.file.open(state.localPath!);
        } else {
          FxMedia.video.openFile(context, state.localPath!);
        }
      } else {
        final String fullUrl = _resolveUrl(file.url);
        if (kApp.isDesktop) {
          // 桌面端：先下载再用系统播放器打开
          context.read<FileDetailCubit>().downloadToLocal();
        } else {
          FxMedia.video.open(context, fullUrl);
        }
      }
    } else if (file.mimeCategory == 'image') {
      final String fullUrl = _resolveUrl(file.url);
      final ImageMeta meta = ImageMeta(
        source: NetworkSource(Uri.parse(fullUrl)),
        thumbnail: NetworkSource(Uri.parse(fullUrl)),
        originalSize: (file.width != null && file.height != null)
            ? (width: file.width!, height: file.height!)
            : null,
      );
      FxMedia.image.preview(context, items: [meta]);
    }
    // 音频的点击由 _buildAudioPreviewCenter 内部 GestureDetector 处理
  }

  Widget _buildAudioPreviewCenter(CloudFile file, FileDetailState state) {
    final String cacheId = fxMediaIdFromUrl(file.url);
    final Color color = _categoryColor('audio');
    return StreamBuilder<FxAudioSnapshot>(
      stream: FxMedia.audio.snapshotStream,
      builder: (BuildContext context, AsyncSnapshot<FxAudioSnapshot> snapshot) {
        final FxAudioState audioState = (FxMedia.audio.currentId == cacheId)
            ? (snapshot.data?.state ?? FxAudioState.idle)
            : FxAudioState.idle;
        final bool isPlaying = audioState == FxAudioState.playing || audioState == FxAudioState.loading;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _handleAudioTap(context, file, state, audioState, cacheId),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.pause_circle_filled : (state.isCached ? Icons.play_circle_filled : Icons.download_rounded),
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPlaying ? '播放中' : (state.isCached ? '点击播放' : '点击下载'),
                style: TextStyle(fontSize: 13, color: color),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAudioTap(BuildContext context, CloudFile file, FileDetailState state, FxAudioState audioState, String cacheId) {
    if (!state.isCached || state.localPath == null) {
      context.read<FileDetailCubit>().downloadToLocal();
      return;
    }
    if (audioState == FxAudioState.playing || audioState == FxAudioState.loading) {
      FxMedia.audio.pause();
    } else {
      FxMedia.audio.playFile(state.localPath!, id: cacheId);
    }
  }

  static Color _categoryColor(String category) {
    return switch (category) {
      'image' => const Color(0xFF2196F3),
      'video' => const Color(0xFFFFC107),
      'audio' => const Color(0xFFF44336),
      'file' => const Color(0xFF4CAF50),
      _ => const Color(0xFF9E9E9E),
    };
  }

  static IconData _categoryIcon(String category) {
    return switch (category) {
      'audio' => Icons.audiotrack_outlined,
      'file' => Icons.insert_drive_file_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Widget _buildInfoCard(CloudFile file) {
    final String fileName = file.originalName ?? file.url.split('/').last;
    final String date = DateFormat('yyyy-MM-dd HH:mm').format(file.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showAppBar ? null : BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _infoRow('名称', fileName),
          _divider(),
          _infoRow('大小', file.sizeFormatted),
          _divider(),
          _infoRow('格式', file.mimeType),
          _divider(),
          _infoRow('上传时间', date),
        ],
      ),
    );
  }

  Widget _buildCacheCard(BuildContext context, FileDetailState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showAppBar ? null : BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: state.isDownloading ? null : () => _onCacheTap(context, state),
        child: Stack(
          children: [
            if (state.isDownloading)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: state.downloadProgress,
                  child: Container(color: const Color(0xFF3B82F6).withValues(alpha: 0.08)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('本地缓存', style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
                      const Spacer(),
                      if (state.isDownloading)
                        Text('${(state.downloadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF3B82F6)))
                      else
                        Text(
                          state.isCached ? '✅ 已缓存' : '❌ 未缓存',
                          style: TextStyle(fontSize: 14, color: state.isCached ? const Color(0xFF4CAF50) : const Color(0xFF999999)),
                        ),
                      if (!state.isDownloading) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                  if (state.isCached && state.localPath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.localPath!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onCacheTap(BuildContext context, FileDetailState state) {
    if (state.isCached) {
      showTolyPopPicker<bool>(
        context: context,
        title: const Text('本地缓存操作'),
        tasks: [
          if (state.localPath != null)
            TolyMenuItem(
              info: '复制',
              content: const Text('复制缓存地址', style: TextStyle(fontSize: 16)),
              task: () {
                Clipboard.setData(ClipboardData(text: state.localPath!));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
                return true;
              },
            ),
          TolyMenuItem(
            info: '清除',
            content: const Text('清除本地缓存', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 16)),
            task: () {
              context.read<FileDetailCubit>().clearLocalCache();
              return true;
            },
          ),
        ],
      );
    } else {
      showTolyPopPicker<bool>(
        context: context,
        title: Text('是否将文件下载到本地？（${state.detail?.file.sizeFormatted ?? ''})'),
        tasks: [
          TolyMenuItem(
            info: '下载',
            content: const Text('下载到本地', style: TextStyle(fontSize: 16)),
            task: () {
              context.read<FileDetailCubit>().downloadToLocal();
              return true;
            },
          ),
        ],
      );
    }
  }

  Widget _buildConversationsCard(List<FileConversationRef> conversations) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: showAppBar ? null : BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              '使用此文件的会话（${conversations.length}）',
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
          ),
          ...conversations.map((conv) => Column(
            children: [
              _divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    AvatarWidget(avatar: conv.avatar, size: 36, borderRadius: 6),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(conv.conversationName, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, CloudFile file) {
    return GestureDetector(
      onTap: () => _confirmDelete(context, file),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: showAppBar ? null : BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Text(
          '删除文件释放 ${file.sizeFormatted} 空间',
          style: const TextStyle(fontSize: 15, color: Color(0xFFF44336)),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CloudFile file) {
    showTolyPopPicker<bool>(
      context: context,
      title: const Text('删除后消息中将无法查看此文件（本地缓存仍可展示）'),
      tasks: [
        TolyMenuItem(
          info: '删除',
          content: Text('删除文件释放 ${file.sizeFormatted} 空间', style: const TextStyle(color: Color(0xFFFF4D4F), fontSize: 16)),
          task: () {
            context.read<FileDetailCubit>().deleteFile(file.id);
            return true;
          },
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 16),
    child: Divider(height: 0.5, thickness: 0.5, color: Color(0xFFF0F0F0)),
  );

  String _resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    if (baseUrl != null) return '$baseUrl$url';
    return url;
  }
}
