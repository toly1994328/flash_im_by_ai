import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flash_shared/flash_shared.dart';
import 'package:intl/intl.dart';
import 'package:tolyui_feedback_modal/tolyui_feedback_modal.dart';

import '../data/cloud_file.dart';
import '../data/cloud_repository.dart';
import '../logic/file_detail_cubit.dart';

/// 文件详情页
class FileDetailPage extends StatelessWidget {
  final int fileId;
  final CloudRepository repository;
  final String? baseUrl;
  final VoidCallback? onDeleted;

  const FileDetailPage({
    super.key,
    required this.fileId,
    required this.repository,
    this.baseUrl,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FileDetailCubit(repository: repository)..loadDetail(fileId),
      child: BlocConsumer<FileDetailCubit, FileDetailState>(
        listener: (context, state) {
          if (state.status == FileDetailStatus.deleted) {
            onDeleted?.call();
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              title: const Text('文件详情'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF333333),
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
            body: _buildBody(context, state),
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
            Text('加载失败', style: TextStyle(color: Colors.grey[500])),
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
      children: [
        _buildPreview(file),
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

  Widget _buildPreview(CloudFile file) {
    final bool hasImage = file.thumbUrl != null || file.mimeCategory == 'image';
    if (!hasImage) {
      // 音频/文件：图标占位 + 右下角大小
      final Color color = _categoryColor(file.mimeCategory);
      return Container(
        height: 240,
        color: color.withValues(alpha: 0.08),
        child: Stack(
          children: [
            Center(child: Icon(_categoryIcon(file.mimeCategory), color: color, size: 64)),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Text(file.sizeFormatted, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      );
    }
    final String url = _resolveUrl(file.thumbUrl ?? file.url);
    return Container(
      height: 240,
      color: Colors.black,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
      ),
    );
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
      color: Colors.white,
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
      color: Colors.white,
      child: InkWell(
        onTap: state.isDownloading ? null : () => _onCacheTap(context, state),
        child: Stack(
          children: [
            if (state.isDownloading)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: state.downloadInfo.progress,
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
                        Text('${(state.downloadInfo.progress * 100).toInt()}%',
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
                  if (state.isCached && state.downloadInfo.localPath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.downloadInfo.localPath!,
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
          if (state.downloadInfo.localPath != null)
            TolyMenuItem(
              info: '复制',
              content: const Text('复制缓存地址', style: TextStyle(fontSize: 16)),
              task: () {
                Clipboard.setData(ClipboardData(text: state.downloadInfo.localPath!));
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
      color: Colors.white,
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
        color: Colors.white,
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
